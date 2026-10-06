import 'dart:convert';
import 'package:http/http.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants.dart';
import '../models/user.dart' as app;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

ValueNotifier<UserService> userService = ValueNotifier(UserService());

class UserService {
  Map<String, dynamic> data = {};

  Future<Map<String, dynamic>> loginUser(
    String username,
    String password,
  ) async {
    final response = await post(
      Uri.parse('$host/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'password': password,
        'expiresInMins': 60,
      }),
    );

    if (response.statusCode == 200) {
      data = jsonDecode(response.body);
      await saveUserData(data);
      return data;
    } else {
      throw Exception(response.body);
    }
  }

  /// **Save User Data to SharedPreferences**
  /// Save user data from API response based on User model
  Future<void> saveUserData(Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();
    final user = app.User.fromJson(userData);

    await prefs.setInt('id', user.id);
    await prefs.setString('username', user.username);
    await prefs.setString('email', user.email);
    await prefs.setString('firstName', user.firstName);
    await prefs.setString('lastName', user.lastName);
    await prefs.setString('gender', user.gender);
    await prefs.setString('image', user.image);
    await prefs.setString('accessToken', user.accessToken);
    await prefs.setString('refreshToken', user.refreshToken);
    // LAB 5: Firebase sign up fields and the login type.
    await prefs.setString('uid', user.uid);
    await prefs.setInt('age', user.age);
    await prefs.setString('phone', user.phone);
    await prefs.setString('loginType', user.loginType);

    // Support generic token key if present in API response
    if (userData.containsKey('token')) {
      await prefs.setString('token', userData['token'] ?? '');
    } else if (user.accessToken.isNotEmpty) {
      await prefs.setString('token', user.accessToken);
    }
  }

  /// Retrieve user data from SharedPreferences
  Future<Map<String, dynamic>> getUserData() async {
    final prefs = await SharedPreferences.getInstance();

    return {
      'id': prefs.getInt('id') ?? 0,
      'username': prefs.getString('username') ?? '',
      'email': prefs.getString('email') ?? '',
      'firstName': prefs.getString('firstName') ?? '',
      'lastName': prefs.getString('lastName') ?? '',
      'gender': prefs.getString('gender') ?? '',
      'image': prefs.getString('image') ?? '',
      'accessToken': prefs.getString('accessToken') ?? '',
      'refreshToken': prefs.getString('refreshToken') ?? '',
      'token': prefs.getString('token') ?? prefs.getString('accessToken') ?? '',
      'uid': prefs.getString('uid') ?? '',
      'age': prefs.getInt('age') ?? 0,
      'phone': prefs.getString('phone') ?? '',
      'loginType': prefs.getString('loginType') ?? app.LoginType.dummyJson,
    };
  }

  /// Retrieve User model from SharedPreferences
  Future<app.User> getUser() async {
    final userData = await getUserData();
    return app.User.fromJson(userData);
  }

  /// **Check if User is Logged In**
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken') ?? prefs.getString('token');

    // LAB 5: a Firebase session also needs a signed-in Firebase user.
    if (prefs.getString('loginType') == app.LoginType.firebase) {
      if (currentUser == null) return false;
      try {
        await saveFirebaseSession(); // refreshes the Firebase ID token
      } catch (_) {
        // Offline: keep the last saved token.
      }
      return true;
    }

    return token != null && token.isNotEmpty;
  }

  /// **Logout and Clear User Data**
  Future<void> logout() async {
    try {
      // LAB 5: sign out of Firebase and clear the session, but keep the
      // saved Firebase sign up profiles (profile_<uid>).
      await signOut();
      final prefs = await SharedPreferences.getInstance();
      for (final key in prefs.getKeys()) {
        if (!key.startsWith('profile_')) await prefs.remove(key);
      }
    } catch (e) {
      throw Exception('Failed to log out: $e');
    }
  }

  // ======================= LAB 5 - FIREBASE AUTH =======================
  // Email/password authentication through the FirebaseAuth SDK.
  // =====================================================================
  final FirebaseAuth firebaseAuth = FirebaseAuth.instance;

  User? get currentUser => firebaseAuth.currentUser;

  Stream<User?> get authStateChanges => firebaseAuth.authStateChanges();
  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    return await firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<UserCredential> createAccount({
    required String email,
    required String password,
  }) async {
    return await firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    await firebaseAuth.signOut();
  }

  Future<void> updateUsername({required String username}) async {
    await currentUser!.updateDisplayName(username);
  }

  Future<void> deleteAccount({
    required String email,
    required String password,
  }) async {
    AuthCredential credential = EmailAuthProvider.credential(
      email: email,
      password: password,
    );

    await currentUser!.reauthenticateWithCredential(credential);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('profile_${currentUser!.uid}');
    await currentUser!.delete();
    await firebaseAuth.signOut();
  }

  Future<void> resetPasswordFromCurrentPassword({
    required String currentPassword,
    required String newPassword,
    required String email,
  }) async {
    AuthCredential credential = EmailAuthProvider.credential(
      email: email,
      password: currentPassword,
    );
    await currentUser!.reauthenticateWithCredential(credential);
    await currentUser!.updatePassword(newPassword);
  }

  /// LAB 5: Firebase Auth only stores email and display name, so the other
  /// sign up fields (first/last name, age, contact no.) are kept per uid.
  Future<void> saveFirebaseProfile(
    String uid,
    Map<String, dynamic> profile,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('profile_$uid', jsonEncode(profile));
  }

  /// LAB 5: save the signed-in Firebase user as the current session.
  /// getIdToken(true) forces a token refresh, so the saved token is fresh.
  Future<Map<String, dynamic>> saveFirebaseSession() async {
    final user = currentUser!;
    final prefs = await SharedPreferences.getInstance();
    final Map<String, dynamic> profile = jsonDecode(
      prefs.getString('profile_${user.uid}') ?? '{}',
    );
    final idToken = await user.getIdToken(true) ?? '';

    final userData = <String, dynamic>{
      ...profile,
      'uid': user.uid,
      'username': user.displayName ?? profile['username'] ?? '',
      'email': user.email ?? '',
      'accessToken': idToken,
      'loginType': app.LoginType.firebase,
    };
    await saveUserData(userData);
    return userData;
  }
}
