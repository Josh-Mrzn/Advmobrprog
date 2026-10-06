import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:marzan_advmobprog/widgets/custom_text.dart';

import '../services/chat_service.dart';
import '../services/user_service.dart';

final ChatService chatService = ChatService();

// ======================= LAB 6 - ENHANCEMENT 3 =======================
// Chat detail screen, redesigned: header with avatar, gradient bubbles
// with tails for my messages, timestamps, sending/delivered/seen states
// and fade + slide animations for new messages.
// =====================================================================
class ChatDetailScreen extends StatefulWidget {
  final String currentUserEmail;
  final Map<String, dynamic> tappedUser;

  const ChatDetailScreen({
    super.key,
    required this.currentUserEmail,
    required this.tappedUser,
  });

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final TextEditingController _msgCtrl = TextEditingController();
  final FocusNode _msgFocus = FocusNode();
  final ScrollController _scrollCtrl = ScrollController();

  late Future<String> _currentUserIdFuture;
  bool _isSending = false;
  bool _hasText = false;
  bool _markingSeen = false;

  // Messages already animated in, so scrolling back does not replay them.
  final Set<String> _animatedIds = {};

  @override
  void initState() {
    super.initState();
    _currentUserIdFuture = _getCurrentUserId();
    _msgCtrl.addListener(() {
      final hasText = _msgCtrl.text.trim().isNotEmpty;
      if (hasText != _hasText) setState(() => _hasText = hasText);
    });
  }

  Future<String> _getCurrentUserId() async {
    final userData = await userService.value.getUserData();
    return (userData['uid'] ?? '').toString();
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    _msgFocus.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _send(String currentUserId, String receiverId) async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() => _isSending = true);
    // Clear right away; the message shows up as "sending..." in the list.
    _msgCtrl.clear();
    _msgFocus.requestFocus();

