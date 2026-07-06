import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/match_model.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../providers/chat_provider.dart';
import '../providers/match_provider.dart';
import '../utils/constants.dart';
import '../widgets/message_bubble.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({
    super.key,
    required this.match,
    required this.otherUser,
  });

  final MatchModel match;
  final UserModel otherUser;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    final chat = context.read<ChatProvider>();
    // Start listening to Firestore
    chat.listenToMessages(widget.match.id);
    
    // Mark messages as read
    final auth = context.read<AuthProvider>();
    chat.markRead(widget.match.id, auth.currentUser!.id);

    // Seed the match with an icebreaker if chat is empty
    _seedIfNeeded();
  }

  Future<void> _seedIfNeeded() async {
    final chat = context.read<ChatProvider>();
    await chat.seedMatchMessage(
      matchId: widget.match.id,
      fromUserId: widget.otherUser.id,
      fromUserName: widget.otherUser.name,
    );
  }

  @override
  void dispose() {
    // Unsubscribe from Firestore
    context.read<ChatProvider>().stopListening(widget.match.id);
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _sendMessage() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;

    final currentUser = context.read<AuthProvider>().currentUser!;
    final chat = context.read<ChatProvider>();

    _msgCtrl.clear();
    
    await chat.sendMessage(
      matchId: widget.match.id,
      senderId: currentUser.id,
      content: text,
    );

    if (!mounted) return;

    // Update last message preview in matches list
    context
        .read<MatchProvider>()
        .updateLastMessage(widget.match.id, text);

    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = context.watch<AuthProvider>().currentUser!;
    final messages =
        context.watch<ChatProvider>().getMessages(widget.match.id);
    final other = widget.otherUser;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
        leadingWidth: 44,
        title: Row(
          children: [
            _buildAvatar(other, 20),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  other.name,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 18),
                ),
                Text(
                  other.location ?? other.skillLevel,
                  style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showProfile(context, other),
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: messages.isEmpty
                ? Center(
                    child: Text(
                      'Say hello to ${other.name}!',
                      style: TextStyle(
                          color: AppColors.textSecondary, fontSize: 15),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    itemCount: messages.length,
                    itemBuilder: (ctx, i) {
                      final msg = messages[i];
                      final isSent = msg.senderId == currentUser.id;
                      return MessageBubble(
                        content: msg.content,
                        isSent: isSent,
                        time: _formatTime(msg.sentAt),
                      );
                    },
                  ),
          ),

          // Input bar
          SafeArea(
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                      color: Color(0x14000000),
                      blurRadius: 8,
                      offset: Offset(0, -2)),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _msgCtrl,
                      textCapitalization: TextCapitalization.sentences,
                      onSubmitted: (_) => _sendMessage(),
                      decoration: InputDecoration(
                        hintText: 'Message ${other.name}…',
                        hintStyle: const TextStyle(
                            color: AppColors.textSecondary),
                        filled: true,
                        fillColor: AppColors.background,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _sendMessage,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.send,
                          color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(UserModel user, double radius) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: Colors.grey[200],
      backgroundImage: user.avatarUrl != null ? NetworkImage(user.avatarUrl!) : null,
      child: user.avatarUrl == null
          ? Text(
              user.name.substring(0, 1),
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: radius * 0.9),
            )
          : null,
    );
  }

  void _showProfile(BuildContext context, UserModel user) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _ProfilePreviewSheet(user: user),
    );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

class _ProfilePreviewSheet extends StatelessWidget {
  const _ProfilePreviewSheet({required this.user});
  final UserModel user;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey.withAlpha(80),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Text(
            '${user.name}, ${user.age}',
            style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary),
          ),
          if (user.location != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.location_on,
                    size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text(user.location!,
                    style: TextStyle(
                        color: AppColors.textSecondary, fontSize: 13)),
              ],
            ),
          ],
          const SizedBox(height: 10),
          Text(user.bio,
              style: TextStyle(
                  color: AppColors.textSecondary, fontSize: 14)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: user.adventureTypes
                .map((a) => Chip(
                      label: Text(a,
                          style: const TextStyle(
                              color: AppColors.primary, fontSize: 12)),
                      backgroundColor:
                          AppColors.primary.withAlpha(20),
                      side: BorderSide(
                          color: AppColors.primary.withAlpha(60)),
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                    ))
                .toList(),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
