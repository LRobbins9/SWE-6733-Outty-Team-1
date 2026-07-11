import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/match_model.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../providers/match_provider.dart';
import '../utils/constants.dart';
import '../widgets/user_avatar.dart';
import 'chat_screen.dart';

class MatchesScreen extends StatefulWidget {
  const MatchesScreen({super.key});

  @override
  State<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends State<MatchesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool _matchesSearchQuery(UserModel user, String query) {
    final normalizedQuery = query.trim().toLowerCase();
    if (normalizedQuery.isEmpty) return true;
    return user.name.toLowerCase().contains(normalizedQuery);
  }

  void _showProfile(BuildContext context, UserModel other) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _ProfilePreviewSheet(user: other),
    );
  }

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
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    controller: _searchController,
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
                    onChanged: (value) {
                      setState(() => _searchQuery = value);
                    },
                    onSubmitted: (value) {
                      setState(() => _searchQuery = value);
                    },
                  ),
                ),
                if (matches.isEmpty)
                  Expanded(child: _buildEmptyState())
                else
                  Expanded(
                    child: ListView(
                      children: [
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                              final otherId = matches[i].otherUserId(currentUser.id);
                              return FutureBuilder<UserModel?>(
                                future: matchProv.getUserById(otherId),
                                builder: (context, snapshot) {
                                  if (!snapshot.hasData || snapshot.data == null) {
                                    return const SizedBox.shrink();
                                  }

                                  final otherUser = snapshot.data!;
                                  if (!_matchesSearchQuery(otherUser, _searchQuery)) {
                                    return const SizedBox.shrink();
                                  }

                                  return GestureDetector(
                                    onTap: () => _showProfile(context, otherUser),
                                    child: _NewMatchCircle(user: otherUser),
                                  );
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
                                if (!snapshot.hasData || snapshot.data == null) {
                                  return const SizedBox.shrink();
                                }

                                final otherUser = snapshot.data!;
                                if (!_matchesSearchQuery(otherUser, _searchQuery)) {
                                  return const SizedBox.shrink();
                                }

                                return _MatchTile(match: match, other: otherUser);
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
            Icon(Icons.message_outlined, size: 72, color: Colors.grey[300]),
            const SizedBox(height: 16),
            const Text(
              'No messages yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black54,
              ),
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
