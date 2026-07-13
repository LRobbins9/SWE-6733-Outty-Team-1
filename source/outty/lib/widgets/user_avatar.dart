import 'package:flutter/material.dart';

class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    required this.size,
    required this.photoUrl,
    required this.fallback,
    this.backgroundColor,
    this.borderColor,
    this.borderWidth = 0,
  });

  final double size;
  final String? photoUrl;
  final Widget fallback;
  final Color? backgroundColor;
  final Color? borderColor;
  final double borderWidth;

  bool get _hasPhoto => photoUrl != null && photoUrl!.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final fillColor = backgroundColor ?? Colors.grey[200]!;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: fillColor,
        border: borderWidth > 0
            ? Border.all(
                color: borderColor ?? Colors.transparent,
                width: borderWidth,
              )
            : null,
      ),
      child: ClipOval(
        child: _hasPhoto
            ? Image.network(
                photoUrl!,
                width: size,
                height: size,
                fit: BoxFit.cover,
                webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
                errorBuilder: (context, error, stackTrace) {
                  return ColoredBox(
                    color: fillColor,
                    child: Center(child: fallback),
                  );
                },
              )
            : ColoredBox(
                color: fillColor,
                child: Center(child: fallback),
              ),
      ),
    );
  }
}
