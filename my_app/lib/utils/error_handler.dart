import 'package:flutter/foundation.dart';

/// A user-facing error that can be safely displayed without leaking
/// technical stack traces.
class AppException implements Exception {
  final String message;
  final String? technicalDetails;

  const AppException(this.message, {this.technicalDetails});

  @override
  String toString() => message;
}

/// Error handler helpers. Logs technical details only in debug mode and
/// returns a friendly message for the user.
class ErrorHandler {
  const ErrorHandler._();

  static String messageOf(Object error, {String fallback = 'Something went wrong.'}) {
    if (error is AppException) return error.message;
    if (error is Exception) return fallback;
    return fallback;
  }

  static void log(Object error, [String? context]) {
    if (kDebugMode) {
      // ignore: avoid_print
      debugPrint('[${context ?? 'SkinAI'}] $error');
    }
  }
}
