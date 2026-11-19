// lib/core/theme/app_theme.dart
// GroundFlow Material 3 theme definition — light & dark.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

// ──────────────────────────────────────────────────────────────────────────────
// Spacing constants
// ──────────────────────────────────────────────────────────────────────────────

abstract class AppSpacing {
  static const double xs  =  4.0;
  static const double sm  =  8.0;
  static const double md  = 12.0;
  static const double lg  = 16.0;
  static const double xl  = 20.0;
  static const double xxl = 24.0;
  static const double x3l = 32.0;
  static const double x4l = 48.0;

  // Border radii
  static const double radiusSm   =  8.0;
  static const double radiusMd   = 12.0;
  static const double radiusLg   = 16.0;
  static const double radiusXl   = 24.0;
  static const double radiusFull = 999.0;

  // Card elevation
  static const double elevationNone = 0;
  static const double elevationSm   = 1;
  static const double elevationMd   = 3;
  static const double elevationLg   = 6;
}

// ──────────────────────────────────────────────────────────────────────────────
// Custom color theme extension
// ──────────────────────────────────────────────────────────────────────────────

/// Extends ThemeData with GroundFlow-specific semantic colors.
class AppColorExtension extends ThemeExtension<AppColorExtension> {
  final Color success;
  final Color successLight;
  final Color warning;
  final Color warningLight;
  final Color danger;
  final Color dangerLight;
  final Color info;
  final Color infoLight;

  // Member status colors
  final Color statusPresent;
  final Color statusOnShoot;
  final Color statusBreak;
  final Color statusNeedsHelp;
  final Color statusNotArrived;
  final Color statusMissed;

  // Gear status colors
  final Color gearAvailable;
  final Color gearCheckedOut;
  final Color gearOverdue;
  final Color gearMissing;
  final Color gearDamaged;
  final Color gearCharging;

  // Surface variants
  final Color cardBg;
  final Color border;
  final Color divider;
  final Color textPrimary;
  final Color textSecondary;
  final Color textHint;

  const AppColorExtension({
    required this.success,
    required this.successLight,
    required this.warning,
    required this.warningLight,
    required this.danger,
    required this.dangerLight,
    required this.info,
    required this.infoLight,
    required this.statusPresent,
    required this.statusOnShoot,
    required this.statusBreak,
    required this.statusNeedsHelp,
    required this.statusNotArrived,
    required this.statusMissed,
    required this.gearAvailable,
    required this.gearCheckedOut,
    required this.gearOverdue,
    required this.gearMissing,
    required this.gearDamaged,
    required this.gearCharging,
    required this.cardBg,
    required this.border,
    required this.divider,
    required this.textPrimary,
    required this.textSecondary,
    required this.textHint,
  });

  @override
  AppColorExtension copyWith({
    Color? success, Color? successLight,
    Color? warning, Color? warningLight,
    Color? danger,  Color? dangerLight,
    Color? info,    Color? infoLight,
    Color? statusPresent, Color? statusOnShoot,
    Color? statusBreak,   Color? statusNeedsHelp,
    Color? statusNotArrived, Color? statusMissed,
    Color? gearAvailable, Color? gearCheckedOut,
    Color? gearOverdue,   Color? gearMissing,
    Color? gearDamaged,   Color? gearCharging,
    Color? cardBg,  Color? border,
    Color? divider, Color? textPrimary,
    Color? textSecondary, Color? textHint,
  }) {
    return AppColorExtension(
      success:           success           ?? this.success,
      successLight:      successLight      ?? this.successLight,
      warning:           warning           ?? this.warning,
      warningLight:      warningLight      ?? this.warningLight,
      danger:            danger            ?? this.danger,
      dangerLight:       dangerLight       ?? this.dangerLight,
      info:              info              ?? this.info,
      infoLight:         infoLight         ?? this.infoLight,
      statusPresent:     statusPresent     ?? this.statusPresent,
      statusOnShoot:     statusOnShoot     ?? this.statusOnShoot,
      statusBreak:       statusBreak       ?? this.statusBreak,
      statusNeedsHelp:   statusNeedsHelp   ?? this.statusNeedsHelp,
      statusNotArrived:  statusNotArrived  ?? this.statusNotArrived,
      statusMissed:      statusMissed      ?? this.statusMissed,
      gearAvailable:     gearAvailable     ?? this.gearAvailable,
      gearCheckedOut:    gearCheckedOut    ?? this.gearCheckedOut,
      gearOverdue:       gearOverdue       ?? this.gearOverdue,
      gearMissing:       gearMissing       ?? this.gearMissing,
      gearDamaged:       gearDamaged       ?? this.gearDamaged,
      gearCharging:      gearCharging      ?? this.gearCharging,
      cardBg:            cardBg            ?? this.cardBg,
      border:            border            ?? this.border,
      divider:           divider           ?? this.divider,
      textPrimary:       textPrimary       ?? this.textPrimary,
      textSecondary:     textSecondary     ?? this.textSecondary,
      textHint:          textHint          ?? this.textHint,
    );
  }

