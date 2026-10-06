// ======================= LAB 4 - ENHANCEMENT 3 =======================
// User model built from the POST /auth/login response. The same model
// is used to read the data back from SharedPreferences (UserService
// .getUser), so the profile_screen and cart_screen work with a typed
// User instead of a raw map.
// =====================================================================
class User {
  final int id;
  final String username;
  final String email;
  final String firstName;
  final String lastName;
  final String gender;
  final String image;
  final String accessToken;
  final String refreshToken;
  // LAB 5: Firebase sign up fields and which backend the user signed in with.
  final String uid;
  final int age;
  final String phone;
  final String loginType;

  User({
    required this.id,
    required this.username,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.gender,
    required this.image,
    required this.accessToken,
    required this.refreshToken,
    this.uid = '',
    this.age = 0,
    this.phone = '',
    this.loginType = LoginType.dummyJson,
  });

  // LAB 5: true when the account is managed by Firebase Auth.
  bool get isFirebase => loginType == LoginType.firebase;

  // LAB 4 - ENHANCEMENT 3: full name shown on the profile header.
  String get fullName => '$firstName $lastName'.trim();

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? 0,
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      gender: json['gender'] ?? '',
      image: json['image'] ?? '',
      accessToken: json['accessToken'] ?? '',
      refreshToken: json['refreshToken'] ?? '',
      uid: json['uid'] ?? '',
      age: json['age'] ?? 0,
      phone: json['phone'] ?? '',
      loginType: json['loginType'] ?? LoginType.dummyJson,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'gender': gender,
      'image': image,
      'accessToken': accessToken,
      'refreshToken': refreshToken,
      'uid': uid,
      'age': age,
      'phone': phone,
      'loginType': loginType,
    };
  }
}

// LAB 5: the two ways a user can sign in to the app.
class LoginType {
  static const String dummyJson = 'dummyjson';
  static const String firebase = 'firebase';
}
