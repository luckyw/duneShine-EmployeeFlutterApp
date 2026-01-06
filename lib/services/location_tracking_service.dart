import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';

/// Service for real-time location tracking using Firebase Firestore
class LocationTrackingService {
  static final LocationTrackingService _instance = LocationTrackingService._internal();
  factory LocationTrackingService() => _instance;
  LocationTrackingService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  StreamSubscription<Position>? _locationSubscription;
  String? _currentJobId;

  /// Check and request location permissions
  Future<bool> requestLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return false;
    }

    if (permission == LocationPermission.deniedForever) return false;
    return true;
  }

  /// Get current position once
  Future<Position?> getCurrentPosition() async {
    if (!await requestLocationPermission()) return null;
    return await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
  }

  /// Start sending location updates to Firestore
  Future<void> startSendingLocation({
    required int jobId,
    required String employeeId,
    int distanceFilter = 10,
  }) async {
    if (!await requestLocationPermission()) {
      throw Exception('Location permission denied');
    }

    _currentJobId = jobId.toString();

    // Initialize tracking document
    final docRef = _firestore.collection('job_tracking').doc(_currentJobId);
    final doc = await docRef.get();

    if (!doc.exists) {
      await docRef.set({
        'employee_id': employeeId,
        'job_status': 'en_route',
        'created_at': FieldValue.serverTimestamp(),
      });
    } else {
      await docRef.update({'job_status': 'en_route'});
    }

    // Start location stream
    _locationSubscription = Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: distanceFilter,
      ),
    ).listen((Position position) {
      _firestore.collection('job_tracking').doc(_currentJobId).update({
        'employee_location': {
          'latitude': position.latitude,
          'longitude': position.longitude,
          'updated_at': FieldValue.serverTimestamp(),
        },
      });
    });
  }

  /// Stop sending location updates
  void stopSendingLocation() {
    _locationSubscription?.cancel();
    _locationSubscription = null;
    _currentJobId = null;
  }

  /// Update job status in Firestore
  Future<void> updateJobStatus(int jobId, String status) async {
    await _firestore.collection('job_tracking').doc(jobId.toString()).update({
      'job_status': status,
    });
  }

  /// Set customer destination location
  Future<void> setCustomerLocation({
    required int jobId,
    required double latitude,
    required double longitude,
  }) async {
    final docRef = _firestore.collection('job_tracking').doc(jobId.toString());
    final doc = await docRef.get();

    if (doc.exists) {
      await docRef.update({
        'customer_location': {'latitude': latitude, 'longitude': longitude},
      });
    } else {
      await docRef.set({
        'customer_location': {'latitude': latitude, 'longitude': longitude},
        'created_at': FieldValue.serverTimestamp(),
      });
    }
  }

  /// Check if currently tracking
  bool get isTracking => _locationSubscription != null;
}
