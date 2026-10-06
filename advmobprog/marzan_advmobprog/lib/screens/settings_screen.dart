import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

// providers
import '../providers/theme_provider.dart';

// services
import '../services/cart_service.dart';
import '../services/user_service.dart';

// widgets
import '../widgets/custom_text.dart';

// ======================= ENHANCEMENT 3 =======================
// Settings page that holds the dark/light mode switch. The toggle
// lives here instead of on the home screen; it reads and updates the
// ThemeProvider, and MaterialApp in main.dart reacts to the change.
// =============================================================
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // ENHANCEMENT 3: watch the provider so this page rebuilds on toggle.
    final themeModel = context.watch<ThemeProvider>();

    return Scaffold(
      appBar: AppBar(
        elevation: 2,
        title: CustomText(
          text: 'Settings',
          fontSize: 20.sp,
          fontWeight: FontWeight.w600,
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
          children: [
            CustomText(
              text: 'APPEARANCE',
              fontSize: 11.sp,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
            ),
            SizedBox(height: 8.h),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
                side: BorderSide(color: Theme.of(context).dividerColor),
              ),
              // ENHANCEMENT 3: the dark/light mode switch itself.
              child: SwitchListTile(
                value: themeModel.isDark,
                onChanged: (_) => context.read<ThemeProvider>().toggleTheme(),
                secondary: Icon(
                  themeModel.isDark ? Icons.dark_mode : Icons.light_mode,
                  size: 24.sp,
                ),
                title: CustomText(
                  text: themeModel.isDark ? 'Dark Mode' : 'Light Mode',
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                ),
                subtitle: CustomText(
                  text: themeModel.isDark
                      ? 'Dark theme is on'
                      : 'Light theme is on',
                  fontSize: 12.sp,
                ),
              ),
            ),
            // LAB 5 - ENHANCEMENT 3: Logout in settings, back to sign in.
            SizedBox(height: 24.h),
            CustomText(
              text: 'ACCOUNT',
              fontSize: 11.sp,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
            ),
            SizedBox(height: 8.h),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
                side: BorderSide(color: Theme.of(context).dividerColor),
              ),
              child: ListTile(
                leading: Icon(
                  Icons.logout,
                  size: 24.sp,
                  color: Colors.deepOrangeAccent,
                ),
                title: CustomText(
                  text: 'Log Out',
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                ),
                onTap: () async {
                  await UserService().logout();
                  CartService.addedProducts.value = [];
                  if (!context.mounted) return;
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/signin',
                    (route) => false,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
