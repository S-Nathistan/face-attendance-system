import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class StoragePermissionHelper {
  /// Checks and requests storage permission.
  static Future<bool> requestStoragePermission(BuildContext context) async {
    if (Platform.isAndroid) {
      // For Android 11 (API 30) and above
      if (await Permission.manageExternalStorage.isGranted) {
        return true;
      }

      final status = await Permission.manageExternalStorage.request();
      if (status.isGranted) {
        return true;
      } else {
        await _showPermissionDialog(context);
        return false;
      }
    } else {
      // For iOS or lower Android
      if (await Permission.storage.isGranted) {
        return true;
      }

      final status = await Permission.storage.request();
      if (status.isGranted) {
        return true;
      } else {
        await _showPermissionDialog(context);
        return false;
      }
    }
  }

  /// Shows dialog guiding the user to app settings if permission is denied.
  static Future<void> _showPermissionDialog(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Permission Required'),
        content: const Text(
          'This app needs storage permission to save files. Please enable it in settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await openAppSettings(); // Open system settings
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }
}
