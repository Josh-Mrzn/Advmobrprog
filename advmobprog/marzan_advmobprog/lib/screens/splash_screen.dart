import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

// services
import '../services/user_service.dart';

// widgets
import '../widgets/custom_text.dart';

// ======================= LAB 4 - ENHANCEMENT 1 =======================
// Splash screen with persistent authentication. While the logo is
// shown, the saved token in SharedPreferences is checked: a logged-in
// user goes straight to /home with the saved data, otherwise /signin.
// =====================================================================
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final UserService _userService = UserService();

  @override
  void initState() {
    super.initState();
    _checkAuthentication();
  }

  // LAB 4 - ENHANCEMENT 1: persistent authentication check.
  Future<void> _checkAuthentication() async {
    await Future.delayed(const Duration(seconds: 4));

    final loggedIn = await _userService.isLoggedIn();

    if (!mounted) return;

    if (loggedIn) {
      final userData = await _userService.getUserData();
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/home', arguments: userData);
    } else {
      Navigator.pushReplacementNamed(context, '/signin');
    }
  }

  // LAB 4 - ENHANCEMENT 1: own splash UI, logo, app name and loader.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/images/nu_logo_splash.png', width: 160.w),
            SizedBox(height: 20.h),
            CustomText(
              text: 'NUBD Exchange',
              fontSize: 20.sp,
              fontWeight: FontWeight.w600,
            ),
            SizedBox(height: 24.h),
            SizedBox(
              width: 24.r,
              height: 24.r,
              child: const CircularProgressIndicator(
                strokeWidth: 2.5,
                color: Colors.amber,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
