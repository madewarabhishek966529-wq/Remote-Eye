import 'dart:math';

class CodeGenerator {
  /// Generates a secure, readable 6-digit numeric pairing code
  static String generateSessionCode() {
    final random = Random.secure();
    final code = random.nextInt(900000) + 100000; // Ensures 6 digits (100000 to 999999)
    return code.toString();
  }

  /// Format 6-digit code for display with a space in middle (e.g., "839 102")
  static String formatCode(String code) {
    if (code.length != 6) return code;
    return '${code.substring(0, 3)} ${code.substring(3)}';
  }
}