  @override
  AppColorExtension lerp(AppColorExtension? other, double t) {
    if (other is! AppColorExtension) return this;
    return AppColorExtension(
      success:          Color.lerp(success,          other.success,          t)!,
      successLight:     Color.lerp(successLight,     other.successLight,     t)!,
      warning:          Color.lerp(warning,          other.warning,          t)!,
      warningLight:     Color.lerp(warningLight,     other.warningLight,     t)!,
      danger:           Color.lerp(danger,           other.danger,           t)!,
      dangerLight:      Color.lerp(dangerLight,      other.dangerLight,      t)!,
      info:             Color.lerp(info,             other.info,             t)!,
      infoLight:        Color.lerp(infoLight,        other.infoLight,        t)!,
      statusPresent:    Color.lerp(statusPresent,    other.statusPresent,    t)!,
      statusOnShoot:    Color.lerp(statusOnShoot,    other.statusOnShoot,    t)!,
      statusBreak:      Color.lerp(statusBreak,      other.statusBreak,      t)!,
      statusNeedsHelp:  Color.lerp(statusNeedsHelp,  other.statusNeedsHelp,  t)!,
      statusNotArrived: Color.lerp(statusNotArrived, other.statusNotArrived, t)!,
      statusMissed:     Color.lerp(statusMissed,     other.statusMissed,     t)!,
      gearAvailable:    Color.lerp(gearAvailable,    other.gearAvailable,    t)!,
      gearCheckedOut:   Color.lerp(gearCheckedOut,   other.gearCheckedOut,   t)!,
      gearOverdue:      Color.lerp(gearOverdue,      other.gearOverdue,      t)!,
      gearMissing:      Color.lerp(gearMissing,      other.gearMissing,      t)!,
      gearDamaged:      Color.lerp(gearDamaged,      other.gearDamaged,      t)!,
      gearCharging:     Color.lerp(gearCharging,     other.gearCharging,     t)!,
      cardBg:           Color.lerp(cardBg,           other.cardBg,           t)!,
      border:           Color.lerp(border,           other.border,           t)!,
      divider:          Color.lerp(divider,          other.divider,          t)!,
      textPrimary:      Color.lerp(textPrimary,      other.textPrimary,      t)!,
      textSecondary:    Color.lerp(textSecondary,    other.textSecondary,    t)!,
      textHint:         Color.lerp(textHint,         other.textHint,         t)!,
    );
  }

  static const light = AppColorExtension(
    success:           kSuccess,      successLight:     kSuccessLight,
    warning:           kWarning,      warningLight:     kWarningLight,
    danger:            kDanger,       dangerLight:      kDangerLight,
    info:              kInfo,         infoLight:        kInfoLight,
    statusPresent:     kStatusPresent,
    statusOnShoot:     kStatusOnShoot,
    statusBreak:       kStatusBreak,
    statusNeedsHelp:   kStatusNeedsHelp,
    statusNotArrived:  kStatusNotArrived,
    statusMissed:      kStatusMissed,
    gearAvailable:     kGearAvailable,
    gearCheckedOut:    kGearCheckedOut,
    gearOverdue:       kGearOverdue,
    gearMissing:       kGearMissing,
    gearDamaged:       kGearDamaged,
    gearCharging:      kGearCharging,
    cardBg:            kCardBg,
    border:            kBorder,
    divider:           kDivider,
    textPrimary:       kTextPrimary,
    textSecondary:     kTextSecondary,
    textHint:          kTextHint,
  );

