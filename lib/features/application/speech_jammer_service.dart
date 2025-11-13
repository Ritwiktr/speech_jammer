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
  static const platform = MethodChannel('com.example.speech_jammer/audio');
  
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
      final hasMicPermission = await PermissionHelper.requestMicrophonePermission();
      print('🎤 Microphone permission: $hasMicPermission');
      return hasMicPermission;
    } catch (e) {
      print('❌ Error initializing: $e');
      return false;
    }
  }

  Future<bool> checkHeadphones() async {
    return await AudioHelper.checkHeadphonesConnected();
  }

  Future<void> start(int delayMs) async {
    if (_isActive) return;

    _currentDelayMs = delayMs;

    try {
      print('🎯 Starting native speech jammer with ${delayMs}ms delay...');
      
      // Call native iOS code for real-time audio processing
      final result = await platform.invokeMethod('start', {
        'delayMs': delayMs,
      });
      
      if (result == true) {
        _isActive = true;
        print('✅ Native speech jammer started successfully!');
      } else {
        throw Exception('Failed to start native audio engine');
      }
    } on PlatformException catch (e) {
      print('❌ Platform error: ${e.message}');
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
      final hasPermission = await PermissionHelper.requestStoragePermission();
      if (!hasPermission) {
        throw Exception('Storage permission not granted');
      }

      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      _recordingPath = '${directory.path}/${AppConstants.recordingPrefix}$timestamp${AppConstants.recordingExtension}';

      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          sampleRate: AppConstants.sampleRate,
        ),
        path: _recordingPath!,
      );

      return _recordingPath;
    } catch (e) {
      _recordingPath = null;
      return null;
    }
  }

  Future<void> stopRecording() async {
    await _recorder.stop();
  }

  Future<List<String>> getSavedRecordings() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final files = directory.listSync();
      
      return files
          .where((file) => 
              file is File && 
              file.path.contains(AppConstants.recordingPrefix))
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

