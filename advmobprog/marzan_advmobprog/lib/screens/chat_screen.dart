import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../models/user.dart';
import '../services/chat_service.dart';
import '../services/user_service.dart';
import '../widgets/custom_text.dart';
import 'chat_detailscreen.dart';

// ======================= LAB 6 - CHAT LIST =======================
// Second bottom navigation tab. Lists the registered users from the
// Firestore "Users" collection; tapping one opens ChatDetailScreen.
// =================================================================
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _searchChatController = TextEditingController();
  final ChatService _chatService = ChatService();
  String? _currentUserEmail;
  String _currentUserId = '';
  bool _isFirebaseUser = true;
  String _searchText = '';

  @override
  void initState() {
    super.initState();
    _loadCurrentUserEmail();
  }

  Future<void> _loadCurrentUserEmail() async {
    final userData = await userService.value.getUserData();
    if (!mounted) return;
    setState(() {
      _currentUserEmail = userData['email'];
      _currentUserId = (userData['uid'] ?? '').toString();
      // Chat runs on Firebase, so a DummyJSON session cannot use it.
      _isFirebaseUser =
          userData['loginType'] == LoginType.firebase &&
          userService.value.currentUser != null;
    });
  }

  @override
  void dispose() {
    _searchChatController.dispose();
    super.dispose();
  }

  // LAB 6 - ENHANCEMENT 1: everyone except the logged-in user.
  // LAB 6 - ENHANCEMENT 2: filtered by name, username or email.
  List<Map<String, dynamic>> _filterUsers(List<Map<String, dynamic>> all) {
    final query = _searchText.trim().toLowerCase();
    return all.where((user) {
      if (user['uid'] == _currentUserId) return false;
      if (user['email'] == _currentUserEmail) return false;
      if (query.isEmpty) return true;
      final haystack = [
        user['firstName'],
        user['lastName'],
        user['username'],
        user['email'],
      ].map((v) => (v ?? '').toString().toLowerCase()).join(' ');
      return haystack.contains(query);
    }).toList();
  }

  String _displayName(Map<String, dynamic> user) {
    final name = '${user['firstName'] ?? ''} ${user['lastName'] ?? ''}'.trim();
    if (name.isNotEmpty) return name;
    return (user['username'] ?? user['email'] ?? 'Unknown').toString();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isFirebaseUser) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(24.r),
          child: CustomText(
            text:
                'Chat is available for Firebase accounts. Log in with an '
                'email, or sign up to start chatting.',
            fontSize: 14.sp,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        children: [
          SizedBox(height: 20.h),
          // LAB 6 - ENHANCEMENT 2: search bar at the top of the list.
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 23.w),
            child: TextField(
              controller: _searchChatController,
              textInputAction: TextInputAction.search,
              onChanged: (value) => setState(() => _searchText = value),
              decoration: InputDecoration(
                hintText: 'Search name or email...',
                hintStyle: TextStyle(fontFamily: 'Poppins', fontSize: 14.sp),
                prefixIcon: const Icon(Icons.search),
                suffixIcon: (_searchChatController.text.isNotEmpty)
                    ? IconButton(
                        tooltip: 'Clear',
                        icon: const Icon(Icons.cancel),
                        onPressed: () {
                          setState(() {
                            _searchChatController.clear();
                            _searchText = '';
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          SizedBox(height: 10.h),

          // Users Stream
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: _chatService.getUsersStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Container(
                  height: ScreenUtil().screenHeight * 0.6,
                  padding: EdgeInsets.all(16.sp),
                  child: const Center(
                    child: CircularProgressIndicator.adaptive(),
                  ),
                );
              }
              if (snapshot.hasError) {
                return _message('Error loading users');
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return _message('No users found');
              }

              final users = _filterUsers(snapshot.data!);

              if (users.isEmpty) {
                return _message(
                  _searchText.isEmpty
                      ? 'No other users yet...'
                      : 'No users match "$_searchText"',
                );
              }

              return ListView.builder(
                shrinkWrap: true,
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                physics: const NeverScrollableScrollPhysics(),
                itemCount: users.length,
                itemBuilder: (context, index) {
                  final user = users[index];
                  final name = _displayName(user);
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatDetailScreen(
                            currentUserEmail: _currentUserEmail!,
                            tappedUser: user,
                          ),
                        ),
                      );
                    },
                    child: Card(
                      child: ListTile(
                        leading: Hero(
                          tag: 'avatar_${user['uid']}',
                          child: CircleAvatar(
                            backgroundColor: Colors.amber.shade100,
                            child: CustomText(
                              text: name[0].toUpperCase(),
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.amber.shade900,
                            ),
                          ),
                        ),
                        title: CustomText(
                          text: name,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: CustomText(
                          text: user['email'] ?? 'No email',
                          fontSize: 12,
                          fontWeight: FontWeight.w300,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: const Icon(Icons.chevron_right),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _message(String text) {
    return Container(
      height: ScreenUtil().screenHeight * 0.6,
      padding: EdgeInsets.all(16.sp),
      child: Center(
        child: CustomText(
          text: text,
          fontSize: 16.sp,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
