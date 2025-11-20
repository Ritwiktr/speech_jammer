import 'package:permission_handler/permission_handler.dart';

class PermissionHelper {
  static Future<bool> requestMicrophonePermission() async {
    try {
      print('📱 Requesting microphone permission...');
      final result = await Permission.microphone.request();
      print('📱 Permission result: $result');
      return result.isGranted;
    } catch (e) {
      print('❌ Error requesting permission: $e');
      return false;
    }
  }

  static Future<bool> hasMicrophonePermission() async {
    try {
      final status = await Permission.microphone.status;
      return status.isGranted;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> isMicrophonePermissionPermanentlyDenied() async {
    try {
      final status = await Permission.microphone.status;
      return status.isPermanentlyDenied;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> requestStoragePermission() async {
    // On Android 13+ (API 33+), storage permission is deprecated
    // Apps have automatic access to their own app directory
    // For saving recordings to app directory, no permission needed
    try {
      if (await Permission.storage.isGranted ||
          await Permission.storage.isLimited) {
        return true;
      }

      // On older Android versions, request storage permission
      final status = await Permission.storage.request();

      // If storage permission is denied but we're on newer Android, still allow
      // since we're only writing to app's own directory
      return status.isGranted || status.isLimited || status.isDenied;
    } catch (e) {
      // If storage permission throws an error (e.g., on API 33+),
      // assume we can still write to app directory
      print('📱 Storage permission check failed (expected on Android 13+): $e');
      return true;
    }
  }

  static Future<bool> checkMicrophonePermission() async {
    final status = await Permission.microphone.status;
    return status.isGranted;
  }

  static Future<bool> checkStoragePermission() async {
    try {
      final status = await Permission.storage.status;
      return status.isGranted || status.isLimited;
    } catch (e) {
      // On newer Android versions where storage permission is deprecated
      return true;
    }
  }
}
