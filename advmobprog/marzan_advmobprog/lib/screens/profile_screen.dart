import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

// models
import '../models/user.dart';

// services
import '../services/cart_service.dart';
import '../services/user_service.dart';

// widgets
import '../widgets/custom_text.dart';

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
  late final Future<User> _userFuture;

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
              text: user.fullName,
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
      child: Column(
        children: [
          _infoTile(Icons.email_outlined, 'Email', user.email),
          const Divider(height: 1),
          _infoTile(Icons.wc, 'Gender', user.gender),
          const Divider(height: 1),
          _infoTile(Icons.badge_outlined, 'User ID', '#${user.id}'),
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
}
