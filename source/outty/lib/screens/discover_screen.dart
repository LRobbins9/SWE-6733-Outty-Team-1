import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/match_model.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../providers/match_provider.dart';
import '../utils/constants.dart';
import '../widgets/swipe_card.dart';

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  SwipeCardController? _cardCtrl;
  bool _showMatchDialog = false;
  UserModel? _matchedUser;

  void _onLike(UserModel candidate) async {
    final auth = context.read<AuthProvider>();
    final matchProv = context.read<MatchProvider>();

    final match = await matchProv.swipeRight(auth.currentUser!, candidate);

    if (match != null && mounted) {
      setState(() {
        _matchedUser = candidate;
        _showMatchDialog = true;
      });
    }
  }

  void _onPass(UserModel candidate) {
    final auth = context.read<AuthProvider>();
    context.read<MatchProvider>().swipeLeft(auth.currentUser!.id, candidate.id);
  }

  @override
  Widget build(BuildContext context) {
    final matchProv = context.watch<MatchProvider>();
    final feed = matchProv.feed;

    return Stack(
      children: [
        Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            title: const Row(
              children: [
                Icon(Icons.terrain, size: 20),
                SizedBox(width: 6),
                Text(
                  'Outty',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 22),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: 'Reset feed',
                onPressed: () async {
                  final auth = context.read<AuthProvider>();
                  await context
                      .read<MatchProvider>()
                      .resetFeed(auth.currentUser!);
                },
              ),
            ],
          ),
          body: matchProv.isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.primary))
              : feed.isEmpty
                  ? _buildEmptyState()
                  : _buildFeed(feed),
        ),

        // Match overlay
        if (_showMatchDialog && _matchedUser != null)
          _MatchOverlay(
            matchedUser: _matchedUser!,
            onDismiss: () => setState(() {
              _showMatchDialog = false;
              _matchedUser = null;
            }),
          ),
      ],
    );
  }

  Widget _buildFeed(List<UserModel> feed) {
    _cardCtrl = SwipeCardController();
    final topCandidate = feed.first;

    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Stack(
              children: [
                // Background card shadow (next card peek)
                if (feed.length > 1)
                  Positioned(
                    top: 8,
                    left: 8,
                    right: 8,
                    bottom: 0,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(200),
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                // Top card
                SwipeCard(
                  key: ValueKey(topCandidate.id),
                  user: topCandidate,
                  controller: _cardCtrl,
                  onLike: () => _onLike(topCandidate),
                  onPass: () => _onPass(topCandidate),
                ),
              ],
            ),
          ),
        ),

        // Action buttons
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _ActionButton(
                icon: Icons.close,
                color: AppColors.pass,
                onTap: () => _cardCtrl?.pass(),
                size: 56,
              ),
              _ActionButton(
                icon: Icons.favorite,
                color: AppColors.like,
                onTap: () => _cardCtrl?.like(),
                size: 66,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.terrain, size: 80, color: AppColors.primaryLight),
            const SizedBox(height: 16),
            const Text(
              'No more adventurers nearby',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Check back soon or tap refresh to start over.',
              style: TextStyle(
                  fontSize: 14, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () async {
                final auth = context.read<AuthProvider>();
                await context
                    .read<MatchProvider>()
                    .resetFeed(auth.currentUser!);
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh Feed'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.color,
    required this.onTap,
    this.size = 56,
  });

  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color.withAlpha(60),
              blurRadius: 12,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Icon(icon, color: color, size: size * 0.45),
      ),
    );
  }
}

// ─── Match overlay ────────────────────────────────────────────────────────────

class _MatchOverlay extends StatelessWidget {
  const _MatchOverlay({
    required this.matchedUser,
    required this.onDismiss,
  });

  final UserModel matchedUser;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onDismiss,
      child: DecoratedBox(
        decoration: const BoxDecoration(color: AppColors.overlay),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.favorite,
                    size: 72, color: AppColors.secondary),
                const SizedBox(height: 16),
                const Text(
                  "It's an Adventure Match! 🏔️",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'You and ${matchedUser.name} both want to explore together!',
                  style: TextStyle(
                    color: Colors.white.withAlpha(220),
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: onDismiss,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text('Keep Exploring'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          onDismiss();
                          // Navigate to matches tab
                          final homeState = context
                              .findAncestorStateOfType<
                                  _DiscoverScreenState>();
                          homeState?.setState(() {});
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.secondary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text('Send Message'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
