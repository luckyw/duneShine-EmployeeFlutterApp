import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:async';
import '../constants/colors.dart';
import '../constants/text_styles.dart';

class NavigateToJobScreen extends StatefulWidget {
  const NavigateToJobScreen({Key? key}) : super(key: key);

  @override
  State<NavigateToJobScreen> createState() => _NavigateToJobScreenState();
}

class _NavigateToJobScreenState extends State<NavigateToJobScreen> {
  bool _hasArrived = false;
  final Completer<GoogleMapController> _mapController = Completer<GoogleMapController>();
  
  // Job location coordinates (Building A, Parking B1, Slot 12)
  // Using a sample location - you can adjust these coordinates
  static const LatLng _jobLocation = LatLng(25.2048, 55.2708); // Dubai example
  
  // Initial camera position
  static const CameraPosition _initialPosition = CameraPosition(
    target: _jobLocation,
    zoom: 16.0,
  );
  
  // Markers set
  final Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _createMarker();
  }

  void _createMarker() {
    _markers.add(
      Marker(
        markerId: const MarkerId('job_location'),
        position: _jobLocation,
        infoWindow: const InfoWindow(
          title: 'Job Location',
          snippet: 'Building A, Parking B1, Slot 12',
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
      ),
    );
  }

  Future<void> _animateToJobLocation() async {
    final GoogleMapController controller = await _mapController.future;
    controller.animateCamera(
      CameraUpdate.newCameraPosition(
        const CameraPosition(
          target: _jobLocation,
          zoom: 17.0,
          tilt: 45.0,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ?? {};
    final String jobId = args['jobId'] ?? 'JOB-56392';
    final String carModel = args['carModel'] ?? 'Toyota Camry';
    final String carColor = args['carColor'] ?? 'White';
    final String employeeName = args['employeeName'] ?? 'Ahmed';
    final double earnedAmount = (args['earnedAmount'] ?? 120.0).toDouble();

    return Scaffold(
      backgroundColor: const Color(0xFF1A3A52),
      appBar: AppBar(
        backgroundColor: AppColors.primaryTeal,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Navigate to Job',
          style: AppTextStyles.headline(context).copyWith(
            color: AppColors.white,
            fontSize: 20, // AppBar size override
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location, color: AppColors.white),
            onPressed: _animateToJobLocation,
            tooltip: 'Center on job location',
          ),
        ],
      ),
      body: Stack(
        children: [
          // Google Maps Widget
          GoogleMap(
            mapType: MapType.normal,
            initialCameraPosition: _initialPosition,
            markers: _markers,
            onMapCreated: (GoogleMapController controller) {
              _mapController.complete(controller);
            },
            myLocationEnabled: true,
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
                        Text(
                          'En Route to Building A',
                          style: AppTextStyles.title(context).copyWith(
                            fontSize: 18,
                            color: AppColors.darkNavy,
                          ),
                        ),
                        const SizedBox(height: 12),
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
                            const Icon(Icons.access_time,
                                color: AppColors.primaryTeal, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Estimated Time: 12 mins',
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
                                'Building A, Parking B1, Slot 12',
                                style: AppTextStyles.body(context).copyWith(
                                  color: AppColors.darkNavy,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _hasArrived = true;
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFFC107),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
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
    super.dispose();
  }
}