  static const dark = AppColorExtension(
    success:           kSuccessLight,  successLight:    kSuccess,
    warning:           kWarningLight,  warningLight:    kWarning,
    danger:            kDangerLight,   dangerLight:     kDanger,
    info:              kInfoLight,     infoLight:       kInfo,
    statusPresent:     kStatusPresent,
    statusOnShoot:     kStatusOnShoot,
    statusBreak:       kStatusBreak,
    statusNeedsHelp:   kStatusNeedsHelp,
    statusNotArrived:  kStatusNotArrived,
    statusMissed:      kStatusMissed,
    gearAvailable:     kGearAvailable,
    gearCheckedOut:    kGearCheckedOut,
    gearOverdue:       kGearOverdue,
    gearMissing:       kGearMissing,
    gearDamaged:       kGearDamaged,
    gearCharging:      kGearCharging,
    cardBg:            kDarkCard,
    border:            kDarkBorder,
    divider:           kDarkBorder,
    textPrimary:       kDarkTextPrimary,
    textSecondary:     kDarkTextSecondary,
    textHint:          Color(0xFF64748B),
  );
}

// Convenience extension on BuildContext
extension AppThemeContext on BuildContext {
  AppColorExtension get appColors =>
      Theme.of(this).extension<AppColorExtension>()!;
  TextTheme get textTheme => Theme.of(this).textTheme;
}

// ──────────────────────────────────────────────────────────────────────────────
// Text styles (Inter via google_fonts)
// ──────────────────────────────────────────────────────────────────────────────

abstract class AppTextStyles {
  // Display
  static TextStyle displayLarge(Color color) =>
      GoogleFonts.inter(fontSize: 57, fontWeight: FontWeight.w700, color: color, letterSpacing: -0.25);
  static TextStyle displayMedium(Color color) =>
      GoogleFonts.inter(fontSize: 45, fontWeight: FontWeight.w700, color: color);
  static TextStyle displaySmall(Color color) =>
      GoogleFonts.inter(fontSize: 36, fontWeight: FontWeight.w600, color: color);

  // Headline
  static TextStyle headlineLarge(Color color) =>
      GoogleFonts.inter(fontSize: 32, fontWeight: FontWeight.w700, color: color);
  static TextStyle headlineMedium(Color color) =>
      GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w600, color: color);
  static TextStyle headlineSmall(Color color) =>
      GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w600, color: color);

  // Title
  static TextStyle titleLarge(Color color) =>
      GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600, color: color);
  static TextStyle titleMedium(Color color) =>
      GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: color);
  static TextStyle titleSmall(Color color) =>
      GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: color);

  // Body
  static TextStyle bodyLarge(Color color) =>
      GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w400, color: color);
  static TextStyle bodyMedium(Color color) =>
      GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w400, color: color);
  static TextStyle bodySmall(Color color) =>
      GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w400, color: color);

  // Label
  static TextStyle labelLarge(Color color) =>
      GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: color, letterSpacing: 0.1);
  static TextStyle labelMedium(Color color) =>
      GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: color, letterSpacing: 0.5);
  static TextStyle labelSmall(Color color) =>
      GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500, color: color, letterSpacing: 0.5);
}

// ──────────────────────────────────────────────────────────────────────────────
// Theme
// ──────────────────────────────────────────────────────────────────────────────

abstract class AppTheme {
  // ── Color Schemes ──────────────────────────────────────────────────────────

  static ColorScheme get _lightColorScheme => ColorScheme(
    brightness: Brightness.light,
    primary:            kPrimary,
    onPrimary:          Colors.white,
    primaryContainer:   const Color(0xFFDDE1FF),
    onPrimaryContainer: const Color(0xFF001160),
    secondary:          kSecondary,
    onSecondary:        Colors.white,
    secondaryContainer: const Color(0xFFFFECB3),
    onSecondaryContainer: const Color(0xFF3E2800),
    tertiary:           kInfo,
    onTertiary:         Colors.white,
    tertiaryContainer:  const Color(0xFFCDE5FF),
    onTertiaryContainer: const Color(0xFF001D33),
    error:              kDanger,
    onError:            Colors.white,
    errorContainer:     const Color(0xFFFFDAD6),
    onErrorContainer:   const Color(0xFF410002),
    surface:            kSurface,
    onSurface:          kTextPrimary,
    surfaceContainerHighest: const Color(0xFFE3E1EC),
    onSurfaceVariant:   kTextSecondary,
    outline:            kBorder,
    outlineVariant:     kDivider,
    shadow:             Colors.black,
    scrim:              Colors.black,
    inverseSurface:     const Color(0xFF313033),
    onInverseSurface:   const Color(0xFFF4EFF4),
    inversePrimary:     kPrimaryLight,
  );

