import 'package:flutter/services.dart';
import '../../../core/utils/logger.dart';

class AccessibilityNativeService {
  static const String _tag = 'AccessibilityNative';
  static const MethodChannel _channel = MethodChannel('com.example.remote_eye/accessibility');

  /// Checks whether RemoteEye's Accessibility Service is currently granted and active
  Future<bool> isAccessibilityGranted() async {
    try {
      final bool isGranted = await _channel.invokeMethod('isAccessibilityGranted');
      return isGranted;
    } catch (e) {
      AppLogger.e(_tag, 'Error checking accessibility status', e);
      return false;
    }
  }

  /// Opens Android Accessibility Settings page so user can enable RemoteEye Gesture Controller
  Future<bool> openAccessibilitySettings() async {
    try {
      final bool result = await _channel.invokeMethod('openAccessibilitySettings');
      return result;
    } catch (e) {
      AppLogger.e(_tag, 'Error opening accessibility settings', e);
      return false;
    }
  }

  /// Injects single tap at normalized coordinates (0.0 to 1.0)
  Future<bool> injectTap(double xPercent, double yPercent) async {
    try {
      final bool success = await _channel.invokeMethod('injectTap', {
        'x': xPercent,
        'y': yPercent,
      });
      return success;
    } catch (e) {
      AppLogger.e(_tag, 'Failed to inject tap at ($xPercent, $yPercent)', e);
      return false;
    }
  }

  /// Injects double tap at normalized coordinates
  Future<bool> injectDoubleTap(double xPercent, double yPercent) async {
    try {
      final bool success = await _channel.invokeMethod('injectDoubleTap', {
        'x': xPercent,
        'y': yPercent,
      });
      return success;
    } catch (e) {
      AppLogger.e(_tag, 'Failed to inject double tap', e);
      return false;
    }
  }

  /// Injects long press at normalized coordinates
  Future<bool> injectLongPress(double xPercent, double yPercent) async {
    try {
      final bool success = await _channel.invokeMethod('injectLongPress', {
        'x': xPercent,
        'y': yPercent,
      });
      return success;
    } catch (e) {
      AppLogger.e(_tag, 'Failed to inject long press', e);
      return false;
    }
  }

  /// Injects swipe gesture from start to end normalized coordinates
  Future<bool> injectSwipe({
    required double startXPercent,
    required double startYPercent,
    required double endXPercent,
    required double endYPercent,
    int durationMs = 300,
  }) async {
    try {
      final bool success = await _channel.invokeMethod('injectSwipe', {
        'startX': startXPercent,
        'startY': startYPercent,
        'endX': endXPercent,
        'endY': endYPercent,
        'durationMs': durationMs,
      });
      return success;
    } catch (e) {
      AppLogger.e(_tag, 'Failed to inject swipe', e);
      return false;
    }
  }

  /// Triggers Android global system action ('back', 'home', 'recents')
  Future<bool> triggerGlobalAction(String action) async {
    try {
      final bool success = await _channel.invokeMethod('triggerGlobalAction', {
        'action': action,
      });
      return success;
    } catch (e) {
      AppLogger.e(_tag, 'Failed to trigger global action: $action', e);
      return false;
    }
  }
}
