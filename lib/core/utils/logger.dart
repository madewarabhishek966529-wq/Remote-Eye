import 'package:flutter/foundation.dart';

class AppLogger {
  static void d(String tag, String message) {
    if (kDebugMode) {
      debugPrint('🔵 [$tag] $message');
    }
  }

  static void i(String tag, String message) {
    if (kDebugMode) {
      debugPrint('🟢 [$tag] $message');
    }
  }

  static void w(String tag, String message) {
    if (kDebugMode) {
      debugPrint('🟠 [$tag] $message');
    }
  }

  static void e(String tag, String message, [dynamic error, StackTrace? stackTrace]) {
    if (kDebugMode) {
      debugPrint('🔴 [$tag] $message');
      if (error != null) debugPrint('    Error: $error');
      if (stackTrace != null) debugPrint('    StackTrace: $stackTrace');
    }
  }
}