  static ColorScheme get _darkColorScheme => ColorScheme(
    brightness: Brightness.dark,
    primary:            kPrimaryLight,
    onPrimary:          const Color(0xFF001160),
    primaryContainer:   kPrimaryDark,
    onPrimaryContainer: const Color(0xFFDDE1FF),
    secondary:          kWarningLight,
    onSecondary:        const Color(0xFF3E2800),
    secondaryContainer: const Color(0xFF5A3E00),
    onSecondaryContainer: const Color(0xFFFFECB3),
    tertiary:           kInfoLight,
    onTertiary:         const Color(0xFF001D33),
    tertiaryContainer:  const Color(0xFF004D71),
    onTertiaryContainer: const Color(0xFFCDE5FF),
    error:              kDangerLight,
    onError:            const Color(0xFF690005),
    errorContainer:     const Color(0xFF93000A),
    onErrorContainer:   const Color(0xFFFFDAD6),
    surface:            kDarkSurface,
    onSurface:          kDarkTextPrimary,
    surfaceContainerHighest: const Color(0xFF49454F),
    onSurfaceVariant:   kDarkTextSecondary,
    outline:            kDarkBorder,
    outlineVariant:     const Color(0xFF49454F),
    shadow:             Colors.black,
    scrim:              Colors.black,
    inverseSurface:     const Color(0xFFE6E1E5),
    onInverseSurface:   const Color(0xFF313033),
    inversePrimary:     kPrimary,
  );

  // ── Text Theme (Inter) ─────────────────────────────────────────────────────

