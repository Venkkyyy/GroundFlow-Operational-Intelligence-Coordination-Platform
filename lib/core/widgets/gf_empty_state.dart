import 'package:flutter/material.dart';

/// A centered empty-state widget for lists and dashboards that have no data.
///
/// Shows a large icon in a soft container, a [title], an optional [subtitle],
/// and an optional action button labelled [actionLabel].
class GFEmptyState extends StatelessWidget {
  const GFEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
    this.iconSize = 72.0,
    this.iconColor,
    this.iconBackgroundColor,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  final double iconSize;
  final Color? iconColor;
  final Color? iconBackgroundColor;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final effectiveIconColor =
        iconColor ?? colorScheme.onSurface.withOpacity(0.35);
    final effectiveIconBg =
        iconBackgroundColor ?? colorScheme.onSurface.withOpacity(0.06);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon container
            Container(
              width: iconSize * 1.4,
              height: iconSize * 1.4,
              decoration: BoxDecoration(
                color: effectiveIconBg,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(icon, size: iconSize, color: effectiveIconColor),
            ),
            const SizedBox(height: 24),

            // Title
            Text(
              title,
              textAlign: TextAlign.center,
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
              ),
            ),

            // Subtitle
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.55),
                  height: 1.5,
                ),
              ),
            ],

            // Action button
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 24),
              FilledButton.tonal(
                onPressed: onAction,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28,
                    vertical: 12,
                  ),
                ),
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