    if (_scrollCtrl.hasClients) {
      _scrollCtrl.animateTo(
        0.0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    }

    try {
      await chatService.sendMessage(receiverId, text);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to send: $e')));
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  // Mark incoming messages as seen once, after this frame is built.
  void _markSeen(String currentUserId, String otherUserId) {
    if (_markingSeen) return;
    _markingSeen = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        await chatService.markAsSeen(currentUserId, otherUserId);
      } finally {
        _markingSeen = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final tappedUserId = (widget.tappedUser['uid'] ?? '').toString();
    final tappedUserName = _displayName(widget.tappedUser);
    final scheme = Theme.of(context).colorScheme;

    return FutureBuilder<String>(
      future: _currentUserIdFuture,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snap.hasError || !snap.hasData || snap.data!.isEmpty) {
          return const Scaffold(
            body: Center(child: Text('Error loading user data')),
          );
        }

        final currentUserId = snap.data!;

        return Scaffold(
          appBar: AppBar(
            titleSpacing: 0,
            title: Row(
              children: [
                Hero(
                  tag: 'avatar_$tappedUserId',
                  child: CircleAvatar(
                    radius: 18.r,
                    backgroundColor: Colors.amber.shade100,
                    child: CustomText(
                      text: tappedUserName[0].toUpperCase(),
                      fontSize: 15.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.amber.shade900,
                    ),
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomText(
                        text: tappedUserName,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      CustomText(
                        text: (widget.tappedUser['email'] ?? '').toString(),
                        fontSize: 11.sp,
                        color: scheme.onSurfaceVariant,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          body: Container(
            color: scheme.surfaceContainerLowest,
            child: Column(
              children: [
                // Messages
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: chatService.getMessage(currentUserId, tappedUserId),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return Center(
                          child: Text(
                            'Error loading messages: ${snapshot.error}',
                          ),
                        );
                      }

                      final docs = snapshot.data?.docs ?? [];

                      if (docs.isEmpty) {
                        return _EmptyChat(name: tappedUserName);
                      }

                      final hasUnseen = docs.any((d) {
                        final data = d.data() as Map<String, dynamic>;
                        return data['receiverId'] == currentUserId &&
                            data['seen'] == false;
                      });
                      if (hasUnseen) _markSeen(currentUserId, tappedUserId);

                      return ListView.builder(
                        controller: _scrollCtrl,
                        reverse: true,
                        padding: EdgeInsets.symmetric(
                          vertical: 12.h,
                          horizontal: 12.w,
                        ),
                        itemCount: docs.length,
                        itemBuilder: (context, index) {
                          final doc = docs[index];
                          final data = doc.data() as Map<String, dynamic>;
                          final isMe = data['senderId'] == currentUserId;

                          // Group consecutive messages from the same sender.
                          final newer = index > 0
                              ? docs[index - 1].data() as Map<String, dynamic>
                              : null;
                          final isLastInGroup =
                              newer == null ||
                              newer['senderId'] != data['senderId'];

                          final animate = _animatedIds.add(doc.id);

                          return _AnimatedMessage(
                            key: ValueKey(doc.id),
                            animate: animate,
                            fromRight: isMe,
                            child: _MessageBubble(
                              text: (data['message'] ?? '').toString(),
                              time: data['timestamp'] as Timestamp?,
                              isMe: isMe,
                              showTail: isLastInGroup,
                              status: !isMe
                                  ? null
                                  : doc.metadata.hasPendingWrites
                                  ? _Status.sending
                                  : data['seen'] == true
                                  ? _Status.seen
                                  : _Status.delivered,
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),

                // Composer
                _buildComposer(currentUserId, tappedUserId, scheme),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildComposer(
    String currentUserId,
    String tappedUserId,
    ColorScheme scheme,
  ) {
    return Material(
      color: scheme.surface,
      elevation: 8,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(12.w, 8.h, 8.w, 8.h),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: _msgCtrl,
                  focusNode: _msgFocus,
                  textInputAction: TextInputAction.send,
                  minLines: 1,
                  maxLines: 4,
                  onSubmitted: (_) => _send(currentUserId, tappedUserId),
                  style: TextStyle(fontFamily: 'Poppins', fontSize: 14.sp),
                  decoration: InputDecoration(
                    hintText: 'Type a message…',
                    hintStyle: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14.sp,
                    ),
                    filled: true,
                    fillColor: scheme.surfaceContainerHighest,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 10.h,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24.r),
                      borderSide: BorderSide.none,
                    ),
                    isDense: true,
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              // Send button grows in when there is text to send.
              AnimatedScale(
                scale: _hasText ? 1 : 0.85,
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutBack,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _hasText
                        ? scheme.primary
                        : scheme.surfaceContainerHighest,
                  ),
                  child: IconButton(
                    icon: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 180),
                      child: _isSending
                          ? SizedBox(
                              key: const ValueKey('spinner'),
                              width: 20.r,
                              height: 20.r,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: scheme.primary,
                              ),
                            )
                          : Icon(
                              Icons.send_rounded,
                              key: const ValueKey('send'),
                              color: _hasText
                                  ? scheme.onPrimary
                                  : scheme.onSurfaceVariant,
                            ),
                    ),
                    onPressed: _hasText
                        ? () => _send(currentUserId, tappedUserId)
                        : null,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _displayName(Map<String, dynamic> user) {
  final name = '${user['firstName'] ?? ''} ${user['lastName'] ?? ''}'.trim();
  if (name.isNotEmpty) return name;
  return (user['username'] ?? user['email'] ?? 'Unknown').toString();
}

enum _Status { sending, delivered, seen }

// Fade + slide in from the sender's side.
class _AnimatedMessage extends StatelessWidget {
  final bool animate;
  final bool fromRight;
  final Widget child;

  const _AnimatedMessage({
    super.key,
    required this.animate,
    required this.fromRight,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    if (!animate) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset((fromRight ? 24 : -24) * (1 - t), 12 * (1 - t)),
          child: child,
        ),
      ),
      child: child,
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final String text;
  final Timestamp? time;
  final bool isMe;
  final bool showTail;
  final _Status? status;

  const _MessageBubble({
    required this.text,
    required this.time,
    required this.isMe,
    required this.showTail,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final foreground = isMe ? scheme.onPrimary : scheme.onSurface;
    final radius = Radius.circular(18.r);
    final tail = Radius.circular(showTail ? 4.r : 18.r);

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(top: 2.h, bottom: showTail ? 8.h : 2.h),
        padding: EdgeInsets.fromLTRB(14.w, 9.h, 12.w, 6.h),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          gradient: isMe
              ? LinearGradient(
                  colors: [scheme.primary, scheme.primary.withAlpha(210)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isMe ? null : scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.only(
            topLeft: radius,
            topRight: radius,
            bottomLeft: isMe ? radius : tail,
            bottomRight: isMe ? tail : radius,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(20),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              widthFactor: 1,
              child: CustomText(
                text: text.isNotEmpty ? text : '[empty]',
                fontSize: 15.sp,
                color: foreground,
              ),
            ),
            SizedBox(height: 2.h),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomText(
                  text: _formatTime(time),
                  fontSize: 10.sp,
                  color: foreground.withAlpha(170),
                ),
                if (status != null) ...[
                  SizedBox(width: 4.w),
                  _StatusIndicator(status: status!, color: foreground),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String _formatTime(Timestamp? time) {
    if (time == null) return '';
    final date = time.toDate();
    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute ${date.hour < 12 ? 'AM' : 'PM'}';
  }
}

// "sending…" → ✓✓ delivered → blue ✓✓ seen, cross-faded.
class _StatusIndicator extends StatelessWidget {
  final _Status status;
  final Color color;

  const _StatusIndicator({required this.status, required this.color});

  @override
  Widget build(BuildContext context) {
    final Widget child = switch (status) {
      _Status.sending => Row(
        key: const ValueKey('sending'),
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.schedule, size: 12.sp, color: color.withAlpha(170)),
          SizedBox(width: 2.w),
          CustomText(
            text: 'sending…',
            fontSize: 10.sp,
            fontStyle: FontStyle.italic,
            color: color.withAlpha(170),
          ),
        ],
      ),
      _Status.delivered => Icon(
        Icons.done_all,
        key: const ValueKey('delivered'),
        size: 15.sp,
        color: color.withAlpha(170),
      ),
      _Status.seen => Icon(
        Icons.done_all,
        key: const ValueKey('seen'),
        size: 15.sp,
        color: Colors.lightBlueAccent,
      ),
    };

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      transitionBuilder: (child, animation) =>
          ScaleTransition(scale: animation, child: child),
      child: child,
    );
  }
}

class _EmptyChat extends StatelessWidget {
  final String name;

  const _EmptyChat({required this.name});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 400),
        builder: (context, t, child) => Opacity(opacity: t, child: child),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.waving_hand_rounded,
              size: 48.sp,
              color: Colors.amber.shade600,
            ),
            SizedBox(height: 12.h),
            CustomText(
              text: 'No messages yet',
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
            ),
            SizedBox(height: 4.h),
            CustomText(
              text: 'Say hi to $name!',
              fontSize: 13.sp,
              color: scheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}
