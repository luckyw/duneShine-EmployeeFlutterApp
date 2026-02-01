import 'dart:async';
import 'dart:ui';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

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

  /// Start the background service with employee ID
  static void start(int employeeId) {
    final service = FlutterBackgroundService();
    service.startService();
    // Wait a bit for service to start before sending data
    Future.delayed(const Duration(seconds: 1), () {
      service.invoke('updateEmployeeId', {'employeeId': employeeId});
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
    service.on('updateEmployeeId').listen((event) {
      if (event != null && event['employeeId'] != null) {
        employeeId = event['employeeId'].toString();
        debugPrint("Background Service: Received Employee ID $employeeId");
      }
    });

    // Start tracking loop
    // Update every 5 minutes for general tracking to save battery
    Timer.periodic(const Duration(minutes: 5), (timer) async {
      if (employeeId == null) return;

      try {
        final position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.medium, // Lower accuracy for general tracking
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
    });
  }
}
