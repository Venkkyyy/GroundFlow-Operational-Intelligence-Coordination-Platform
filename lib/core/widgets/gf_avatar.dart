import 'package:flutter/material.dart';

/// A user avatar that shows either a network image or initials derived from
/// [name], with a gradient background based on the name's hash.
///
/// An optional [statusColor] paints a small dot in the bottom-right corner to
/// indicate presence / member status.
class GFAvatar extends StatelessWidget {
  const GFAvatar({
    super.key,
    required this.name,
    this.imageUrl,
    this.size = 40.0,
    this.statusColor,
    this.textStyle,
  });

  final String name;
  final String? imageUrl;
  final double size;

  /// When non-null, a small dot of this color is painted in the bottom-right.
  final Color? statusColor;

  final TextStyle? textStyle;

  // ---------------------------------------------------------------------------
  // Gradient palette — 10 vibrant pairs derived deterministically from the
  // name's hash so the same name always gets the same gradient.
  // ---------------------------------------------------------------------------
  static const List<List<Color>> _gradients = [
    [Color(0xFF3D5AFE), Color(0xFF8C9EFF)], // deep indigo → periwinkle
    [Color(0xFF00B0FF), Color(0xFF80D8FF)], // blue → light-blue
    [Color(0xFF00BFA5), Color(0xFFA7FFEB)], // teal → mint
    [Color(0xFFFF6D00), Color(0xFFFFD180)], // deep-orange → amber
    [Color(0xFFD500F9), Color(0xFFEA80FC)], // purple → orchid
    [Color(0xFFE91E63), Color(0xFFF48FB1)], // pink → light-pink
    [Color(0xFF76FF03), Color(0xFFCCFF90)], // lime → light-lime
    [Color(0xFFFFD600), Color(0xFFFFFF8D)], // yellow → light-yellow
    [Color(0xFF6200EA), Color(0xFFB388FF)], // deep-purple → lavender
    [Color(0xFF00C853), Color(0xFFB9F6CA)], // green → light-green
  ];

  List<Color> _gradientForName(String name) {
    final hash = name.codeUnits.fold(0, (acc, unit) => acc + unit);
    return _gradients[hash % _gradients.length];
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      return parts[0].substring(0, parts[0].length.clamp(1, 2)).toUpperCase();
    }
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final dotSize = size * 0.27;
    final fontSize = size * 0.36;
    final gradient = _gradientForName(name);

    Widget avatar;

    if (imageUrl != null && imageUrl!.isNotEmpty) {
      avatar = ClipOval(
        child: Image.network(
          imageUrl!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _initialsWidget(gradient, fontSize),
        ),
      );
    } else {
      avatar = _initialsWidget(gradient, fontSize);
    }

    if (statusColor == null) return SizedBox(width: size, height: size, child: avatar);

    return SizedBox(
      width: size + dotSize * 0.5,
      height: size + dotSize * 0.5,
      child: Stack(
        children: [
          Positioned(top: 0, left: 0, child: SizedBox(width: size, height: size, child: avatar)),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: dotSize,
              height: dotSize,
              decoration: BoxDecoration(
                color: statusColor,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _initialsWidget(List<Color> gradient, double fontSize) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradient,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        _initials(name),
        style: (textStyle ??
                TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 0.5,
                )),
      ),
    );
  }
}
