import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:just_audio/just_audio.dart';
import '../../core/utils/audio_helper.dart';
import '../../core/utils/permission_helper.dart';
import '../../core/constants/app_constants.dart';

class SpeechJammerService {
  // Platform channel for native audio processing
  static const platform = MethodChannel('com.app.speechjammer/audio');

  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _player = AudioPlayer();

  bool _isActive = false;
  int _currentDelayMs = AppConstants.defaultDelayMs;
  String? _recordingPath;
  Timer? _delayTimer;

  bool get isActive => _isActive;
  int get currentDelay => _currentDelayMs;
  String? get recordingPath => _recordingPath;

  Future<bool> initialize() async {
    try {
      await AudioHelper.configureAudioSession();

      // Try record package's permission first (often triggers system dialog better)
      final recorderHasPermission = await _recorder.hasPermission();
      print('🎤 Recorder permission check: $recorderHasPermission');

      if (!recorderHasPermission) {
        // Try permission_handler as fallback
        final permissionGranted =
            await PermissionHelper.requestMicrophonePermission();
        print('🎤 Permission handler result: $permissionGranted');

        if (!permissionGranted) {
          final isPermanentlyDenied =
              await PermissionHelper.isMicrophonePermissionPermanentlyDenied();
          if (isPermanentlyDenied) {
            throw Exception(
                'Microphone permission was denied. Please enable it in Settings > Privacy & Security > Microphone.');
          } else {
            throw Exception(
                'Microphone permission is required to use this app.');
          }
        }
      }

      print('✅ Microphone permission granted');
      return true;
    } catch (e) {
      print('❌ Error initializing: $e');
      rethrow;
    }
  }

  Future<bool> checkHeadphones() async {
    return await AudioHelper.checkHeadphonesConnected();
  }

  Future<void> start(int delayMs) async {
    if (_isActive) return;

    _currentDelayMs = delayMs;

    try {
      print('🎯 Starting speech jammer with ${delayMs}ms delay...');

      // Try native implementation first (iOS has real implementation)
      final result = await platform.invokeMethod('start', {
        'delayMs': delayMs,
      });

      if (result == true) {
        _isActive = true;
        print('✅ Speech jammer started!');
      } else {
        throw Exception('Failed to start audio engine');
      }
    } on PlatformException catch (e) {
      print('⚠️ Platform implementation not available: ${e.message}');
      print('📱 Note: Full native audio on Android coming soon!');
      _isActive = false;
      rethrow;
    } catch (e) {
      print('❌ Error starting speech jammer: $e');
      _isActive = false;
      rethrow;
    }
  }

  Future<void> stop() async {
    if (!_isActive) return;

    try {
      print('⏹️ Stopping native speech jammer...');

      // Call native iOS code to stop
      final result = await platform.invokeMethod('stop');

      if (result == true) {
        _isActive = false;
        print('✅ Native speech jammer stopped');
      }
    } on PlatformException catch (e) {
      print('❌ Platform error stopping: ${e.message}');
    } catch (e) {
      print('❌ Error stopping: $e');
    }
  }

  Future<void> updateDelay(int delayMs) async {
    _currentDelayMs = delayMs;

    if (_isActive) {
      try {
        print('🔄 Updating delay to ${delayMs}ms...');

        // Call native code to update delay
        await platform.invokeMethod('updateDelay', {
          'delayMs': delayMs,
        });

        print('✅ Delay updated');
      } on PlatformException catch (e) {
        print('❌ Platform error updating delay: ${e.message}');
      } catch (e) {
        print('❌ Error updating delay: $e');
      }
    }
  }

  Future<String?> startRecording() async {
    try {
      print('🎙️ Starting recording...');
      
      if (!_isActive) {
        throw Exception('Jammer must be active to record');
      }
      
      final hasPermission = await PermissionHelper.requestStoragePermission();
      print('📁 Storage permission granted: $hasPermission');
      
      if (!hasPermission) {
        throw Exception('Storage permission not granted');
      }

      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      
      // Use .wav extension for Android native recording, .m4a for iOS
      final extension = Platform.isAndroid ? '.wav' : AppConstants.recordingExtension;
      _recordingPath = '${directory.path}/${AppConstants.recordingPrefix}$timestamp$extension';

      print('💾 Recording to: $_recordingPath');

      if (Platform.isAndroid) {
        // Use native recording on Android to avoid AudioRecord conflict
        print('🤖 Using native Android recording');
        final result = await platform.invokeMethod('startRecording', {
          'filePath': _recordingPath,
        });
        
        if (result != true) {
          throw Exception('Native recording failed to start');
        }
      } else {
        // Use record package on iOS and other platforms
        print('🍎 Using record package');
        await _recorder.start(
          const RecordConfig(
            encoder: AudioEncoder.aacLc,
            sampleRate: AppConstants.sampleRate,
          ),
          path: _recordingPath!,
        );
      }

      print('✅ Recording started successfully');
      return _recordingPath;
    } catch (e) {
      print('❌ Error starting recording: $e');
      _recordingPath = null;
      rethrow; // Rethrow to let the bloc handle the error
    }
  }

  Future<void> stopRecording() async {
    try {
      print('🛑 Stopping recording...');
      
      if (Platform.isAndroid) {
        // Use native recording on Android
        print('🤖 Stopping native Android recording');
        final path = await platform.invokeMethod('stopRecording');
        print('✅ Recording stopped. Saved at: $path');
      } else {
        // Use record package on iOS and other platforms
        print('🍎 Stopping record package recording');
        final path = await _recorder.stop();
        print('✅ Recording stopped. Saved at: $path');
      }
    } catch (e) {
      print('❌ Error stopping recording: $e');
      rethrow;
    }
  }

  Future<List<String>> getSavedRecordings() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final files = directory.listSync();

      return files
          .where((file) =>
              file is File && 
              file.path.contains(AppConstants.recordingPrefix) &&
              (file.path.endsWith('.wav') || file.path.endsWith('.m4a')))
          .map((file) => file.path)
          .toList();
    } catch (e) {
      return [];
    }
  }

  void dispose() {
    _recorder.dispose();
    _player.dispose();
    _delayTimer?.cancel();
  }
}
