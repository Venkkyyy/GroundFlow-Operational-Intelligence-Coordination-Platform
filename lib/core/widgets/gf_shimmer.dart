import 'dart:math' as math;
import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// Shimmer animation helpers
// ---------------------------------------------------------------------------

/// Internal shimmer gradient that sweeps left-to-right.
class _ShimmerGradient extends StatefulWidget {
  const _ShimmerGradient({required this.child});
  final Widget child;

  @override
  State<_ShimmerGradient> createState() => _ShimmerGradientState();
}

class _ShimmerGradientState extends State<_ShimmerGradient>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            final double slide = _controller.value * (bounds.width + 200) - 100;
            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: const [
                Color(0xFFE8E8E8),
                Color(0xFFF5F5F5),
                Color(0xFFFFFFFF),
                Color(0xFFF5F5F5),
                Color(0xFFE8E8E8),
              ],
              stops: const [0.0, 0.3, 0.5, 0.7, 1.0],
              transform: _SlideGradientTransform(slide),
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

class _SlideGradientTransform extends GradientTransform {
  const _SlideGradientTransform(this.slideX);
  final double slideX;

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(slideX, 0, 0);
  }
}

// ---------------------------------------------------------------------------
// GFShimmerCard
// ---------------------------------------------------------------------------

/// A single shimmer placeholder shaped like a content card.
///
/// Optionally set [height] and [width] to control dimensions. By default it
/// fills the available width at a sensible card height.
class GFShimmerCard extends StatelessWidget {
  const GFShimmerCard({
    super.key,
    this.height = 88,
    this.width = double.infinity,
    this.borderRadius = 16.0,
    this.margin = const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    this.showAvatar = false,
    this.lines = 2,
  });

  final double height;
  final double width;
  final double borderRadius;
  final EdgeInsetsGeometry margin;

  /// When true, an avatar circle placeholder appears on the left.
  final bool showAvatar;

  /// Number of text line skeletons inside the card.
  final int lines;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? const Color(0xFF2C2C2C) : const Color(0xFFE8E8E8);

    return Padding(
      padding: margin,
      child: _ShimmerGradient(
        child: Container(
          height: height,
          width: width,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: baseColor,
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (showAvatar) ...[
                _ShimmerBlock(width: 44, height: 44, isCircle: true, baseColor: baseColor),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: List.generate(
                    math.max(1, lines),
                    (i) => Padding(
                      padding: EdgeInsets.only(bottom: i < lines - 1 ? 8 : 0),
                      child: _ShimmerBlock(
                        width: i == lines - 1 ? double.infinity * 0.6 : double.infinity,
                        height: 12,
                        isCircle: false,
                        baseColor: baseColor,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShimmerBlock extends StatelessWidget {
  const _ShimmerBlock({
    required this.width,
    required this.height,
    required this.isCircle,
    required this.baseColor,
  });
  final double width;
  final double height;
  final bool isCircle;
  final Color baseColor;

  @override
  Widget build(BuildContext context) {
    final highlight = baseColor == const Color(0xFF2C2C2C)
        ? const Color(0xFF3E3E3E)
        : const Color(0xFFF0F0F0);
    return Container(
      width: width.isInfinite ? null : width,
      height: height,
      decoration: BoxDecoration(
        color: highlight,
        borderRadius: isCircle ? null : BorderRadius.circular(6),
        shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// GFShimmerList
// ---------------------------------------------------------------------------

/// A scrollable (or non-scrollable) vertical list of [GFShimmerCard] items.
///
/// Use this as a full-screen loading state before real data arrives.
class GFShimmerList extends StatelessWidget {
  const GFShimmerList({
    super.key,
    this.itemCount = 6,
    this.shrinkWrap = false,
    this.physics,
    this.cardHeight = 88,
    this.showAvatars = false,
    this.cardLines = 2,
    this.margin = const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  });

  final int itemCount;
  final bool shrinkWrap;
  final ScrollPhysics? physics;
  final double cardHeight;
  final bool showAvatars;
  final int cardLines;
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: shrinkWrap,
      physics: physics ?? (shrinkWrap ? const NeverScrollableScrollPhysics() : null),
      itemCount: itemCount,
      itemBuilder: (context, index) => GFShimmerCard(
        height: cardHeight,
        margin: margin,
        showAvatar: showAvatars,
        lines: cardLines,
      ),
    );
  }
}
