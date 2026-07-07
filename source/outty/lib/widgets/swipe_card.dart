import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' show Vector3;
import '../models/user_model.dart';
import '../utils/constants.dart';
import 'adventure_chip.dart';

/// Draggable card displayed in the Discover feed.
///
/// Swipe right → [onLike], swipe left → [onPass].
/// Buttons at the bottom of the parent screen may also call [likeFromButton]
/// and [passFromButton] via a [SwipeCardController].
class SwipeCard extends StatefulWidget {
  const SwipeCard({
    super.key,
    required this.user,
    required this.onLike,
    required this.onPass,
    this.controller,
  });

  final UserModel user;
  final VoidCallback onLike;
  final VoidCallback onPass;
  final SwipeCardController? controller;

  @override
  State<SwipeCard> createState() => SwipeCardState();
}

class SwipeCardController {
  SwipeCardState? _state;
  void _attach(SwipeCardState state) => _state = state;
  void like() => _state?._animateOut(true);
  void pass() => _state?._animateOut(false);
}

class SwipeCardState extends State<SwipeCard>
    with SingleTickerProviderStateMixin {
  Offset _position = Offset.zero;
  late AnimationController _animCtrl;
  Animation<Offset>? _anim;
  bool _animating = false;

  static const double _swipeThreshold = 90;

  @override
  void initState() {
    super.initState();
    widget.controller?._attach(this);
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  // ── Drag handlers ──────────────────────────────────────────────────────────

  void _onPanUpdate(DragUpdateDetails d) {
    if (_animating) return;
    setState(() => _position += d.delta);
  }

  void _onPanEnd(DragEndDetails _) {
    if (_animating) return;
    if (_position.dx > _swipeThreshold) {
      _animateOut(true);
    } else if (_position.dx < -_swipeThreshold) {
      _animateOut(false);
    } else {
      _snapBack();
    }
  }

  // ── Animations ─────────────────────────────────────────────────────────────

  void _animateOut(bool isLike) {
    _animating = true;
    final target = Offset(isLike ? 600 : -600, _position.dy + 80);
    _anim = Tween<Offset>(begin: _position, end: target).animate(
      CurvedAnimation(parent: _animCtrl, curve: Curves.easeIn),
    )..addListener(() {
        setState(() => _position = _anim!.value);
      });

    _animCtrl.reset();
    _animCtrl.forward().whenComplete(() {
      if (isLike) {
        widget.onLike();
      } else {
        widget.onPass();
      }
    });
  }

  void _snapBack() {
    _anim = Tween<Offset>(begin: _position, end: Offset.zero).animate(
      CurvedAnimation(parent: _animCtrl, curve: Curves.elasticOut),
    )..addListener(() {
        setState(() => _position = _anim!.value);
      });

    _animCtrl.reset();
    _animCtrl.forward().whenComplete(() {
      _animating = false;
    });
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  String get _displayName {
    final trimmedName = widget.user.name.trim();
    return trimmedName.isEmpty ? 'Adventurer' : trimmedName;
  }

  String get _displayInitial => _displayName.substring(0, 1).toUpperCase();

  double get _rotation => (_position.dx / 400) * 0.25;

  @override
  Widget build(BuildContext context) {
    final likeOpacity = (_position.dx / 150).clamp(0.0, 1.0);
    final passOpacity = (-_position.dx / 150).clamp(0.0, 1.0);

    return GestureDetector(
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      child: Transform(
        transform: Matrix4.identity()
          ..translateByVector3(Vector3(_position.dx, _position.dy, 0))
          ..rotateZ(_rotation),
        alignment: Alignment.bottomCenter,
        child: Stack(
          children: [
            _buildCard(),
            // Like overlay
            if (likeOpacity > 0)
              Positioned(
                top: 40,
                left: 24,
                child: Opacity(
                  opacity: likeOpacity,
                  child: _buildStamp('LIKE', AppColors.like),
                ),
              ),
            // Pass overlay
            if (passOpacity > 0)
              Positioned(
                top: 40,
                right: 24,
                child: Opacity(
                  opacity: passOpacity,
                  child: _buildStamp('PASS', AppColors.pass),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard() {
    final user = widget.user;
    final displayName = _displayName;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Avatar / photo area
          Expanded(
            flex: 5,
            child: ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
              child: _buildAvatar(user),
            ),
          ),
          // Info area
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '$displayName, ${user.age}',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    _skillBadge(user.skillLevel),
                  ],
                ),
                if (user.location != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on,
                          size: 14, color: AppColors.textSecondary),
                      const SizedBox(width: 3),
                      Text(
                        user.location!,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 8),
                Text(
                  user.bio,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: user.adventureTypes
                      .take(4)
                      .map((a) => AdventureChip(
                            label: a,
                            selected: true,
                            compact: true,
                          ))
                      .toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(UserModel user) {
    // Use a gradient placeholder with initials since we have no real photos
    final hue = (_displayInitial.codeUnitAt(0) * 37) % 360;
    final color1 = HSLColor.fromAHSL(1, hue.toDouble(), 0.5, 0.35).toColor();
    final color2 =
        HSLColor.fromAHSL(1, (hue + 40) % 360, 0.5, 0.45).toColor();

    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [color1, color2],
            ),
          ),
        ),
        // Landscape icon overlay
        const Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Opacity(
            opacity: 0.15,
            child: Icon(
              Icons.terrain,
              size: 120,
              color: Colors.white,
            ),
          ),
        ),
        Center(
          child: Text(
            _displayInitial,
            style: const TextStyle(
              fontSize: 96,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _skillBadge(String level) {
    const skillColors = {
      'Beginner': Color(0xFF52B788),
      'Intermediate': Color(0xFFF4A261),
      'Advanced': Color(0xFF2D6A4F),
      'Expert': Color(0xFF1B2432),
    };
    final color = skillColors[level] ?? AppColors.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(80)),
      ),
      child: Text(
        level,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildStamp(String label, Color color) {
    return Transform.rotate(
      angle: label == 'LIKE' ? -0.3 : 0.3,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          border: Border.all(color: color, width: 3),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 28,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
          ),
        ),
      ),
    );
  }
}
