import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/match_model.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../providers/match_provider.dart';
import '../utils/constants.dart';
import '../widgets/user_avatar.dart';
import 'chat_screen.dart';

class MatchesScreen extends StatelessWidget {
  const MatchesScreen({super.key});

  static const _loadingBody = Center(
    child: CircularProgressIndicator(color: AppColors.primary),
  );

  @override
  Widget build(BuildContext context) {
    final matches = context.watch<MatchProvider>().matches;
    final currentUser = context.watch<AuthProvider>().currentUser;
    final matchProv = context.read<MatchProvider>();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Chats',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      body: currentUser == null
          ? _loadingBody
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search for partners',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                if (matches.isEmpty)
                  Expanded(child: _buildEmptyState())
                else
                  Expanded(
                    child: ListView(
                      children: [
                        const Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: Text(
                            'Matches',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        SizedBox(
                          height: 100,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            itemCount: matches.length,
                            itemBuilder: (ctx, i) {
                              final otherId = matches[i].otherUserId(
                                currentUser.id,
                              );
                              return FutureBuilder<UserModel?>(
                                future: matchProv.getUserById(otherId),
                                builder: (context, snapshot) {
                                  if (!snapshot.hasData ||
                                      snapshot.data == null) {
                                    return const SizedBox.shrink();
                                  }
                                  return _NewMatchCircle(user: snapshot.data!);
                                },
                              );
                            },
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text(
                            'Messages',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: matches.length,
                          itemBuilder: (ctx, i) {
                            final match = matches[i];
                            final otherId = match.otherUserId(currentUser.id);

                            return FutureBuilder<UserModel?>(
                              future: matchProv.getUserById(otherId),
                              builder: (context, snapshot) {
                                if (!snapshot.hasData ||
                                    snapshot.data == null) {
                                  return const SizedBox.shrink();
                                }
                                return _MatchTile(
                                  match: match,
                                  other: snapshot.data!,
                                );
                              },
                            );
                          },
                        ),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.message_outlined, size: 72, color: Colors.grey[300]),
            const SizedBox(height: 16),
            const Text(
              'No messages yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NewMatchCircle extends StatelessWidget {
  const _NewMatchCircle({required this.user});
  final UserModel user;

  String get _displayName {
    final trimmedName = user.name.trim();
    return trimmedName.isEmpty ? 'Adventurer' : trimmedName;
  }

  bool get _hasAvatar => (user.avatarUrl?.trim().isNotEmpty ?? false);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        children: [
          UserAvatar(
            size: 64,
            photoUrl: _hasAvatar ? user.avatarUrl : null,
            backgroundColor: Colors.grey[200],
            fallback: const Icon(Icons.person, color: Colors.white),
          ),
          const SizedBox(height: 4),
          Text(
            _displayName.split(' ')[0],
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

class _MatchTile extends StatelessWidget {
  const _MatchTile({required this.match, required this.other});

  final MatchModel match;
  final UserModel other;

  String get _displayName {
    final trimmedName = other.name.trim();
    return trimmedName.isEmpty ? 'Adventurer' : trimmedName;
  }

  bool get _hasAvatar => (other.avatarUrl?.trim().isNotEmpty ?? false);

  @override
  Widget build(BuildContext context) {
    final lastMsg = match.lastMessage ?? 'Say hello!';

    return ListTile(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatScreen(match: match, otherUser: other),
          ),
        );
      },
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: UserAvatar(
        size: 60,
        photoUrl: _hasAvatar ? other.avatarUrl : null,
        backgroundColor: Colors.grey[200],
        fallback: const Icon(Icons.person, color: Colors.white),
      ),
      title: Text(
        '$_displayName, ${other.age}',
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
      subtitle: Text(
        lastMsg,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: match.lastMessage == null
              ? AppColors.primary
              : AppColors.textSecondary,
          fontStyle: match.lastMessage == null
              ? FontStyle.italic
              : FontStyle.normal,
          fontSize: 13,
        ),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            _formatTime(match.lastMessageAt ?? match.matchedAt),
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
          if (match.hasUnreadMessages) ...[
            const SizedBox(height: 4),
            Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m';
    if (diff.inDays < 1) return '${diff.inHours}h';
    return '${diff.inDays}d';
  }
}
