import 'package:permission_handler/permission_handler.dart';
import 'dart:io';

class PermissionHelper {
  static Future<bool> requestMicrophonePermission() async {
    try {
      print('📱 Requesting microphone permission...');
      
      // Check current status first
      final currentStatus = await Permission.microphone.status;
      print('📱 Current microphone status: $currentStatus');
      
      if (currentStatus.isGranted) {
        print('✅ Microphone already granted');
        return true;
      }
      
      if (currentStatus.isPermanentlyDenied) {
        print('❌ Microphone permanently denied - opening settings');
        await openAppSettings();
        return false;
      }
      
      // Request permission
      final status = await Permission.microphone.request();
      print('📱 Microphone permission result: $status');
      
      if (status.isGranted) {
        print('✅ Microphone granted');
        return true;
      } else if (status.isDenied) {
        print('⚠️ Microphone denied');
        return false;
      } else if (status.isPermanentlyDenied) {
        print('❌ Microphone permanently denied');
        return false;
      }
      
      return status.isGranted;
    } catch (e) {
      print('❌ Error requesting microphone permission: $e');
      return false;
    }
  }

  static Future<bool> requestStoragePermission() async {
    final status = await Permission.storage.request();
    return status.isGranted || status.isLimited;
  }

  static Future<bool> checkMicrophonePermission() async {
    final status = await Permission.microphone.status;
    return status.isGranted;
  }

  static Future<bool> checkStoragePermission() async {
    final status = await Permission.storage.status;
    return status.isGranted || status.isLimited;
  }
}

