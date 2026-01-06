import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';
import '../constants/colors.dart';
import '../constants/text_styles.dart';
import '../models/job_model.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/location_tracking_service.dart';

class NavigateToJobScreen extends StatefulWidget {
  const NavigateToJobScreen({Key? key}) : super(key: key);

  @override
  State<NavigateToJobScreen> createState() => _NavigateToJobScreenState();
}

class _NavigateToJobScreenState extends State<NavigateToJobScreen> {
  bool _hasArrived = false;
  bool _isMarkingArrival = false;
  bool _isLoading = true;
  Job? _job;
  
  GoogleMapController? _mapController;
  final LocationTrackingService _locationService = LocationTrackingService();
  
  // Employee's current position
  Position? _currentPosition;
  StreamSubscription<Position>? _positionStream;
  
  // Customer location (destination)
  LatLng? _customerLocation;
  
  // Map markers
  final Set<Marker> _markers = {};
  
  // Route polyline
  final Set<Polyline> _polylines = {};
  List<LatLng> _polylineCoordinates = [];
  
  // Google Directions API key (same as Maps key)
  static const String _googleApiKey = 'AIzaSyD3Zy41HBhg8K73xjRMeZyCRceJfShzkMs';
  
  // Default Dubai location (fallback)
  static const LatLng _defaultLocation = LatLng(25.2048, 55.2708);

