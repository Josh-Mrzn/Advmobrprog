import 'package:firebase_auth/firebase_auth.dart' hide User;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

// models
import '../models/user.dart';

// services
import '../services/cart_service.dart';
import '../services/user_service.dart';

// widgets
import '../widgets/custom_text.dart';

// screens
import 'signup_screen.dart';

// ======================= LAB 4 - ENHANCEMENT 3 =======================
// Profile page. The User model is read back from SharedPreferences
// through UserService.getUser and rendered as a header card (avatar,
// name, username) and an info card (email, gender, user id), with a
// Log Out button that clears the saved data.
// =====================================================================
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final UserService _userService = UserService();
  late Future<User> _userFuture;

  @override
  void initState() {
    super.initState();
    _userFuture = _userService.getUser();
  }

  // LAB 4 - ENHANCEMENT 3: clear SharedPreferences and the local cart
  // items, then return to the sign in screen.
  Future<void> _logout() async {
    await _userService.logout();
    CartService.addedProducts.value = [];
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/signin', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<User>(
      future: _userFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: CustomText(
              text: 'Error: ${snapshot.error}',
              fontSize: 14.sp,
            ),
          );
        }

        final user = snapshot.data!;
        return ListView(
          padding: EdgeInsets.all(16.r),
          children: [
            _buildHeader(user),
            SizedBox(height: 16.h),
            _buildInfo(user),
            SizedBox(height: 16.h),
            _buildAccountActions(user),
            SizedBox(height: 24.h),
            SizedBox(
              height: 48.h,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepOrangeAccent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
                onPressed: _logout,
                icon: Icon(Icons.logout, size: 20.sp),
                label: CustomText(
                  text: 'Log Out',
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // LAB 4 - ENHANCEMENT 3: avatar, full name and username.
  Widget _buildHeader(User user) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 24.h, horizontal: 16.w),
        child: Column(
          children: [
            CircleAvatar(
              radius: 44.r,
              backgroundColor: Colors.amber.shade100,
              child: ClipOval(
                child: Image.network(
                  user.image,
                  width: 88.r,
                  height: 88.r,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Icon(Icons.person, size: 44.sp),
                ),
              ),
            ),
            SizedBox(height: 12.h),
            CustomText(
              text: user.fullName.isEmpty ? user.username : user.fullName,
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 2.h),
            CustomText(
              text: '@${user.username}',
              fontSize: 13.sp,
              color: Colors.amber.shade700,
            ),
          ],
        ),
      ),
    );
  }

  // LAB 4 - ENHANCEMENT 3: email, gender and user id rows.
  Widget _buildInfo(User user) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      // LAB 5 - ENHANCEMENT 3: details depend on the LoginType.
      child: Column(
        children: [
          _infoTile(
            Icons.login,
            'Login Type',
            user.isFirebase ? 'Firebase' : 'DummyJSON',
          ),
          const Divider(height: 1),
          _infoTile(Icons.email_outlined, 'Email', user.email),
          const Divider(height: 1),
          if (user.isFirebase) ...[
            _infoTile(Icons.cake_outlined, 'Age', '${user.age}'),
            const Divider(height: 1),
            _infoTile(Icons.phone_outlined, 'Contact No.', user.phone),
            const Divider(height: 1),
            _infoTile(Icons.badge_outlined, 'User ID', user.uid),
          ] else ...[
            _infoTile(Icons.wc, 'Gender', user.gender),
            const Divider(height: 1),
            _infoTile(Icons.badge_outlined, 'User ID', '#${user.id}'),
          ],
        ],
      ),
    );
  }

  Widget _infoTile(IconData icon, String label, String value) {
    return ListTile(
      leading: Icon(icon, size: 22.sp, color: Colors.amber.shade700),
      title: CustomText(
        text: label,
        fontSize: 13.sp,
        fontWeight: FontWeight.w600,
      ),
      trailing: SizedBox(
        width: 180.w,
        child: CustomText(
          text: value,
          fontSize: 12.sp,
          textAlign: TextAlign.right,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  // ======================= LAB 5 - ENHANCEMENT 3 =======================
  // Account actions through the Firebase UserService functions. A
  // DummyJSON account is read-only, so only Firebase users get them.
  // =====================================================================
  Widget _buildAccountActions(User user) {
    if (!user.isFirebase) {
      return CustomText(
        text:
            'DummyJSON accounts are read-only. Sign up with Firebase to '
            'update your username, password or account.',
        fontSize: 12.sp,
        textAlign: TextAlign.center,
      );
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      child: Column(
        children: [
          _actionTile(Icons.edit_outlined, 'Update Username', _updateUsername),
          const Divider(height: 1),
          _actionTile(Icons.password, 'Change Password', _changePassword),
          const Divider(height: 1),
          _actionTile(
            Icons.delete_outline,
            'Delete Account',
            _deleteAccount,
            color: Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _actionTile(
    IconData icon,
    String label,
    VoidCallback onTap, {
    Color? color,
  }) {
    return ListTile(
      leading: Icon(icon, size: 22.sp, color: color ?? Colors.amber.shade700),
      title: CustomText(
        text: label,
        fontSize: 13.sp,
        fontWeight: FontWeight.w600,
        color: color,
      ),
      trailing: Icon(Icons.chevron_right, size: 20.sp),
      onTap: onTap,
    );
  }

  Future<void> _updateUsername() async {
    final values = await _showFormDialog(
      title: 'Update Username',
      action: 'Save',
      fields: [
        _DialogField(
          'New Username',
          validator: (value) => (value == null || value.trim().length < 3)
              ? 'Username must be at least 3 characters'
              : null,
        ),
      ],
    );
    if (values == null) return;

    await _runAction('Username updated', () async {
      await _userService.updateUsername(username: values[0].trim());
      await _userService.saveFirebaseSession();
    });
    if (!mounted) return;
    setState(() => _userFuture = _userService.getUser());
  }

  Future<void> _changePassword() async {
    final values = await _showFormDialog(
      title: 'Change Password',
      action: 'Change',
      fields: [
        _DialogField('Current Password', obscure: true),
        _DialogField(
          'New Password',
          obscure: true,
          validator: validatePassword,
        ),
      ],
    );
    if (values == null) return;

    await _runAction('Password changed', () async {
      await _userService.resetPasswordFromCurrentPassword(
        currentPassword: values[0],
        newPassword: values[1],
        email: _userService.currentUser!.email!,
      );
    });
  }

  Future<void> _deleteAccount() async {
    final values = await _showFormDialog(
      title: 'Delete Account',
      message:
          'This permanently deletes your account. Enter your password '
          'to confirm.',
      action: 'Delete',
      fields: [_DialogField('Password', obscure: true)],
    );
    if (values == null) return;

    final deleted = await _runAction('Account deleted', () async {
      await _userService.deleteAccount(
        email: _userService.currentUser!.email!,
        password: values[0],
      );
    });
    if (deleted) await _logout();
  }

  /// Runs a Firebase action and reports the result in a snackbar.
  Future<bool> _runAction(
    String success,
    Future<void> Function() action,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await action();
      messenger.showSnackBar(SnackBar(content: Text(success)));
      return true;
    } catch (e) {
      final message = e is FirebaseAuthException ? e.message ?? e.code : '$e';
      messenger.showSnackBar(SnackBar(content: Text(message)));
      return false;
    }
  }

  /// Shows a dialog with the given text fields; returns their values,
  /// or null when cancelled.
  Future<List<String>?> _showFormDialog({
    required String title,
    required String action,
    required List<_DialogField> fields,
    String? message,
  }) async {
    final formKey = GlobalKey<FormState>();
    final controllers = [for (final _ in fields) TextEditingController()];

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: CustomText(
          text: title,
          fontSize: 16.sp,
          fontWeight: FontWeight.w600,
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (message != null) CustomText(text: message, fontSize: 12.sp),
              for (var i = 0; i < fields.length; i++)
                TextFormField(
                  controller: controllers[i],
                  obscureText: fields[i].obscure,
                  decoration: InputDecoration(
                    labelText: fields[i].label,
                    errorMaxLines: 2,
                  ),
                  validator:
                      fields[i].validator ??
                      (value) =>
                          (value == null || value.isEmpty) ? 'Required' : null,
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(context, true);
              }
            },
            child: Text(action),
          ),
        ],
      ),
    );

    final values = [for (final c in controllers) c.text];
    return confirmed == true ? values : null;
  }
}

class _DialogField {
  final String label;
  final bool obscure;
  final FormFieldValidator<String>? validator;

  _DialogField(this.label, {this.obscure = false, this.validator});
}
