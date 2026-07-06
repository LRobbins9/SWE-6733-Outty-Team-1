import 'package:flutter/material.dart';
import '../utils/constants.dart';

/// A tappable chip representing a single adventure type.
class AdventureChip extends StatelessWidget {
  const AdventureChip({
    super.key,
    required this.label,
    this.selected = false,
    this.onTap,
    this.compact = false,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    IconData? getIconForLabel(String label) {
      switch (label.toLowerCase()) {
        case 'hiking': return Icons.terrain;
        case 'climbing': return Icons.park_outlined;
        case 'cycling': return Icons.directions_bike;
        case 'skiing': return Icons.downhill_skiing;
        case 'surfing': return Icons.surfing;
        case 'camping': return Icons.shutter_speed;
        default: return null;
      }
    }

    final icon = getIconForLabel(label);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 8 : 12,
          vertical: compact ? 4 : 7,
        ),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.primary : Colors.grey[300]!,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: compact ? 14 : 16,
                color: selected ? Colors.white : AppColors.primary,
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: compact ? 11 : 13,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
