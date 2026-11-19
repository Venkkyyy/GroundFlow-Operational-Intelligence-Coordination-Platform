import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// String extensions
// ---------------------------------------------------------------------------

extension StringExtensions on String {
  /// Returns up to 2 uppercase initials extracted from the string, treating
  /// whitespace runs as word boundaries.
  ///
  /// `'Alice Johnson'` → `'AJ'`, `'Bob'` → `'BO'`, `''` → `'?'`
  String toInitials() {
    final trimmed = trim();
    if (trimmed.isEmpty) return '?';
    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length == 1) {
      return trimmed.substring(0, trimmed.length.clamp(1, 2)).toUpperCase();
    }
    return '${parts.first[0]}${parts[1][0]}'.toUpperCase();
  }

  /// Returns the string with its first character upper-cased and the rest
  /// unchanged.
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }

  /// Truncates to [maxLength] characters, appending [ellipsis] when cut.
  String truncate(int maxLength, {String ellipsis = '…'}) {
    if (length <= maxLength) return this;
    return '${substring(0, maxLength)}$ellipsis';
  }

  /// Returns `true` when this string is neither empty nor blank (whitespace only).
  bool get isNotBlank => trim().isNotEmpty;

  /// Returns `true` when this string is empty or contains only whitespace.
  bool get isBlank => trim().isEmpty;
}

// ---------------------------------------------------------------------------
// DateTime extensions
// ---------------------------------------------------------------------------

extension DateTimeExtensions on DateTime {
  /// Returns a human-friendly relative string such as "just now", "3 min ago",
  /// "2 hours ago", "yesterday", or "16 Nov" for older dates.
  String toTimeAgo() {
    final now = DateTime.now();
    final diff = now.difference(this);

    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) {
      final m = diff.inMinutes;
      return '$m min ago';
    }
    if (diff.inHours < 24 && isToday) {
      final h = diff.inHours;
      return '$h ${h == 1 ? 'hour' : 'hours'} ago';
    }
    if (isTomorrow) return 'tomorrow';
    if (isYesterday) return 'yesterday';

    // Older dates — show day and abbreviated month.
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '$day ${months[month - 1]}';
  }

  /// Formats the date as `"Mon, 16 Nov 2026"`.
  String toFormattedDate() {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${days[weekday - 1]}, $day ${months[month - 1]} $year';
  }

  /// Formats only the time as `"HH:MM"` (24-hour) or `"h:MM AM/PM"` when
  /// [use24Hour] is false.
  String toFormattedTime({bool use24Hour = true}) {
    final h = hour.toString().padLeft(2, '0');
    final m = minute.toString().padLeft(2, '0');
    if (use24Hour) return '$h:$m';

    final period = hour < 12 ? 'AM' : 'PM';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '$displayHour:$m $period';
  }

  /// `true` when this [DateTime] falls on today's calendar date (local time).
  bool get isToday {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }

  /// `true` when this [DateTime] falls on tomorrow's calendar date.
  bool get isTomorrow {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return year == tomorrow.year && month == tomorrow.month && day == tomorrow.day;
  }

  /// `true` when this [DateTime] fell on yesterday's calendar date.
  bool get isYesterday {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return year == yesterday.year && month == yesterday.month && day == yesterday.day;
  }

  /// Returns the date portion only (time zeroed out).
  DateTime get dateOnly => DateTime(year, month, day);

  /// Returns this [DateTime] rounded down to the start of the hour.
  DateTime get startOfHour => DateTime(year, month, day, hour);
}

// ---------------------------------------------------------------------------
// Color extensions
// ---------------------------------------------------------------------------

extension ColorExtensions on Color {
  /// Returns a copy with [opacity] in the range 0.0–1.0.
  /// Identical to [withOpacity] but named to match the GroundFlow convention.
  Color withOpacityValue(double opacity) => withOpacity(opacity.clamp(0.0, 1.0));

  /// Returns a "soft" version of the color: 12 % opacity on the same hue,
  /// suitable for chip backgrounds and status badges.
  Color toSoftBackground() => withOpacity(0.12);

  /// Lightens the color by mixing with white at the given [amount] (0–1).
  Color lighten([double amount = 0.2]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(this);
    return hsl
        .withLightness((hsl.lightness + amount).clamp(0.0, 1.0))
        .toColor();
  }

  /// Darkens the color by reducing lightness by [amount] (0–1).
  Color darken([double amount = 0.2]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(this);
    return hsl
        .withLightness((hsl.lightness - amount).clamp(0.0, 1.0))
        .toColor();
  }

  /// Returns `Colors.white` or `Colors.black87` depending on which offers
  /// better readability on this background color.
  Color get onColor =>
      computeLuminance() > 0.35 ? Colors.black87 : Colors.white;

  /// Maps common GroundFlow status names to their corresponding colors. Use
  /// [AppColors] from `app_colors.dart` for the actual constants; this helper
  /// is for inline computation.
  static Color forStatus(String status) {
    switch (status.toLowerCase().replaceAll(' ', '_').replaceAll('-', '_')) {
      case 'present':
        return const Color(0xFF00C853); // green
      case 'on_shoot':
        return const Color(0xFF2979FF); // blue
      case 'on_break':
        return const Color(0xFFFFB300); // amber
      case 'needs_help':
        return const Color(0xFFD32F2F); // red
      case 'not_arrived':
      case 'missed_check_in':
        return const Color(0xFF9E9E9E); // grey
      default:
        return const Color(0xFF9E9E9E);
    }
  }
}

// ---------------------------------------------------------------------------
// List extensions (bonus utility)
// ---------------------------------------------------------------------------

extension ListExtensions<T> on List<T> {
  /// Returns the element at [index], or [fallback] if out of bounds.
  T? safeGet(int index) {
    if (index < 0 || index >= length) return null;
    return this[index];
  }

  /// Splits this list into chunks of at most [size] elements.
  List<List<T>> chunked(int size) {
    assert(size > 0);
    final chunks = <List<T>>[];
    for (var i = 0; i < length; i += size) {
      chunks.add(sublist(i, (i + size).clamp(0, length)));
    }
    return chunks;
  }
}
