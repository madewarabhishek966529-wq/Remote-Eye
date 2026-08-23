class AppConstants {
  static const String appName = 'RemoteEye';
  static const String appTagline = 'Real-time P2P Screen Mirroring & Control';

  // Firebase Realtime Database Paths
  static const String sessionsPath = 'sessions';

  // Data Channel Label
  static const String dataChannelLabel = 'remote_control';

  // Touch Gesture Types
  static const String gestureTap = 'tap';
  static const String gestureDoubleTap = 'double_tap';
  static const String gestureLongPress = 'long_press';
  static const String gestureSwipe = 'swipe';
  static const String gestureGlobal = 'global';

  // Shared Preferences Keys
  static const String keyAllowRemoteControl = 'pref_allow_remote_control';
  static const String keyTurnUrl = 'pref_turn_url';
  static const String keyTurnUsername = 'pref_turn_username';
  static const String keyTurnCredential = 'pref_turn_credential';
}
