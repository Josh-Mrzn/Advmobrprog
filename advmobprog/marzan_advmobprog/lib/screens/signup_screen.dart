import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

// services
import '../services/user_service.dart';

// widgets
import '../widgets/custom_text.dart';

// ======================= LAB 5 - ENHANCEMENT 2 =======================
// Sign up screen. Creates a Firebase Auth account (email + password),
// sets the username as the display name, and keeps the other fields
// (based on dummyjson.com/users) as the user's profile.
// =====================================================================
class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _ageController = TextEditingController();
  final _contactNoController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _ageController.dispose();
    _contactNoController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // LAB 5 - ENHANCEMENT 2: create the Firebase account and sign in.
  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;

    final userService = UserService();
    setState(() => _isLoading = true);

    try {
      final credential = await userService.createAccount(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      final username = _usernameController.text.trim();
      await userService.updateUsername(username: username);
      await userService.saveFirebaseProfile(credential.user!.uid, {
        'firstName': _firstNameController.text.trim(),
        'lastName': _lastNameController.text.trim(),
        'age': int.parse(_ageController.text.trim()),
        'phone': _contactNoController.text.trim(),
        'username': username,
      });
      final response = await userService.saveFirebaseSession();

      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/home',
        (route) => false,
        arguments: response,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      final message = e is FirebaseAuthException ? e.message ?? e.code : '$e';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Sign up failed: $message')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: CustomText(
          text: 'Create Account',
          fontSize: 20.sp,
          fontWeight: FontWeight.w600,
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _field(
                        _firstNameController,
                        'First Name',
                        Icons.badge_outlined,
                        validator: _required('first name'),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: _field(
                        _lastNameController,
                        'Last Name',
                        Icons.badge_outlined,
                        validator: _required('last name'),
                      ),
                    ),
                  ],
                ),
                _field(
                  _ageController,
                  'Age',
                  Icons.cake_outlined,
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    final age = int.tryParse(value?.trim() ?? '');
                    if (age == null) return 'Please enter your age';
                    if (age < 1 || age > 120) return 'Enter a valid age';
                    return null;
                  },
                ),
                _field(
                  _contactNoController,
                  'Contact No.',
                  Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    final phone = value?.trim() ?? '';
                    if (phone.isEmpty) return 'Please enter your contact no.';
                    if (!RegExp(r'^\+?[0-9 -]{7,15}$').hasMatch(phone)) {
                      return 'Enter a valid contact no.';
                    }
                    return null;
                  },
                ),
                _field(
                  _usernameController,
                  'Username',
                  Icons.person_outline,
                  validator: (value) {
                    final username = value?.trim() ?? '';
                    if (username.isEmpty) return 'Please enter a username';
                    if (username.length < 3) {
                      return 'Username must be at least 3 characters';
                    }
                    if (username.contains(' ')) {
                      return 'Username cannot contain spaces';
                    }
                    return null;
                  },
                ),
                _field(
                  _emailController,
                  'Email Address',
                  Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    final email = value?.trim() ?? '';
                    if (email.isEmpty) return 'Please enter your email';
                    if (!RegExp(
                      r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                    ).hasMatch(email)) {
                      return 'Enter a valid email address';
                    }
                    return null;
                  },
                ),
                _field(
                  _passwordController,
                  'Password',
                  Icons.lock_outline,
                  obscureText: _obscurePassword,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                      size: 20.sp,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  validator: validatePassword,
                ),
                SizedBox(height: 8.h),
                SizedBox(
                  height: 48.h,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: scheme.primary,
                      foregroundColor: scheme.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                    onPressed: _isLoading ? null : _signUp,
                    child: _isLoading
                        ? SizedBox(
                            width: 20.r,
                            height: 20.r,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : CustomText(
                            text: 'Sign Up',
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            color: scheme.onPrimary,
                          ),
                  ),
                ),
                SizedBox(height: 12.h),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: CustomText(
                    text: 'Already have an account? Log In',
                    fontSize: 13.sp,
                    color: scheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  FormFieldValidator<String> _required(String label) {
    return (value) => (value == null || value.trim().isEmpty)
        ? 'Please enter your $label'
        : null;
  }

  Widget _field(
    TextEditingController controller,
    String label,
    IconData icon, {
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
    FormFieldValidator<String>? validator,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16.h),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        textInputAction: TextInputAction.next,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(fontFamily: 'Poppins', fontSize: 14.sp),
          prefixIcon: Icon(icon, size: 20.sp),
          suffixIcon: suffixIcon,
          errorMaxLines: 2,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
        ),
      ),
    );
  }
}

// LAB 5 - ENHANCEMENT 2: password rules, also used by the change
// password dialog on the profile screen.
String? validatePassword(String? value) {
  final password = value ?? '';
  if (password.isEmpty) return 'Please enter a password';
  if (password.length < 8) return 'Password must be at least 8 characters';
  if (!RegExp(r'[A-Z]').hasMatch(password)) {
    return 'Password needs an uppercase letter';
  }
  if (!RegExp(r'[a-z]').hasMatch(password)) {
    return 'Password needs a lowercase letter';
  }
  if (!RegExp(r'[0-9]').hasMatch(password)) return 'Password needs a number';
  if (!RegExp(r'[!@#\$%^&*(),.?":{}|<>_\-]').hasMatch(password)) {
    return 'Password needs a special character';
  }
  return null;
}
