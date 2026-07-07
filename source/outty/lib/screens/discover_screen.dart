import 'package:flutter/material.dart';
import 'package:outty/screens/profile_setup_screen.dart';
import 'package:provider/provider.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../providers/match_provider.dart';
import '../providers/navigation_notifier.dart';
import '../utils/constants.dart';
import '../widgets/swipe_card.dart';
import '../widgets/centered_content.dart';

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  final SwipeCardController _cardCtrl = SwipeCardController();
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
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            foregroundColor: AppColors.primary,
            elevation: 0,
            title: Row(
              children: [
                const Icon(Icons.terrain, size: 24, color: AppColors.primary),
                const SizedBox(width: 8),
                const Text(
                  'Outty',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 24,
                    color: AppColors.primary,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.tune, color: AppColors.textSecondary),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (context) => const ProfileSetupScreen(initialStep: 1),
                    ),
                  );
                },
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: matchProv.isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.primary))
              : Stack(
                  fit: StackFit.expand,
                  children: [
                    _buildScenicBackdrop(),
                    feed.isEmpty ? _buildEmptyState() : _buildFeed(feed),
                  ],
                ),
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
    final topCandidate = feed.first;

    return CenteredContent(
      maxWidth: 460,
      child: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Center(
                child: AspectRatio(
                  aspectRatio: 0.72,
                  child: Stack(
                    children: [
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
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _ActionButton(
                  icon: Icons.close,
                  color: AppColors.pass,
                  onTap: _cardCtrl.pass,
                  size: 56,
                ),
                _ActionButton(
                  icon: Icons.favorite,
                  color: AppColors.like,
                  onTap: _cardCtrl.like,
                  size: 66,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScenicBackdrop() {
    return IgnorePointer(
      child: Stack(
        children: [
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFFF8F6EF),
                    Color(0xFFF4F3EC),
                    Color(0xFFF7F8F3),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: -70,
            left: -10,
            child: _BackdropAccent(
              size: 260,
              color: const Color(0xFFF05A22).withAlpha(24),
            ),
          ),
          Positioned(
            top: 110,
            right: -60,
            child: _BackdropAccent(
              size: 240,
              color: const Color(0xFF2D6A4F).withAlpha(22),
            ),
          ),
          Positioned(
            bottom: 10,
            left: -40,
            child: _BackdropAccent(
              size: 220,
              color: const Color(0xFF4A90A4).withAlpha(20),
            ),
          ),
          const Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _BackdropHorizon(),
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
            const Icon(Icons.terrain, size: 80, color: AppColors.primaryLight),
            const SizedBox(height: 16),
            Text(
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
              label: Text('Refresh Feed'),
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

class _BackdropAccent extends StatelessWidget {
  const _BackdropAccent({
    required this.size,
    required this.color,
  });

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, Colors.transparent],
        ),
      ),
    );
  }
}

class _BackdropHorizon extends StatelessWidget {
  const _BackdropHorizon();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 220,
      child: Stack(
        children: [
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: 120,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x002D6A4F),
                    Color(0x142D6A4F),
                    Color(0x1F2D6A4F),
                  ],
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomLeft,
            child: Container(
              width: 320,
              height: 120,
              decoration: const BoxDecoration(
                color: Color(0x122D6A4F),
                borderRadius: BorderRadius.only(
                  topRight: Radius.elliptical(220, 110),
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomRight,
            child: Container(
              width: 360,
              height: 150,
              decoration: const BoxDecoration(
                color: Color(0x104A90A4),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.elliptical(260, 120),
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: 420,
              height: 96,
              decoration: const BoxDecoration(
                color: Color(0x16F05A22),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.elliptical(240, 80),
                  topRight: Radius.elliptical(240, 80),
                ),
              ),
            ),
          ),
          const Align(
            alignment: Alignment(0, 0.52),
            child: Opacity(
              opacity: 0.08,
              child: Icon(
                Icons.terrain_rounded,
                size: 190,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatefulWidget {
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
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final glowColor = widget.color.withAlpha(_isHovered ? 130 : 60);
    final blur = _isHovered ? 22.0 : 12.0;
    final spread = _isHovered ? 5.0 : 2.0;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedScale(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          scale: _isHovered ? 1.06 : 1.0,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOut,
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: glowColor,
                  blurRadius: blur,
                  spreadRadius: spread,
                ),
              ],
            ),
            child: Icon(
              widget.icon,
              color: widget.color,
              size: widget.size * 0.45,
            ),
          ),
        ),
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
    final currentUser = context.read<AuthProvider>().currentUser;

    return Material(
      color: Colors.transparent,
      child: Container(
        // Ensure the background covers the entire stack
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.9),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              // Vertical padding ensures content doesn't touch screen edges on small devices
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "It's a Match!",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 48),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _circularAvatar(currentUser?.avatarUrl, -15),
                      _circularAvatar(matchedUser.avatarUrl, 15),
                    ],
                  ),
                  const SizedBox(height: 64),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: CenteredContent(
                      maxWidth: 360,
                      child: Column(
                        children: [
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: () {
                                onDismiss();
                                context.read<NavigationNotifier>().switchToMatches();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30)),
                              ),
                              child: const Text('Send a message',
                                  style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: OutlinedButton(
                              onPressed: onDismiss,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                side: const BorderSide(color: Colors.white, width: 2),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30)),
                              ),
                              child: const Text('Keep Swiping',
                                  style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _circularAvatar(String? url, double offsetX) {
    final hasAvatar = url != null && url.trim().isNotEmpty;

    return Transform.translate(
      offset: Offset(offsetX, 0),
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 4),
          image: hasAvatar
              ? DecorationImage(image: NetworkImage(url), fit: BoxFit.cover)
              : null,
          color: Colors.grey[800],
        ),
        child: hasAvatar
            ? null
            : const Icon(Icons.person, size: 60, color: Colors.white),
      ),
    );
  }
}