  @override
  void initState() {
    super.initState();
    _initializeLocation();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_job == null) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ?? {};
      if (args['job'] != null && args['job'] is Job) {
        _job = args['job'] as Job;
        _parseCustomerLocation();
      }
    }
  }

  /// Parse customer location from apartment geo_location
  void _parseCustomerLocation() {
    if (_job?.booking?.apartment?.geoLocation != null) {
      final geoStr = _job!.booking!.apartment!.geoLocation;
      // Expected format: "lat,lng" e.g., "25.2048,55.2708"
      final parts = geoStr.split(',');
      if (parts.length == 2) {
        final lat = double.tryParse(parts[0].trim());
        final lng = double.tryParse(parts[1].trim());
        if (lat != null && lng != null) {
          _customerLocation = LatLng(lat, lng);
          return;
        }
      }
    }
    // Fallback to default if parsing fails
    _customerLocation = _defaultLocation;
  }

  /// Initialize location tracking
  Future<void> _initializeLocation() async {
    try {
      // Request permissions
      final hasPermission = await _locationService.requestLocationPermission();
      if (!hasPermission) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location permission required for navigation'),
              backgroundColor: AppColors.error,
            ),
          );
        }
        setState(() => _isLoading = false);
        return;
      }

      // Get current position
      _currentPosition = await _locationService.getCurrentPosition();
      
      // Start position stream for real-time updates
      _startPositionStream();
      
      setState(() => _isLoading = false);
      
      // Update markers and route
      _updateMarkers();
      _fetchRoute();
      
      // Start sending location to Firebase if job exists
      if (_job != null) {
        _startFirebaseTracking();
      }
    } catch (e) {
      debugPrint('Error initializing location: $e');
      setState(() => _isLoading = false);
    }
  }

  /// Start listening to position updates
  void _startPositionStream() {
    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Update every 10 meters
      ),
    ).listen((Position position) {
      setState(() {
        _currentPosition = position;
      });
      _updateMarkers();
      _animateCameraToShowBoth();
    });
  }

  /// Start sending location to Firebase
  Future<void> _startFirebaseTracking() async {
    if (_job == null) return;
    
    try {
      final employeeId = AuthService().employeeId?.toString() ?? 'unknown';
      
      // Set customer location in Firestore
      if (_customerLocation != null) {
        await _locationService.setCustomerLocation(
          jobId: _job!.id,
          latitude: _customerLocation!.latitude,
          longitude: _customerLocation!.longitude,
        );
      }
      
      // Start sending employee location
      await _locationService.startSendingLocation(
        jobId: _job!.id,
        employeeId: employeeId,
      );
    } catch (e) {
      debugPrint('Error starting Firebase tracking: $e');
    }
  }

  /// Update map markers
  void _updateMarkers() {
    _markers.clear();
    
    // Employee marker (blue)
    if (_currentPosition != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('employee'),
          position: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          infoWindow: const InfoWindow(title: 'Your Location'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        ),
      );
    }
    
    // Customer marker (red)
    if (_customerLocation != null) {
      final apartment = _job?.booking?.apartment;
      _markers.add(
        Marker(
          markerId: const MarkerId('customer'),
          position: _customerLocation!,
          infoWindow: InfoWindow(
            title: apartment?.name ?? 'Customer Location',
            snippet: apartment?.fullAddress ?? 'Destination',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
      );
    }
    
    if (mounted) setState(() {});
  }

  /// Fetch and draw route between employee and customer
  Future<void> _fetchRoute() async {
    if (_currentPosition == null || _customerLocation == null) return;
    
    try {
      final polylinePoints = PolylinePoints();
      final result = await polylinePoints.getRouteBetweenCoordinates(
        googleApiKey: _googleApiKey,
        request: PolylineRequest(
          origin: PointLatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          destination: PointLatLng(_customerLocation!.latitude, _customerLocation!.longitude),
          mode: TravelMode.driving,
        ),
      );
      
      if (result.points.isNotEmpty) {
        _polylineCoordinates = result.points
            .map((point) => LatLng(point.latitude, point.longitude))
            .toList();
        
        _polylines.clear();
        _polylines.add(
          Polyline(
            polylineId: const PolylineId('route'),
            points: _polylineCoordinates,
            color: AppColors.primaryTeal,
            width: 5,
          ),
        );
        
        if (mounted) setState(() {});
        _animateCameraToShowBoth();
      }
    } catch (e) {
      debugPrint('Error fetching route: $e');
    }
  }

  /// Animate camera to show both markers
  void _animateCameraToShowBoth() {
    if (_mapController == null) return;
    if (_currentPosition == null || _customerLocation == null) return;
    
    final bounds = LatLngBounds(
      southwest: LatLng(
        _currentPosition!.latitude < _customerLocation!.latitude
            ? _currentPosition!.latitude
            : _customerLocation!.latitude,
        _currentPosition!.longitude < _customerLocation!.longitude
            ? _currentPosition!.longitude
            : _customerLocation!.longitude,
      ),
      northeast: LatLng(
        _currentPosition!.latitude > _customerLocation!.latitude
            ? _currentPosition!.latitude
            : _customerLocation!.latitude,
        _currentPosition!.longitude > _customerLocation!.longitude
            ? _currentPosition!.longitude
            : _customerLocation!.longitude,
      ),
    );
    
    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 80),
    );
  }

  /// Open external Google Maps for turn-by-turn navigation
  Future<void> _openGoogleMaps() async {
    if (_customerLocation == null) return;
    
    final url = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=${_customerLocation!.latitude},${_customerLocation!.longitude}&travelmode=driving',
    );
    
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open Google Maps')),
        );
      }
    }
  }

  /// Center on employee location
  void _centerOnEmployee() {
    if (_mapController == null || _currentPosition == null) return;
    
    _mapController!.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          zoom: 16,
        ),
      ),
    );
  }

  Future<void> _handleArrival() async {
    if (_job == null) {
      setState(() => _hasArrived = true);
      return;
    }

    final token = AuthService().token;
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Not authenticated. Please login again.')),
      );
      return;
    }

    setState(() => _isMarkingArrival = true);

    // Update Firebase status
    try {
      await _locationService.updateJobStatus(_job!.id, 'arrived');
    } catch (e) {
      debugPrint('Error updating Firebase status: $e');
    }

    final response = await ApiService().arrivedAtJob(
      jobId: _job!.id,
      token: token,
    );
    debugPrint('Arrived at job response: $response');

    setState(() => _isMarkingArrival = false);

    if (response['success'] == true) {
      final data = response['data'] as Map<String, dynamic>;
      final jobJson = data['job'] as Map<String, dynamic>?;
      
      Job updatedJob = _job!;
      if (jobJson != null) {
        updatedJob = Job.fromJson(jobJson);
        setState(() {
          _job = updatedJob;
          _hasArrived = true;
        });
      }

      // Stop location tracking
      _locationService.stopSendingLocation();

      if (mounted) {
        final vehicle = updatedJob.booking?.vehicle;
        final carModel = vehicle != null ? '${vehicle.brandName} ${vehicle.model}' : 'Unknown Vehicle';
        final carColor = vehicle?.color ?? 'Unknown';
        final employeeName = AuthService().employeeName;
        
        double earnedAmount = 0;
        if (updatedJob.booking != null) {
          for (var service in updatedJob.booking!.servicesPayload) {
            earnedAmount += double.tryParse(service.price) ?? 0;
          }
        }

        Navigator.pushNamed(
          context,
          '/job-verification',
          arguments: {
            'jobId': 'JOB-${updatedJob.id}',
            'carModel': carModel,
            'carColor': carColor,
            'employeeName': employeeName,
            'earnedAmount': earnedAmount,
            'job': updatedJob,
            'startOtp': updatedJob.startOtp,
          },
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Failed to mark arrival'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ?? {};
    final String jobId = args['jobId'] ?? 'JOB-56392';
    final String carModel = args['carModel'] ?? 'Toyota Camry';
    final String carColor = args['carColor'] ?? 'White';
    final String employeeName = args['employeeName'] ?? 'Ahmed';
    final double earnedAmount = (args['earnedAmount'] ?? 120.0).toDouble();

    final apartment = _job?.booking?.apartment;
    final locationName = apartment?.name ?? 'Customer Location';
    final locationAddress = apartment?.fullAddress ?? 'Loading...';

    // Initial camera position
    final initialPosition = _currentPosition != null
        ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
        : (_customerLocation ?? _defaultLocation);

    return Scaffold(
      backgroundColor: AppColors.darkBlue,
      appBar: AppBar(
        backgroundColor: AppColors.primaryTeal,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.white),
          onPressed: () {
            _locationService.stopSendingLocation();
            Navigator.pop(context);
          },
        ),
        title: Text(
          'Navigate to Job',
          style: AppTextStyles.headline(context).copyWith(
            color: AppColors.white,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location, color: AppColors.white),
            onPressed: _centerOnEmployee,
            tooltip: 'Center on my location',
          ),
          IconButton(
            icon: const Icon(Icons.navigation, color: AppColors.white),
            onPressed: _openGoogleMaps,
            tooltip: 'Open Google Maps',
          ),
        ],
      ),
      body: Stack(
        children: [
          // Google Maps Widget
          _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.primaryTeal),
                )
              : GoogleMap(
                  mapType: MapType.normal,
                  initialCameraPosition: CameraPosition(
                    target: initialPosition,
                    zoom: 14.0,
                  ),
                  markers: _markers,
                  polylines: _polylines,
                  onMapCreated: (GoogleMapController controller) {
                    _mapController = controller;
                    // Animate to show both markers after map is ready
                    Future.delayed(const Duration(milliseconds: 500), () {
                      _animateCameraToShowBoth();
                    });
                  },
                  myLocationEnabled: false, // We show custom marker instead
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  compassEnabled: true,
                  mapToolbarEnabled: false,
                ),
          
          // Bottom sheet with job details
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                  ),
                ],
              ),
              padding: const EdgeInsets.all(24),
              child: _hasArrived
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.check_circle,
                          color: AppColors.primaryTeal,
                          size: 48,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'You Have Arrived',
                          style: AppTextStyles.headline(context).copyWith(
                            fontSize: 20,
                            color: AppColors.darkNavy,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Ready to start the job',
                          style: AppTextStyles.body(context).copyWith(
                            color: AppColors.lightGray,
                          ),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pushNamed(
                                context,
                                '/job-verification',
                                arguments: {
                                  'jobId': jobId,
                                  'carModel': carModel,
                                  'carColor': carColor,
                                  'employeeName': employeeName,
                                  'earnedAmount': earnedAmount,
                                  'job': _job,
                                  'startOtp': _job?.startOtp,
                                },
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryTeal,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'Proceed to Job',
                              style: AppTextStyles.button(context).copyWith(
                                color: AppColors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: AppColors.primaryTeal,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primaryTeal.withValues(alpha: 0.4),
                                    blurRadius: 8,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'En Route to $locationName',
                              style: AppTextStyles.title(context).copyWith(
                                fontSize: 18,
                                color: AppColors.darkNavy,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            const Icon(Icons.directions_car,
                                color: AppColors.primaryTeal, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              '$carModel - $carColor',
                              style: AppTextStyles.body(context).copyWith(
                                color: AppColors.darkNavy,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.location_on,
                                color: AppColors.primaryTeal, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                locationAddress,
                                style: AppTextStyles.body(context).copyWith(
                                  color: AppColors.darkNavy,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        
                        // Open Google Maps button
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: OutlinedButton.icon(
                            onPressed: _openGoogleMaps,
                            icon: const Icon(Icons.navigation, size: 20),
                            label: const Text('Open Google Maps'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.primaryTeal,
                              side: const BorderSide(color: AppColors.primaryTeal),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        
                        // I Have Arrived button
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _isMarkingArrival ? null : _handleArrival,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.amber,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _isMarkingArrival
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      color: AppColors.darkNavy,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(
                                    'I Have Arrived',
                                    style: AppTextStyles.button(context).copyWith(
                                      color: AppColors.darkNavy,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _locationService.stopSendingLocation();
    _mapController?.dispose();
    super.dispose();
  }
}
