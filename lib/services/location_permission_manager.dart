import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../screens/foreground_location_disclosure.dart';
import '../screens/background_location_disclosure.dart';

class LocationPermissionManager {
  static final LocationPermissionManager _instance = LocationPermissionManager._internal();
  factory LocationPermissionManager() => _instance;
  LocationPermissionManager._internal();

  /// Request foreground permission with rationale if needed
  Future<LocationPermission> requestForegroundPermission(BuildContext context) async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return LocationPermission.denied;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    
    if (permission == LocationPermission.always || permission == LocationPermission.whileInUse) {
      return permission;
    }

    if (permission == LocationPermission.denied) {
      if (!context.mounted) return permission;
      
      bool accepted = false;
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return ForegroundLocationDisclosure(
            onAccept: () {
              accepted = true;
              Navigator.of(context).pop();
            },
            onDecline: () {
              accepted = false;
              Navigator.of(context).pop();
            },
          );
        },
      );

      if (accepted) {
        permission = await Geolocator.requestPermission();
      }
    }

    return permission;
  }

  /// Request background permission. Requires foreground to be granted first.
  Future<bool> requestBackgroundPermission(BuildContext context) async {
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.always) {
      return true;
    }

    // Background permission requires foreground permission first on Android 11+
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return false;
    }

    if (!context.mounted) return false;

    bool accepted = false;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return BackgroundLocationDisclosure(
          onAccept: () {
            accepted = true;
            Navigator.of(context).pop();
          },
          onDecline: () {
            accepted = false;
            Navigator.of(context).pop();
          },
        );
      },
    );

    if (accepted) {
      // On Android 11+: geolocator shows a system dialog that says
      // "This app needs background location" and guides the user directly
      // to the Location-specific settings page (not generic app settings).
      // On Android 10 and below: shows a single dialog with "Allow all the time" directly.
      // Do NOT call openAppSettings() separately — that opens the wrong page.
      permission = await Geolocator.requestPermission();
    }

    return permission == LocationPermission.always;
  }

  /// Check and request for start shift, running the full two-step flow
  Future<bool> checkAndRequestForStartShift(BuildContext context) async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!context.mounted) return false;
    if (!serviceEnabled) {
      _showSettingsDialog(context, 'Location Services Disabled', 'Please enable location services to start a shift.');
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    
    // Step 1: Check foreground
    if (permission == LocationPermission.denied) {
      permission = await requestForegroundPermission(context);
    }
    
    if (!context.mounted) return false;
    if (permission == LocationPermission.deniedForever) {
      _showSettingsDialog(context, 'Permission Denied', 'Please go to Settings and allow location permission to start a shift.');
      return false;
    }
    
    if (permission == LocationPermission.denied) {
       return false; // User declined foreground dialog
    }

    // Step 2: Check background
    if (permission == LocationPermission.whileInUse) {
      bool bgGranted = await requestBackgroundPermission(context);
      if (!bgGranted) {
        // Double check if it became denied forever during the process
        permission = await Geolocator.checkPermission();
        if (!context.mounted) return false;
        if (permission == LocationPermission.whileInUse || permission == LocationPermission.deniedForever) {
           _showSettingsDialog(context, 'Background Location Required', 'Please go to Settings -> Location and select "Allow all the time" to start a shift.');
        }
        return false;
      }
    }

    // All good
    await _requestNotificationPermission();
    return true;
  }

  void _showSettingsDialog(BuildContext context, String title, String message) {
    if (!context.mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Geolocator.openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  Future<void> _requestNotificationPermission() async {
    final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }
}
