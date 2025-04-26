import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class CameraPermissionService {
  static final CameraPermissionService _instance =
      CameraPermissionService._internal();

  factory CameraPermissionService() {
    return _instance;
  }

  CameraPermissionService._internal();

  /// Request camera permission and return whether it was granted
  Future<bool> requestCameraPermission() async {
    var status = await Permission.camera.status;

    if (status.isDenied) {
      status = await Permission.camera.request();
    }

    return status.isGranted;
  }

  /// Show dialog to explain why camera permission is needed
  Future<bool> showPermissionDialog(
    BuildContext context,
    String title,
    String message,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('BATAL'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('IZINKAN'),
              ),
            ],
          ),
    );

    return result ?? false;
  }

  /// Open app settings to allow user to manually grant permission
  Future<void> openSettings() async {
    await openAppSettings();
  }
}
