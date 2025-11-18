import 'package:audio_session/audio_session.dart';

class AudioHelper {
  static Future<bool> checkHeadphonesConnected() async {
    try {
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.speech());

      // Note: Actual headphone detection varies by platform
      // This is a simplified check
      return true; // In production, implement platform-specific checks
    } catch (e) {
      return false;
    }
  }

  static Future<void> configureAudioSession() async {
    try {
      print('🔊 Configuring audio session...');
      final session = await AudioSession.instance;
      print('🔊 Got audio session instance');

      await session.configure(const AudioSessionConfiguration.speech());
      print('🔊 Audio session configured');
    } catch (e) {
      print('❌ Error configuring audio session: $e');
      // Don't rethrow - let the app continue even if audio config fails
    }
  }
}
