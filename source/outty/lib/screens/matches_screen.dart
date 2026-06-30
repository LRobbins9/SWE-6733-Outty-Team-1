import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/match_model.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../providers/match_provider.dart';
import '../utils/constants.dart';
import 'chat_screen.dart';

class MatchesScreen extends StatelessWidget {
  const MatchesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final matches = context.watch<MatchProvider>().matches;
    final currentUser = context.watch<AuthProvider>().currentUser!;
    final matchProv = context.read<MatchProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Matches'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: matches.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: matches.length,
              itemBuilder: (ctx, i) {
                final match = matches[i];
                final otherId = match.otherUserId(currentUser.id);
                final other = matchProv.getUserById(otherId);
                if (other == null) return const SizedBox.shrink();
                return _MatchTile(match: match, other: other);
              },
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
            Icon(Icons.favorite_border,
                size: 72, color: AppColors.primaryLight.withAlpha(150)),
            const SizedBox(height: 16),
            const Text(
              'No matches yet',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              'Start swiping to find your adventure partner!',
              style:
                  TextStyle(fontSize: 14, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _MatchTile extends StatelessWidget {
  const _MatchTile({required this.match, required this.other});

  final MatchModel match;
  final UserModel other;

  @override
  Widget build(BuildContext context) {
    final hue = (other.name.codeUnitAt(0) * 37) % 360;
    final avatarColor =
        HSLColor.fromAHSL(1, hue.toDouble(), 0.5, 0.45).toColor();
    final lastMsg = match.lastMessage ?? 'You matched! Say hello 👋';

    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: CircleAvatar(
        radius: 28,
        backgroundColor: avatarColor,
        child: Text(
          other.name.substring(0, 1),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      title: Text(
        '${other.name}, ${other.age}',
        style: const TextStyle(
            fontWeight: FontWeight.w600, color: AppColors.textPrimary),
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
            style:
                const TextStyle(fontSize: 11, color: AppColors.textSecondary),
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
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatScreen(match: match, otherUser: other),
          ),
        );
      },
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
