import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/glass_theme.dart';

/// Clean, Sharp Card Container (Zero Glow, Crisp Borders)
class GlassContainer extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final VoidCallback? onTap;
  final Color? borderColor;

  const GlassContainer({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding = const EdgeInsets.all(18),
    this.margin,
    this.borderRadius = 16.0,
    this.onTap,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        color: GlassTheme.cardBg,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: borderColor ?? GlassTheme.border,
          width: 1.0,
        ),
      ),
      child: Padding(
        padding: padding,
        child: child,
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(borderRadius),
        child: content,
      );
    }
    return content;
  }
}

/// Clean Minimal Status Pill
class GlassPill extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color color;
  final VoidCallback? onTap;

  const GlassPill({
    super.key,
    required this.label,
    this.icon,
    this.color = GlassTheme.white,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Widget pill = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withValues(alpha: 0.25),
          width: 1.0,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: GoogleFonts.roboto(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: pill,
      );
    }
    return pill;
  }
}

/// High-Contrast Monochrome Button
class MetallicButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback onPressed;
  final bool isSecondary;
  final double? width;
  final double height;

  const MetallicButton({
    super.key,
    required this.label,
    this.icon,
    required this.onPressed,
    this.isSecondary = false,
    this.width,
    this.height = 48,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: isSecondary ? const Color(0xFF18181B) : GlassTheme.white,
          foregroundColor: isSecondary ? GlassTheme.white : GlassTheme.black,
          elevation: 0,
          side: BorderSide(
            color: isSecondary ? GlassTheme.border : GlassTheme.white,
            width: 1.0,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        onPressed: onPressed,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 17, color: isSecondary ? GlassTheme.white : GlassTheme.black),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: GoogleFonts.roboto(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSecondary ? GlassTheme.white : GlassTheme.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Centric Top Bar (Clean, Minimal, Zero Glow)
class CentricTopBar extends StatelessWidget {
  final String title;
  final String subtitle;
  final String role;
  final String? photoUrl;
  final String? avatarText;
  final VoidCallback onRoleTap;
  final VoidCallback onProfileTap;

  const CentricTopBar({
    super.key,
    required this.title,
    required this.subtitle,
    required this.role,
    this.photoUrl,
    this.avatarText,
    required this.onRoleTap,
    required this.onProfileTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
      decoration: const BoxDecoration(
        color: GlassTheme.black,
        border: Border(
          bottom: BorderSide(color: GlassTheme.border, width: 1),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            // Left: Back to Global Home
            IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
              onPressed: () => Navigator.maybePop(context),
              tooltip: 'Back to Global Home',
            ),
            const SizedBox(width: 4),

            // Center: Title & Status
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.roboto(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: GlassTheme.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: GlassTheme.statusGreen.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: GlassTheme.statusGreen.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          'SYNCED',
                          style: GoogleFonts.roboto(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: GlassTheme.statusGreen,
                          ),
                        ),
                      ),
                    ],
                  ),
                  RichText(
                    text: TextSpan(
                      style: GoogleFonts.roboto(fontSize: 11.5, color: GlassTheme.mutedSilver),
                      children: [
                        const TextSpan(text: 'Live Ground Protocol • '),
                        TextSpan(
                          text: subtitle.contains('•') ? subtitle.split('•').last.trim() : subtitle,
                          style: const TextStyle(color: GlassTheme.accentEmerald, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Right: Role Switcher Chip
            GestureDetector(
              onTap: onRoleTap,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFF18181B),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: GlassTheme.border),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.shield_outlined, size: 13, color: GlassTheme.accentEmerald),
                    const SizedBox(width: 4),
                    Text(
                      role,
                      style: GoogleFonts.roboto(fontSize: 11.5, fontWeight: FontWeight.w700, color: GlassTheme.accentEmerald),
                    ),
                    const SizedBox(width: 2),
                    const Icon(Icons.keyboard_arrow_down_rounded, size: 14, color: GlassTheme.chrome),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),

            // User Avatar
            GestureDetector(
              onTap: onProfileTap,
              child: CircleAvatar(
                radius: 16,
                backgroundColor: const Color(0xFF27272A),
                backgroundImage: (photoUrl != null && photoUrl!.isNotEmpty) ? NetworkImage(photoUrl!) : null,
                child: (photoUrl != null && photoUrl!.isNotEmpty)
                    ? null
                    : (avatarText != null && avatarText!.isNotEmpty)
                        ? Text(avatarText!, style: GoogleFonts.roboto(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white))
                        : const Icon(Icons.person_rounded, size: 17, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Floating Minimal Bottom Navigation Dock
class FloatingGlassDock extends StatelessWidget {
  final int currentIndex;
  final List<DockItem> items;
  final Function(int) onSelect;

  const FloatingGlassDock({
    super.key,
    required this.currentIndex,
    required this.items,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        height: 60,
        decoration: BoxDecoration(
          color: const Color(0xFF141418),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: GlassTheme.border, width: 1.0),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(items.length, (index) {
            final item = items[index];
            final isSelected = currentIndex == index;

            return GestureDetector(
              onTap: () => onSelect(index),
              behavior: HitTestBehavior.opaque,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? GlassTheme.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isSelected ? item.selectedIcon : item.icon,
                      color: isSelected ? Colors.black : GlassTheme.mutedSilver,
                      size: 18,
                    ),
                    if (isSelected) ...[
                      const SizedBox(width: 6),
                      Text(
                        item.label,
                        style: GoogleFonts.roboto(
                          color: Colors.black,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class DockItem {
  final IconData icon;
  final IconData selectedIcon;
  final String label;

  const DockItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });
}