  static TextTheme _buildTextTheme(Color baseColor) => GoogleFonts.interTextTheme(
    TextTheme(
      displayLarge:   TextStyle(fontSize: 57, fontWeight: FontWeight.w700, color: baseColor, letterSpacing: -0.25),
      displayMedium:  TextStyle(fontSize: 45, fontWeight: FontWeight.w700, color: baseColor),
      displaySmall:   TextStyle(fontSize: 36, fontWeight: FontWeight.w600, color: baseColor),
      headlineLarge:  TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: baseColor),
      headlineMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: baseColor),
      headlineSmall:  TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: baseColor),
      titleLarge:     TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: baseColor),
      titleMedium:    TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: baseColor),
      titleSmall:     TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: baseColor),
      bodyLarge:      TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: baseColor),
      bodyMedium:     TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: baseColor),
      bodySmall:      TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: baseColor),
      labelLarge:     TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: baseColor, letterSpacing: 0.1),
      labelMedium:    TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: baseColor, letterSpacing: 0.5),
      labelSmall:     TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: baseColor, letterSpacing: 0.5),
    ),
  );

  // ── Shared component themes ────────────────────────────────────────────────

  static CardThemeData _cardTheme(ColorScheme cs) => CardThemeData(
    elevation: AppSpacing.elevationSm,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
    ),
    color: cs.surface,
    shadowColor: Colors.black.withValues(alpha: 0.08),
    surfaceTintColor: Colors.transparent,
    margin: const EdgeInsets.symmetric(
      horizontal: AppSpacing.sm,
      vertical: AppSpacing.xs,
    ),
  );

  static AppBarTheme _appBarTheme(ColorScheme cs) => AppBarTheme(
    backgroundColor: cs.surface,
    foregroundColor: cs.onSurface,
    elevation: 0,
    scrolledUnderElevation: 1,
    centerTitle: false,
    titleTextStyle: GoogleFonts.inter(
      fontSize: 20,
      fontWeight: FontWeight.w700,
      color: cs.onSurface,
    ),
  );

  static ElevatedButtonThemeData _elevatedButtonTheme(ColorScheme cs) =>
      ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: cs.primary,
          foregroundColor: cs.onPrimary,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xxl,
            vertical: AppSpacing.md,
          ),
          textStyle: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      );

  static OutlinedButtonThemeData _outlinedButtonTheme(ColorScheme cs) =>
      OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: cs.primary,
          side: BorderSide(color: cs.primary, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xxl,
            vertical: AppSpacing.md,
          ),
          textStyle: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      );

  static InputDecorationTheme _inputDecorationTheme(ColorScheme cs) =>
      InputDecorationTheme(
        filled: true,
        fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.5),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: BorderSide(color: cs.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: BorderSide(color: cs.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: BorderSide(color: cs.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: BorderSide(color: cs.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: BorderSide(color: cs.error, width: 2),
        ),
        labelStyle: GoogleFonts.inter(fontSize: 14, color: cs.onSurfaceVariant),
        hintStyle: GoogleFonts.inter(fontSize: 14, color: cs.onSurfaceVariant.withValues(alpha: 0.6)),
      );

  static ChipThemeData _chipTheme(ColorScheme cs) => ChipThemeData(
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
    ),
    labelStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500),
    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
  );

  static BottomNavigationBarThemeData _bottomNavTheme(ColorScheme cs) =>
      BottomNavigationBarThemeData(
        backgroundColor: cs.surface,
        selectedItemColor: cs.primary,
        unselectedItemColor: cs.onSurfaceVariant,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600),
        unselectedLabelStyle: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w400),
      );

  static NavigationRailThemeData _navRailTheme(ColorScheme cs) =>
      NavigationRailThemeData(
        backgroundColor: cs.surface,
        selectedIconTheme: IconThemeData(color: cs.primary),
        unselectedIconTheme: IconThemeData(color: cs.onSurfaceVariant),
        selectedLabelTextStyle: GoogleFonts.inter(
          color: cs.primary, fontSize: 12, fontWeight: FontWeight.w600,
        ),
        unselectedLabelTextStyle: GoogleFonts.inter(
          color: cs.onSurfaceVariant, fontSize: 12,
        ),
        indicatorColor: cs.primaryContainer,
      );

  static FloatingActionButtonThemeData _fabTheme(ColorScheme cs) =>
      FloatingActionButtonThemeData(
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
      );

  static SnackBarThemeData _snackBarTheme(ColorScheme cs) => SnackBarThemeData(
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
    ),
  );

  static DividerThemeData _dividerTheme(ColorScheme cs) => DividerThemeData(
    color: cs.outlineVariant,
    thickness: 1,
    space: 1,
  );

  // ── Light Theme ────────────────────────────────────────────────────────────

  static ThemeData get lightTheme {
    final cs = _lightColorScheme;
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: cs,
      scaffoldBackgroundColor: kBackground,
      textTheme: _buildTextTheme(kTextPrimary),
      cardTheme: _cardTheme(cs),
      appBarTheme: _appBarTheme(cs),
      elevatedButtonTheme: _elevatedButtonTheme(cs),
      outlinedButtonTheme: _outlinedButtonTheme(cs),
      inputDecorationTheme: _inputDecorationTheme(cs),
      chipTheme: _chipTheme(cs),
      bottomNavigationBarTheme: _bottomNavTheme(cs),
      navigationRailTheme: _navRailTheme(cs),
      floatingActionButtonTheme: _fabTheme(cs),
      snackBarTheme: _snackBarTheme(cs),
      dividerTheme: _dividerTheme(cs),
      extensions: const [AppColorExtension.light],
    );
  }

  // ── Dark Theme ─────────────────────────────────────────────────────────────

  static ThemeData get darkTheme {
    final cs = _darkColorScheme;
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: cs,
      scaffoldBackgroundColor: kDarkBackground,
      textTheme: _buildTextTheme(kDarkTextPrimary),
      cardTheme: _cardTheme(cs),
      appBarTheme: _appBarTheme(cs),
      elevatedButtonTheme: _elevatedButtonTheme(cs),
      outlinedButtonTheme: _outlinedButtonTheme(cs),
      inputDecorationTheme: _inputDecorationTheme(cs),
      chipTheme: _chipTheme(cs),
      bottomNavigationBarTheme: _bottomNavTheme(cs),
      navigationRailTheme: _navRailTheme(cs),
      floatingActionButtonTheme: _fabTheme(cs),
      snackBarTheme: _snackBarTheme(cs),
      dividerTheme: _dividerTheme(cs),
      extensions: const [AppColorExtension.dark],
    );
  }
}
