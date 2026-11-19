// lib/core/theme/app_colors.dart
// All GroundFlow brand and semantic color constants.

import 'package:flutter/material.dart';

/// ─────────────────────────── Brand ───────────────────────────
const Color kPrimary      = Color(0xFF3D5AFE); // Deep Indigo
const Color kPrimaryLight = Color(0xFF8187FF); // Lighter indigo tint
const Color kPrimaryDark  = Color(0xFF0031CA); // Darker indigo shade
const Color kSecondary    = Color(0xFFFFB300); // Amber

/// ─────────────────────────── Status ──────────────────────────
const Color kSuccess = Color(0xFF2E7D32); // Deep green
const Color kSuccessLight = Color(0xFF4CAF50);
const Color kWarning = Color(0xFFF57C00); // Deep amber/orange
const Color kWarningLight = Color(0xFFFFB300);
const Color kDanger  = Color(0xFFC62828); // Deep red
const Color kDangerLight  = Color(0xFFEF5350);
const Color kInfo    = Color(0xFF0277BD); // Deep blue
const Color kInfoLight    = Color(0xFF29B6F6);

/// ──────────────── Member / Attendance Status ─────────────────
const Color kStatusPresent    = Color(0xFF43A047); // Green
const Color kStatusOnShoot    = Color(0xFF1E88E5); // Blue
const Color kStatusBreak      = Color(0xFFFFB300); // Amber
const Color kStatusNeedsHelp  = Color(0xFFE53935); // Red
const Color kStatusNotArrived = Color(0xFF9E9E9E); // Gray
const Color kStatusMissed     = Color(0xFFFF7043); // Deep orange

/// ─────────────────────────── Gear ────────────────────────────
const Color kGearAvailable  = Color(0xFF43A047);
const Color kGearCheckedOut = Color(0xFF1E88E5);
const Color kGearOverdue    = Color(0xFFE53935);
const Color kGearMissing    = Color(0xFF880E4F);
const Color kGearDamaged    = Color(0xFFBF360C);
const Color kGearCharging   = Color(0xFF6A1B9A);

/// ─────────────────────────── Neutral (Light) ─────────────────
const Color kSurface        = Color(0xFFFFFFFF);
const Color kBackground     = Color(0xFFF5F5F7); // Very light gray
const Color kCardBg         = Color(0xFFFFFFFF);
const Color kBorder         = Color(0xFFE0E0E0);
const Color kDivider        = Color(0xFFEEEEEE);
const Color kTextPrimary    = Color(0xFF1A1A2E); // Near-black with indigo tint
const Color kTextSecondary  = Color(0xFF6B7280); // Medium gray
const Color kTextHint       = Color(0xFFADB5BD); // Light gray

/// ─────────────────────────── Neutral (Dark) ──────────────────
const Color kDarkSurface    = Color(0xFF1E1E2E); // Dark surface
const Color kDarkBackground = Color(0xFF121220); // Very dark navy
const Color kDarkCard       = Color(0xFF262636); // Dark card
const Color kDarkBorder     = Color(0xFF383850);
const Color kDarkTextPrimary    = Color(0xFFF1F5F9);
const Color kDarkTextSecondary  = Color(0xFF94A3B8);

/// GroundFlow AppColors class wrapper for direct references
abstract class AppColors {
  static const Color primary = kPrimary;
  static const Color primaryLight = kPrimaryLight;
  static const Color primaryDark = kPrimaryDark;
  static const Color secondary = kSecondary;

  static const Color success = kSuccess;
  static const Color successLight = kSuccessLight;
  static const Color warning = kWarning;
  static const Color warningLight = kWarningLight;
  static const Color danger = kDanger;
  static const Color dangerLight = kDangerLight;
  static const Color info = kInfo;
  static const Color infoLight = kInfoLight;

  static const Color statusPresent = kStatusPresent;
  static const Color statusOnShoot = kStatusOnShoot;
  static const Color statusBreak = kStatusBreak;
  static const Color statusNeedsHelp = kStatusNeedsHelp;
  static const Color statusNotArrived = kStatusNotArrived;
  static const Color statusMissed = kStatusMissed;

  static const Color surface = kSurface;
  static const Color background = kBackground;
  static const Color cardBg = kCardBg;
  static const Color border = kBorder;
  static const Color divider = kDivider;
  static const Color textPrimary = kTextPrimary;
  static const Color textSecondary = kTextSecondary;
  static const Color textHint = kTextHint;

  static const Color darkSurface = kDarkSurface;
  static const Color darkBackground = kDarkBackground;
  static const Color darkCard = kDarkCard;
  static const Color darkBorder = kDarkBorder;
  static const Color darkTextPrimary = kDarkTextPrimary;
  static const Color darkTextSecondary = kDarkTextSecondary;

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [kPrimary, kPrimaryDark],
  );
}
