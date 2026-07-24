import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../screens/location_permission_dialog.dart';

class LocationPermissionManager {
  static final LocationPermissionManager _instance =
      LocationPermissionManager._internal();
  factory LocationPermissionManager() => _instance;
  LocationPermissionManager._internal();

  static const String _rationaleShownKey = 'location_rationale_shown';

  Future<bool> hasShownRationale() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_rationaleShownKey) ?? false;
  }

  Future<void> markRationaleShown() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_rationaleShownKey, true);
  }

  /// Check and request with rationale if not shown
  Future<bool> checkAndRequestWithRationale(BuildContext context) async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.always) {
      await _requestNotificationPermission();
      return true;
    }

    if (permission == LocationPermission.denied) {
      if (!context.mounted) return false;
      // Show our in-app disclosure dialog first
      final userAccepted = await _showRationaleDialog(context);
      if (!userAccepted) {
        return false;
      }
      await markRationaleShown();

      // Proceed to system request
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return false;
    }

    // Now request notification permission since location is granted
    await _requestNotificationPermission();

    // Now we have at least whileInUse. We might need always for background.
    if (permission == LocationPermission.whileInUse) {
        // Optionally request always here or guide them.
        // For Android background location, you usually have to ask for whileInUse first,
        // then guide to settings for 'always'.
        // Geolocator.requestPermission() might not prompt for 'always' if requested twice depending on Android version.
        // We'll return true if they granted any permission so they can at least start the shift.
        return true;
    }

    return true;
  }

  Future<bool> _showRationaleDialog(BuildContext context) async {
    bool accepted = false;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return LocationPermissionDialog(
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
    return accepted;
  }

  /// Request directly without checking rationale flag. E.g. from onboarding.
  Future<bool> showRationaleAndRequest(BuildContext context) async {
      await markRationaleShown();
      LocationPermission permission = await Geolocator.requestPermission();
      await _requestNotificationPermission();
      return permission != LocationPermission.denied && permission != LocationPermission.deniedForever;
  }

  Future<void> _requestNotificationPermission() async {
    final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }
}
