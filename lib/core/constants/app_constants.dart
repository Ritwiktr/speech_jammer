class AppConstants {
  // Audio Constants
  static const int sampleRate = 44100;
  static const int minDelayMs = 50; // Minimum 50ms to avoid buffer issues
  static const int maxDelayMs = 500;
  static const int defaultDelayMs = 200;

  // Recording Constants
  static const String recordingExtension = '.m4a';
  static const String recordingPrefix = 'speech_jammer_';

  // UI Constants
  static const double buttonSize = 80.0;
  static const double iconSize = 40.0;
  static const double padding = 16.0;

  // Messages
  static const String headphoneWarningTitle = 'Headphones Required';
  static const String headphoneWarningMessage =
      'Please connect headphones to use this app. The speech jamming effect requires headphones to work properly.';
  static const String permissionDeniedTitle = 'Permission Denied';
  static const String permissionDeniedMessage =
      'Microphone permission is required for this app to function.';
}
