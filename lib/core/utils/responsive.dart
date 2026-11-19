import 'package:flutter/material.dart';

/// Breakpoint constants used throughout GroundFlow.
///
/// | Range        | Class   |
/// |-------------|---------|
/// | < 600 px    | Mobile  |
/// | 600–1023 px | Tablet  |
/// | ≥ 1024 px   | Desktop |
class Responsive {
  const Responsive._();

  static const double _mobileBreakpoint = 600;
  static const double _desktopBreakpoint = 1024;

  // -------------------------------------------------------------------------
  // Type checks
  // -------------------------------------------------------------------------

  static bool isMobile(BuildContext ctx) =>
      MediaQuery.of(ctx).size.width < _mobileBreakpoint;

  static bool isTablet(BuildContext ctx) {
    final w = MediaQuery.of(ctx).size.width;
    return w >= _mobileBreakpoint && w < _desktopBreakpoint;
  }

  static bool isDesktop(BuildContext ctx) =>
      MediaQuery.of(ctx).size.width >= _desktopBreakpoint;

  // -------------------------------------------------------------------------
  // Adaptive value selector
  // -------------------------------------------------------------------------

  /// Returns the value appropriate for the current screen width.
  ///
  /// [tablet] is optional; when omitted, mobile and desktop values are used for
  /// their respective breakpoints and the tablet breakpoint falls through to
  /// [mobile].
  ///
  /// ```dart
  /// final columns = Responsive.adaptive(
  ///   context,
  ///   mobile: 1,
  ///   tablet: 2,
  ///   desktop: 3,
  /// );
  /// ```
  static T adaptive<T>(
    BuildContext ctx, {
    required T mobile,
    T? tablet,
    required T desktop,
  }) {
    if (isDesktop(ctx)) return desktop;
    if (isTablet(ctx)) return tablet ?? mobile;
    return mobile;
  }

  // -------------------------------------------------------------------------
  // Grid helpers
  // -------------------------------------------------------------------------

  /// Suggested number of grid columns for the current screen size.
  static int gridColumns(BuildContext ctx, {int mobile = 1, int tablet = 2, int desktop = 3}) =>
      adaptive(ctx, mobile: mobile, tablet: tablet, desktop: desktop);

  /// Suggested horizontal content padding for the current screen size.
  static double horizontalPadding(BuildContext ctx) =>
      adaptive(ctx, mobile: 16, tablet: 24, desktop: 32);

  // -------------------------------------------------------------------------
  // Widget helper
  // -------------------------------------------------------------------------

  /// Builds a widget tree adaptive to the current screen size.
  ///
  /// Exactly the same as [adaptive] but for [Widget]s. [tablet] defaults to
  /// [mobile] when omitted.
  static Widget build(
    BuildContext ctx, {
    required Widget mobile,
    Widget? tablet,
    required Widget desktop,
  }) =>
      adaptive(ctx, mobile: mobile, tablet: tablet, desktop: desktop);
}

/// Convenience extension on [BuildContext] for inline responsive checks.
extension ResponsiveContext on BuildContext {
  bool get isMobile => Responsive.isMobile(this);
  bool get isTablet => Responsive.isTablet(this);
  bool get isDesktop => Responsive.isDesktop(this);

  T adaptive<T>({required T mobile, T? tablet, required T desktop}) =>
      Responsive.adaptive(this, mobile: mobile, tablet: tablet, desktop: desktop);
}
