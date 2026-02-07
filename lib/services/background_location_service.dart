import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';

@pragma('vm:entry-point')
class BackgroundLocationService {
  static const String notificationChannelId = 'foreground_service';
  static const int notificationId = 888;

  /// Initialize the background service
  /// This should be called in main() before runApp()
  static Future<void> initializeService() async {
    final service = FlutterBackgroundService();

    // Android notification channel setup
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      notificationChannelId,
      'Shift Tracking',
      description: 'Tracks location while employee shift is active',
      importance: Importance.low,
    );

    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: false,
        isForegroundMode: true,
        notificationChannelId: notificationChannelId,
        initialNotificationTitle: 'DuneShine Shift Active',
        initialNotificationContent: 'Your location is being tracked while on duty',
        foregroundServiceNotificationId: notificationId,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: onStart,
        onBackground: onIosBackground,
      ),
    );
  }

  /// Start the background service with employee ID and auth token
  static void start(int employeeId, {String? token}) {
    final service = FlutterBackgroundService();
    service.startService();
    // Wait a bit for service to start before sending data
    Future.delayed(const Duration(seconds: 1), () {
      service.invoke('updateEmployeeData', {
        'employeeId': employeeId,
        'token': token,
      });
    });
  }

  /// Stop the background service
  static void stop() {
    final service = FlutterBackgroundService();
    service.invoke('stopService');
  }

  @pragma('vm:entry-point')
  static Future<bool> onIosBackground(ServiceInstance service) async {
    WidgetsFlutterBinding.ensureInitialized();
    DartPluginRegistrant.ensureInitialized();
    return true;
  }

  @pragma('vm:entry-point')
  static void onStart(ServiceInstance service) async {
    DartPluginRegistrant.ensureInitialized();
    WidgetsFlutterBinding.ensureInitialized();
    
    // Initialize Firebase for the background process
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }
    } catch (e) {
      debugPrint("Firebase init error in background: $e");
    }

    final FirebaseFirestore firestore = FirebaseFirestore.instance;

    if (service is AndroidServiceInstance) {
      service.on('setAsForeground').listen((event) {
        service.setAsForegroundService();
      });

      service.on('setAsBackground').listen((event) {
        service.setAsBackgroundService();
      });
    }

    service.on('stopService').listen((event) {
      service.stopSelf();
    });

    String? employeeId;
    String? authToken;
    service.on('updateEmployeeData').listen((event) {
      if (event != null) {
        if (event['employeeId'] != null) {
          employeeId = event['employeeId'].toString();
          debugPrint("Background Service: Received Employee ID $employeeId");
        }
        if (event['token'] != null) {
          authToken = event['token'].toString();
          debugPrint("Background Service: Received auth token");
        }
      }
    });

    // Helper function to update location
    Future<void> updateLocation() async {
      if (employeeId == null) return;

      try {
        final position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.medium,
          ),
        );

        await firestore.collection('employee_locations').doc(employeeId).set({
          'employee_id': int.parse(employeeId!),
          'last_location': {
            'latitude': position.latitude,
            'longitude': position.longitude,
          },
          'updated_at': FieldValue.serverTimestamp(),
          'status': 'on_shift',
        }, SetOptions(merge: true));

        // Also call the update-location API
        if (authToken != null) {
          try {
            final response = await http.post(
              Uri.parse(ApiConstants.updateLocationUrl),
              headers: {
                'Content-Type': 'application/json',
                'Accept': 'application/json',
                'Authorization': 'Bearer $authToken',
              },
              body: jsonEncode({
                'latitude': position.latitude,
                'longitude': position.longitude,
              }),
            );
            debugPrint('Update location API response: ${response.statusCode}');
          } catch (apiError) {
            debugPrint('Update location API error: $apiError');
          }
        }

        // Update notification content on Android
        if (service is AndroidServiceInstance) {
          service.setForegroundNotificationInfo(
            title: "DuneShine Shift Active",
            content: "Last updated: ${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}",
          );
        }
      } catch (e) {
        debugPrint("Background tracking error: $e");
      }
    }

    // Run immediately on start - no wait for first interval
    updateLocation();

    // Then continue updating every 1 minute
    Timer.periodic(const Duration(minutes: 1), (timer) async {
      await updateLocation();

    });
  }
}
