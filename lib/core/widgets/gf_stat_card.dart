import 'package:flutter/material.dart';

/// A compact dashboard stat card that shows a headline [value], a [label],
/// a colored [icon], and an optional [trend] string (e.g. "+3 ▲").
///
/// Example:
/// ```dart
/// GFStatCard(
///   value: '142',
///   label: 'Volunteers Present',
///   icon: Icons.people_rounded,
///   color: Color(0xFF3D5AFE),
///   trend: '+12 ▲',
///   trendPositive: true,
/// )
/// ```
class GFStatCard extends StatelessWidget {
  const GFStatCard({
    super.key,
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
    this.trend,
    this.trendPositive = true,
    this.onTap,
    this.width,
  });

  final String value;
  final String label;
  final IconData icon;
  final Color color;

  /// Optional trend string such as "+3 ▲" or "-1 ▼".
  final String? trend;

  /// Whether the trend is positive (green) or negative (red).
  final bool trendPositive;

  final VoidCallback? onTap;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final iconBg = color.withOpacity(0.12);
    final trendColor = trendPositive
        ? const Color(0xFF00C853)
        : const Color(0xFFD32F2F);

    return SizedBox(
      width: width,
      child: Material(
        color: colorScheme.surface,
        elevation: 1,
        shadowColor: Colors.black.withOpacity(0.07),
        surfaceTintColor: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon badge
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: Icon(icon, size: 22, color: color),
                ),
                const SizedBox(height: 12),

                // Value row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      value,
                      style: textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: colorScheme.onSurface,
                        height: 1,
                      ),
                    ),
                    if (trend != null) ...[
                      const SizedBox(width: 6),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: Text(
                          trend!,
                          style: textTheme.labelSmall?.copyWith(
                            color: trendColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),

                // Label
                Text(
                  label,
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withOpacity(0.55),
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
