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
import '../utils/responsive_utils.dart';
import 'dart:ui' as ui;
import 'dart:typed_data';

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
  
  // Default location (fallback) - Bhopal, India
  static const LatLng _defaultLocation = LatLng(23.030451, 78.076358);

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
        
        // If the job is "lean" (missing booking info), fetch full details
        if (_job!.booking == null) {
          _fetchFullJobDetails();
        }
      }
    }
  }

  Future<void> _fetchFullJobDetails() async {
    final token = AuthService().token;
    if (token == null || _job == null) return;

    final response = await ApiService().getJobDetails(
      jobId: _job!.id,
      token: token,
    );

    if (response['success'] == true && mounted) {
      final data = response['data'] as Map<String, dynamic>;
      final jobJson = data['job'] as Map<String, dynamic>?;
      if (jobJson != null) {
        setState(() {
          // Merge to preserve statuses but gain booking details
          _job = _job!.mergeWith(Job.fromJson(jobJson));
          _parseCustomerLocation();
          _updateMarkers();
          _fetchRoute();
        });
      }
    }
  }

  /// Parse customer location from booking property
  void _parseCustomerLocation() {
    print('DEBUG: Attempting to parse customer location...');
    
    final property = _job?.booking?.property;
    final latStr = property?.resolvedLatitude;
    final lngStr = property?.resolvedLongitude;

    if (latStr != null && lngStr != null) {
      final lat = double.tryParse(latStr);
      final lng = double.tryParse(lngStr);
      if (lat != null && lng != null) {
        _customerLocation = LatLng(lat, lng);
        print('DEBUG: Successfully parsed destination from resolved_location: $_customerLocation');
        return;
      }
    }
    
    // Fallback to legacy geoLocation string
    final geoStr = _job?.booking?.geoLocation;
    if (geoStr != null && geoStr.isNotEmpty) {
      print('DEBUG: Found legacy location string: $geoStr');
      final parts = geoStr.split(',');
      if (parts.length == 2) {
        final lat = double.tryParse(parts[0].trim());
        final lng = double.tryParse(parts[1].trim());
        if (lat != null && lng != null) {
          _customerLocation = LatLng(lat, lng);
          print('DEBUG: Successfully parsed legacy destination: $_customerLocation');
          return;
        }
      }
    }
    
    // Fallback to default if parsing fails
    print('DEBUG: Falling back to default location (Bhopal)');
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


  /// Create a custom marker icon from a Flutter Icon
  Future<BitmapDescriptor> _createMarkerImageFromIcon(IconData icon, Color color) async {
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    final Paint paint = Paint()..color = color;
    final double size = 100.0; // Size of the marker

    // Draw background circle
    canvas.drawCircle(Offset(size / 2, size / 2), size / 2, paint);

    // Draw icon
    final TextPainter textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );
    textPainter.text = TextSpan(
      text: String.fromCharCode(icon.codePoint),
      style: TextStyle(
        fontSize: size * 0.6,
        fontFamily: icon.fontFamily,
        color: Colors.white,
      ),
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        (size - textPainter.width) / 2,
        (size - textPainter.height) / 2,
      ),
    );

    final ui.Image image = await pictureRecorder.endRecording().toImage(
      size.toInt(),
      size.toInt(),
    );
    final ByteData? data = await image.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.fromBytes(data!.buffer.asUint8List());
  }

  /// Update map markers
  Future<void> _updateMarkers() async {
    // Employee marker (Custom Car Icon)
    if (_currentPosition != null) {
      final BitmapDescriptor employeeIcon = await _createMarkerImageFromIcon(
        Icons.directions_car,
        AppColors.primaryTeal,
      );

      setState(() {
         // Clear existing employee marker if any
        _markers.removeWhere((m) => m.markerId.value == 'employee');
        
        _markers.add(
          Marker(
            markerId: const MarkerId('employee'),
            position: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
            infoWindow: const InfoWindow(title: 'Your Location'),
            icon: employeeIcon,
          ),
        );
      });
    }
    
    // Customer/Property marker
    if (_customerLocation != null) {
      final BitmapDescriptor customerIcon = await _createMarkerImageFromIcon(
        Icons.location_on,
        Colors.redAccent,
      );

      final booking = _job?.booking;
      setState(() {
         // Clear existing customer marker if any
        _markers.removeWhere((m) => m.markerId.value == 'customer');

        _markers.add(
          Marker(
            markerId: const MarkerId('customer'),
            position: _customerLocation!,
            infoWindow: InfoWindow(
              title: booking?.locationName ?? 'Property Location',
              snippet: booking?.fullAddress ?? 'Destination',
            ),
            icon: customerIcon,
          ),
        );
      });
    }
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
    final apiMapUrl = _job?.booking?.googleMapsUrl;
    
    // If we have a direct URL from API, try to use it
    if (apiMapUrl != null && apiMapUrl.isNotEmpty) {
      final Uri uri = Uri.parse(apiMapUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return;
      }
    }

    if (_customerLocation == null) return;
    
    final lat = _customerLocation!.latitude;
    final lng = _customerLocation!.longitude;
    final title = _job?.booking?.locationName ?? 'Destination';
    
    // Platform specific URLs
    final Uri googleMapsUri = Uri.parse('comgooglemaps://?daddr=$lat,$lng&directionsmode=driving');
    final Uri appleMapsUrl = Uri.parse('https://maps.apple.com/?daddr=$lat,$lng');
    final Uri androidUri = Uri.parse('geo:$lat,$lng?q=$lat,$lng($title)');
    final Uri webUrl = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=driving');

    try {
      if (Theme.of(context).platform == TargetPlatform.iOS) {
        if (await canLaunchUrl(googleMapsUri)) {
          await launchUrl(googleMapsUri);
        } else if (await canLaunchUrl(appleMapsUrl)) {
          await launchUrl(appleMapsUrl);
        } else {
          await launchUrl(webUrl, mode: LaunchMode.externalApplication);
        }
      } else {
        // Android
        if (await canLaunchUrl(androidUri)) {
          await launchUrl(androidUri);
        } else {
          await launchUrl(webUrl, mode: LaunchMode.externalApplication);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not match map: $e')),
        );
      }
      // Last resort fallback
      if (await canLaunchUrl(webUrl)) {
        await launchUrl(webUrl, mode: LaunchMode.externalApplication);
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
      
      // Update local job with new status
      Job? updatedJob = _job;
      if (jobJson != null) {
        final newJob = Job.fromJson(jobJson);
        if (_job != null) {
          updatedJob = _job!.mergeWith(newJob);
        } else {
          updatedJob = newJob;
        }

        setState(() {
          _job = updatedJob;
          _hasArrived = true;
        });
      }

      // Stop location tracking
      _locationService.stopSendingLocation();

      if (mounted) {
        final vehicle = updatedJob?.booking?.vehicle;
        final carModel = vehicle != null ? '${vehicle.brandName} ${vehicle.model}' : 'Unknown Vehicle';
        final carColor = vehicle?.color ?? 'Unknown';
        final employeeName = AuthService().employeeName;
        
        double earnedAmount = 0;
        if (updatedJob?.booking != null) {
          for (var service in updatedJob!.booking!.servicesPayload) {
            earnedAmount += double.tryParse(service.price) ?? 0;
          }
        }

        // Retrieve fallback args from route settings
        final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ?? {};
        final fallbackJobId = args['jobId'];

        Navigator.pushNamed(
          context,
          '/job-verification',
          arguments: {
            'jobId': updatedJob != null ? 'JOB-${updatedJob.id}' : fallbackJobId,
            'carModel': carModel,
            'carColor': carColor,
            'employeeName': employeeName,
            'earnedAmount': earnedAmount,
            'job': updatedJob,
            'startOtp': updatedJob?.startOtp,
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
    final booking = _job?.booking;
    
    // Initial camera position
    final initialPosition = _currentPosition != null
        ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
        : (_customerLocation ?? _defaultLocation);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // 1. Fullscreen Map
          _isLoading
              ? const Center(child: CircularProgressIndicator(color: AppColors.primaryTeal))
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
                  myLocationEnabled: false,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  compassEnabled: false,
                  mapToolbarEnabled: false,
                  padding: EdgeInsets.only(
                    bottom: ResponsiveUtils.h(context, 350), // Padding for bottom sheet
                    top: ResponsiveUtils.h(context, 100), // Padding for header
                  ),
                ),

          // 2. Premium Back Button (Floating)
          Positioned(
            top: ResponsiveUtils.h(context, 50),
            left: ResponsiveUtils.w(context, 20),
            child: GestureDetector(
              onTap: () {
                _locationService.stopSendingLocation();
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/employee-home',
                  (route) => false,
                );
              },
              child: Container(
                padding: EdgeInsets.all(ResponsiveUtils.w(context, 12)),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.arrow_back,
                  color: AppColors.darkNavy,
                  size: ResponsiveUtils.r(context, 24),
                ),
              ),
            ),
          ),

          // 3. Floating Map Controls (Right Side)
          Positioned(
            top: ResponsiveUtils.h(context, 50),
            right: ResponsiveUtils.w(context, 20),
            child: Column(
              children: [
                _buildMapControl(
                  icon: Icons.my_location_rounded,
                  onTap: _centerOnEmployee,
                ),
                ResponsiveUtils.verticalSpace(context, 12),
                _buildMapControl(
                  icon: Icons.map_rounded,
                  onTap: _openGoogleMaps,
                  isPrimary: true,
                ),
              ],
            ),
          ),

          // 4. Premium Bottom Sheet
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(ResponsiveUtils.r(context, 32)),
                  topRight: Radius.circular(ResponsiveUtils.r(context, 32)),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 25,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              padding: EdgeInsets.fromLTRB(
                ResponsiveUtils.w(context, 24),
                ResponsiveUtils.h(context, 12),
                ResponsiveUtils.w(context, 24),
                ResponsiveUtils.h(context, 32),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   // Handle bar
                  Center(
                    child: Container(
                      width: ResponsiveUtils.w(context, 40),
                      height: ResponsiveUtils.h(context, 4),
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  ResponsiveUtils.verticalSpace(context, 24),

                  if (_hasArrived)
                    _buildArrivedState(context)
                  else
                    _buildNavigationState(context, booking),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapControl({
    required IconData icon,
    required VoidCallback onTap,
    bool isPrimary = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(ResponsiveUtils.w(context, 12)),
        decoration: BoxDecoration(
          color: isPrimary ? AppColors.primaryTeal : Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: (isPrimary ? AppColors.primaryTeal : Colors.black)
                  .withValues(alpha: 0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(
          icon,
          color: isPrimary ? Colors.white : AppColors.darkNavy,
          size: ResponsiveUtils.r(context, 24),
        ),
      ),
    );
  }

  Widget _buildNavigationState(BuildContext context, Booking? booking) {
    final locationName = booking?.locationName ?? 'Destination';
    final locationAddress = booking?.fullAddress ?? 'Loading address...';
    final customerName = booking?.customer?.name ?? 'Unknown Customer';
    final jobId = _job != null ? 'JOB-${_job!.id}' : 'Loading...';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Job ID Badge
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: ResponsiveUtils.w(context, 10),
            vertical: ResponsiveUtils.h(context, 4),
          ),
          decoration: BoxDecoration(
            color: AppColors.primaryTeal.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: AppColors.primaryTeal.withValues(alpha: 0.2),
            ),
          ),
          child: Text(
            jobId,
            style: AppTextStyles.caption(context).copyWith(
              color: AppColors.primaryTeal,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ),
        ResponsiveUtils.verticalSpace(context, 12),
        
        // Location Details
        Text(
          locationName,
          style: AppTextStyles.title(context).copyWith(
            fontWeight: FontWeight.w700,
            fontSize: ResponsiveUtils.sp(context, 20),
          ),
        ),
        ResponsiveUtils.verticalSpace(context, 8),
        Row(
          children: [
            Icon(
              Icons.location_on_rounded,
              size: ResponsiveUtils.r(context, 16),
              color: AppColors.textGray,
            ),
            ResponsiveUtils.horizontalSpace(context, 8),
            Expanded(
              child: Text(
                locationAddress,
                style: AppTextStyles.body(context).copyWith(
                  color: AppColors.textGray,
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        
        ResponsiveUtils.verticalSpace(context, 24),
        
        // Customer Row
        Container(
          padding: EdgeInsets.all(ResponsiveUtils.w(context, 16)),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(ResponsiveUtils.r(context, 16)),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              Container(
                width: ResponsiveUtils.w(context, 44),
                height: ResponsiveUtils.h(context, 44),
                decoration: BoxDecoration(
                  color: AppColors.primaryTeal.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: booking?.customer?.idProofImageUrl != null
                    ? ClipOval(
                        child: Image.network(
                          booking!.customer!.idProofImageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Icon(
                            Icons.person,
                            color: AppColors.primaryTeal,
                            size: 20,
                          ),
                        ),
                      )
                    : Icon(Icons.person, color: AppColors.primaryTeal),
              ),
              ResponsiveUtils.horizontalSpace(context, 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Customer',
                      style: AppTextStyles.caption(context).copyWith(
                        color: AppColors.textGray,
                      ),
                    ),
                    Text(
                      customerName,
                      style: AppTextStyles.body(context).copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.darkNavy,
                      ),
                    ),
                  ],
                ),
              ),
              if (booking?.customer?.phone != null)
                IconButton(
                  onPressed: () async {
                    final Uri launchUri = Uri(
                      scheme: 'tel',
                      path: booking!.customer!.phone,
                    );
                    if (await canLaunchUrl(launchUri)) {
                      await launchUrl(launchUri);
                    }
                  },
                  icon: Container(
                    padding: EdgeInsets.all(ResponsiveUtils.w(context, 10)),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.phone_rounded,
                      color: Colors.green,
                      size: ResponsiveUtils.r(context, 20),
                    ),
                  ),
                ),
            ],
          ),
        ),
        
        ResponsiveUtils.verticalSpace(context, 24),
        
        // Open Maps Button
        SizedBox(
          width: double.infinity,
          height: ResponsiveUtils.h(context, 48),
          child: OutlinedButton.icon(
            onPressed: _openGoogleMaps,
            icon: Icon(
              Icons.map_outlined,
              size: ResponsiveUtils.r(context, 20),
            ),
            label: Text(
              'Open Google Maps',
              style: AppTextStyles.button(context).copyWith(
                color: AppColors.primaryTeal,
                fontSize: ResponsiveUtils.sp(context, 16),
                fontWeight: FontWeight.w600,
              ),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primaryTeal,
              side: BorderSide(color: AppColors.primaryTeal.withValues(alpha: 0.5)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(ResponsiveUtils.r(context, 16)),
              ),
            ),
          ),
        ),

        ResponsiveUtils.verticalSpace(context, 16),
        
        // Arrive Button
        SizedBox(
          width: double.infinity,
          height: ResponsiveUtils.h(context, 56),
          child: ElevatedButton(
            onPressed: _isMarkingArrival ? null : _handleArrival,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryTeal,
              elevation: 4,
              shadowColor: AppColors.primaryTeal.withValues(alpha: 0.4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(ResponsiveUtils.r(context, 16)),
              ),
            ),
            child: _isMarkingArrival
                ? SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.flag_rounded, color: Colors.white),
                      ResponsiveUtils.horizontalSpace(context, 10),
                      Text(
                        'Mark as Arrived',
                        style: AppTextStyles.button(context).copyWith(
                          color: Colors.white,
                          fontSize: ResponsiveUtils.sp(context, 16),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildArrivedState(BuildContext context) {
    return Column(
      children: [
        Container(
          width: ResponsiveUtils.w(context, 80),
          height: ResponsiveUtils.h(context, 80),
          decoration: BoxDecoration(
            color: Colors.green.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.check_circle_rounded,
            color: Colors.green,
            size: ResponsiveUtils.r(context, 48),
          ),
        ),
        ResponsiveUtils.verticalSpace(context, 16),
        Text(
          'You Have Arrived',
          style: AppTextStyles.headline(context).copyWith(
            fontSize: ResponsiveUtils.sp(context, 24),
            color: AppColors.darkNavy,
          ),
        ),
        ResponsiveUtils.verticalSpace(context, 8),
        Text(
          'You are at the destination',
          style: AppTextStyles.body(context).copyWith(
            color: AppColors.textGray,
          ),
        ),
        ResponsiveUtils.verticalSpace(context, 32),
        SizedBox(
          width: double.infinity,
          height: ResponsiveUtils.h(context, 56),
          child: ElevatedButton(
            onPressed: () {
               // Logic from previous implementation
               // We navigate to verification, passing all necessary args
               if (_job != null) {
                  // If we have the job, we can pass it
                   // See _handleArrival logic for what happens next
                   // This button basically just duplicates the auto-navigation success action
                   // or manual proceed if auto-nav failed/user stayed on screen
                   final vehicle = _job?.booking?.vehicle;
                   final carModel = vehicle != null ? '${vehicle.brandName} ${vehicle.model}' : 'Unknown Vehicle';
                   final carColor = vehicle?.color ?? 'Unknown';
                   final employeeName = AuthService().employeeName;
                   
                   double earnedAmount = 0;
                   if (_job?.booking != null) {
                     for (var service in _job!.booking!.servicesPayload) {
                       earnedAmount += double.tryParse(service.price) ?? 0;
                     }
                   }

                   Navigator.pushNamed(
                     context,
                     '/job-verification',
                     arguments: {
                       'jobId': 'JOB-${_job!.id}',
                       'carModel': carModel,
                       'carColor': carColor,
                       'employeeName': employeeName,
                       'earnedAmount': earnedAmount,
                       'job': _job,
                       'startOtp': _job?.startOtp,
                     },
                   );
               }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryTeal,
              elevation: 4,
              shadowColor: AppColors.primaryTeal.withValues(alpha: 0.4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(ResponsiveUtils.r(context, 16)),
              ),
            ),
            child: Text(
              'Proceed to Job',
              style: AppTextStyles.button(context).copyWith(
                color: Colors.white,
                fontSize: ResponsiveUtils.sp(context, 16),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
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
