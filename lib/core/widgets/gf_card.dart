import 'package:flutter/material.dart';

/// A reusable card widget that applies GroundFlow's consistent card styling:
/// white background, 16px border radius, subtle shadow, and optional tap.
class GFCard extends StatelessWidget {
  const GFCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin = const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    this.onTap,
    this.elevation = 1.0,
    this.borderRadius = 16.0,
    this.backgroundColor,
    this.border,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final VoidCallback? onTap;
  final double elevation;
  final double borderRadius;
  final Color? backgroundColor;
  final BoxBorder? border;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final cardColor = backgroundColor ?? colorScheme.surface;
    final radius = BorderRadius.circular(borderRadius);

    return Padding(
      padding: margin,
      child: Material(
        color: cardColor,
        elevation: elevation,
        shadowColor: Colors.black.withOpacity(0.08),
        surfaceTintColor: Colors.transparent,
        borderRadius: radius,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          splashColor: colorScheme.primary.withOpacity(0.06),
          highlightColor: colorScheme.primary.withOpacity(0.04),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: radius,
              border: border,
            ),
            padding: padding,
            child: child,
          ),
        ),
      ),
    );
  }
}
