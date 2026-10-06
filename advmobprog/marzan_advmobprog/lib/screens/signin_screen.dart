import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

// services
import '../services/user_service.dart';

// widgets
import '../widgets/custom_text.dart';

// ======================= LAB 4 - ENHANCEMENT 2 =======================
// Sign in screen. The form posts the username and password through
// UserService.loginUser (POST /auth/login); the response is saved to
// SharedPreferences and passed to /home as the route arguments.
// =====================================================================
class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // LAB 4 - ENHANCEMENT 2: authentication logic using the UserService.
  void _login() async {
    UserService userService = UserService();
    setState(() {
      _isLoading = true;
    });
    if (_formKey.currentState!.validate()) {
      try {
        // LAB 5: an email signs in with Firebase Auth, a username with
        // DummyJSON (POST /auth/login).
        final input = _usernameController.text.trim();
        final Map<String, dynamic> response;
        if (input.contains('@')) {
          await userService.signIn(
            email: input,
            password: _passwordController.text,
          );
          response = await userService.saveFirebaseSession();
        } else {
          response = await userService.loginUser(
            input,
            _passwordController.text,
          );

          // Save user data to SharedPreferences
          await userService.saveUserData(response);
        }

        if (!mounted) return;
        setState(() {
          _isLoading = false;
        });

        Navigator.pushReplacementNamed(context, '/home', arguments: response);
      } on FirebaseAuthException catch (e) {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login failed: ${e.message ?? e.code}')),
        );
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login failed: ${e.toString()}')),
        );
      }
    } else {
      // Stop the loader when the form is invalid.
      setState(() {
        _isLoading = false;
      });
    }
  }

  // LAB 4 - ENHANCEMENT 2: own sign in UI, logo, fields and button.
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset('assets/images/NU LOGO.png', width: 36.w),
                      SizedBox(width: 8.w),
                      CustomText(
                        text: 'Welcome',
                        fontSize: 22.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ],
                  ),
                  SizedBox(height: 32.h),
                  TextFormField(
                    controller: _usernameController,
                    textInputAction: TextInputAction.next,
                    decoration: _inputDecoration(
                      'Username or Email',
                      Icons.person,
                    ),
                    validator: (value) => (value == null || value.isEmpty)
                        ? 'Please enter your username or email'
                        : null,
                  ),
                  SizedBox(height: 16.h),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    onFieldSubmitted: (_) => _isLoading ? null : _login(),
                    decoration: _inputDecoration('Password', Icons.lock)
                        .copyWith(
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              size: 20.sp,
                            ),
                            onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword,
                            ),
                          ),
                        ),
                    validator: (value) => (value == null || value.isEmpty)
                        ? 'Please enter your password'
                        : null,
                  ),
                  SizedBox(height: 24.h),
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
                      onPressed: _isLoading ? null : _login,
                      child: _isLoading
                          ? SizedBox(
                              width: 20.r,
                              height: 20.r,
                              child: const CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : CustomText(
                              text: 'Log In',
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                              color: scheme.onPrimary,
                            ),
                    ),
                  ),
                  // LAB 5 - ENHANCEMENT 2: link to the Firebase sign up form.
                  SizedBox(height: 12.h),
                  TextButton(
                    onPressed: () => Navigator.pushNamed(context, '/signup'),
                    child: CustomText(
                      text: "Don't have an account? Sign Up",
                      fontSize: 13.sp,
                      color: scheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(fontFamily: 'Poppins', fontSize: 14.sp),
      prefixIcon: Icon(icon, size: 20.sp),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
    );
  }
}
