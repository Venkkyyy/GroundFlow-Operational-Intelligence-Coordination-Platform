import 'package:flutter/material.dart';

/// A horizontal pipeline progress indicator that shows a sequence of named
/// [stages] connected by thin lines, with the current stage highlighted.
///
/// Completed stages render with a filled circle; the active stage shows a
/// pulsing ring; future stages are muted.
///
/// Example:
/// ```dart
/// GFPipelineBar(
///   stages: ['Shot', 'Handed In', 'Ingested', 'Verified', 'Backed Up', 'Editing', 'Delivered'],
///   currentStage: 2,
/// )
/// ```
class GFPipelineBar extends StatelessWidget {
  const GFPipelineBar({
    super.key,
    required this.stages,
    required this.currentStage,
    this.stageColors,
    this.showLabels = true,
    this.height = 56.0,
  });

  final List<String> stages;

  /// 0-based index of the stage currently in progress.
  final int currentStage;

  /// Optional per-stage colors. Falls back to the theme primary color.
  final List<Color>? stageColors;

  /// Whether to show the stage label text below each dot.
  final bool showLabels;

  final double height;

  Color _stageColor(int index, Color primary) {
    if (stageColors != null && index < stageColors!.length) {
      return stageColors![index];
    }
    return primary;
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final surface = Theme.of(context).colorScheme.surface;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final textTheme = Theme.of(context).textTheme;

    return SizedBox(
      height: showLabels ? height + 24 : height,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: List.generate(stages.length * 2 - 1, (i) {
              // Even indices → stage dots; odd → connector lines.
              if (i.isOdd) {
                final stageIndex = i ~/ 2;
                final isCompleted = stageIndex < currentStage;
                return Expanded(
                  child: Container(
                    height: 2,
                    color: isCompleted
                        ? _stageColor(stageIndex, primary)
                        : onSurface.withOpacity(0.15),
                  ),
                );
              }

              final stageIndex = i ~/ 2;
              final isCompleted = stageIndex < currentStage;
              final isActive = stageIndex == currentStage;
              final color = _stageColor(stageIndex, primary);

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _StageDot(
                    isCompleted: isCompleted,
                    isActive: isActive,
                    color: isCompleted || isActive
                        ? color
                        : onSurface.withOpacity(0.2),
                    surface: surface,
                  ),
                  if (showLabels) ...[
                    const SizedBox(height: 4),
                    SizedBox(
                      width: 56,
                      child: Text(
                        stages[stageIndex],
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.labelSmall?.copyWith(
                          fontSize: 9,
                          fontWeight: isActive
                              ? FontWeight.w700
                              : FontWeight.w400,
                          color: isActive
                              ? color
                              : isCompleted
                                  ? onSurface.withOpacity(0.7)
                                  : onSurface.withOpacity(0.4),
                        ),
                      ),
                    ),
                  ],
                ],
              );
            }),
          );
        },
      ),
    );
  }
}

class _StageDot extends StatelessWidget {
  const _StageDot({
    required this.isCompleted,
    required this.isActive,
    required this.color,
    required this.surface,
  });

  final bool isCompleted;
  final bool isActive;
  final Color color;
  final Color surface;

  @override
  Widget build(BuildContext context) {
    if (isCompleted) {
      return Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        alignment: Alignment.center,
        child: const Icon(Icons.check_rounded, size: 12, color: Colors.white),
      );
    }

    if (isActive) {
      return Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: color, width: 2.5),
        ),
        alignment: Alignment.center,
        child: Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
      );
    }

    // Future stage
    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 1.5),
        color: surface,
      ),
    );
  }
}
