import 'package:flutter/material.dart';

/// Visual style variants for [GFStatusChip].
enum ChipStyle {
  /// Solid background filled with [color].
  filled,

  /// Transparent background with a [color] border.
  outlined,

  /// Light tint of [color] as background, [color] text — the default for
  /// status badges.
  soft,
}

/// A compact badge/chip for displaying status labels with optional icons.
///
/// Example usage:
/// ```dart
/// GFStatusChip(
///   label: 'Present',
///   color: Colors.green,
///   style: ChipStyle.soft,
///   icon: Icons.check_circle_outline,
/// )
/// ```
class GFStatusChip extends StatelessWidget {
  const GFStatusChip({
    super.key,
    required this.label,
    required this.color,
    this.icon,
    this.style = ChipStyle.soft,
    this.textStyle,
    this.padding,
  });

  final String label;
  final Color color;
  final IconData? icon;
  final ChipStyle style;
  final TextStyle? textStyle;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final effectivePadding = padding ??
        const EdgeInsets.symmetric(horizontal: 10, vertical: 4);

    Color bg;
    Color fg;
    Border? border;

    switch (style) {
      case ChipStyle.filled:
        bg = color;
        fg = _contrastColor(color);
        break;
      case ChipStyle.outlined:
        bg = Colors.transparent;
        fg = color;
        border = Border.all(color: color, width: 1.5);
        break;
      case ChipStyle.soft:
        bg = color.withOpacity(0.12);
        fg = color;
        break;
    }

    final labelWidget = Text(
      label,
      style: (textStyle ??
              const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ))
          .copyWith(color: fg),
    );

    return Container(
      padding: effectivePadding,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(100),
        border: border,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: fg),
            const SizedBox(width: 4),
          ],
          labelWidget,
        ],
      ),
    );
  }

  /// Returns black or white depending on which provides better contrast.
  Color _contrastColor(Color bg) {
    final luminance = bg.computeLuminance();
    return luminance > 0.35 ? Colors.black87 : Colors.white;
  }
}
