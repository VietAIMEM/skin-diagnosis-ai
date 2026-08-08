import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Renders a progress bar style text block for terminal-like output.
extension NumX on num {
  /// Formats [this] as a percentage string with [digits] decimal places.
  String asPercent([int digits = 1]) {
    return (this * 100).toStringAsFixed(digits);
  }
}

/// Formats a timestamp as a short clock time.
String timeOf(DateTime value) => DateFormat.Hm().format(value.toLocal());

extension StringX on String {
  /// Returns a masked representation of an API key. Only the last 4
  /// characters are visible.
  String maskedKey() {
    if (length <= 8) return '••••••••';
    return '••••••••${substring(length - 4)}';
  }
}

extension BuildContextX on BuildContext {
  /// Convenience accessor for Theme.
  ThemeData get theme => Theme.of(this);

  /// Convenience accessor for MediaQuery size.
  Size get screenSize => MediaQuery.sizeOf(this);

  /// Hides the on-screen keyboard.
  void hideKeyboard() {
    FocusScope.of(this).unfocus();
  }
}
