import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../constants/colors.dart';
import '../constants/text_styles.dart';
import '../models/job_model.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../utils/responsive_utils.dart';

class JobArrivalPhotoScreen extends StatefulWidget {
  final String jobId;
  final String carModel;
  final String carColor;

  const JobArrivalPhotoScreen({
    Key? key,
    required this.jobId,
    required this.carModel,
    required this.carColor,
  }) : super(key: key);

  @override
  State<JobArrivalPhotoScreen> createState() => _JobArrivalPhotoScreenState();
}

class _JobArrivalPhotoScreenState extends State<JobArrivalPhotoScreen> {
  File? _capturedPhoto;
  final ImagePicker _picker = ImagePicker();
  bool _isPhotoUploaded = false;
  bool _isUploading = false;
  Job? _job;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_job == null) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ??
          {};
      if (args['job'] != null && args['job'] is Job) {
        _job = args['job'] as Job;

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
          _job = _job!.mergeWith(Job.fromJson(jobJson));
        });
      }
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      // Compress image to reduce file size for faster uploads
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      if (image != null) {
        // Save to permanent storage to avoid "path not found" errors
        // during the upload process if the temp file gets cleaned up
        final directory = await getApplicationDocumentsDirectory();
        final fileName = 'arrival_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final savedImage = await File(image.path).copy('${directory.path}/$fileName');
        
        setState(() {
          _capturedPhoto = savedImage;
          _isPhotoUploaded = true;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error picking image: $e')));
      }
    }
  }

  Future<void> _verifyAndProceed() async {
    if (!_isPhotoUploaded || _capturedPhoto == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload a photo before verifying')),
      );
      return;
    }

    final routeArgs =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ??
        {};

    // Get job ID - try from Job object first, then from widget
    int? jobId;
    if (_job != null) {
      jobId = _job!.id;
    } else {
      // Try to parse from widget.jobId (format: "JOB-1")
      final idStr = widget.jobId.replaceAll('JOB-', '');
      jobId = int.tryParse(idStr);
    }

    if (jobId == null) {
      // Fallback: navigate without API call
      debugPrint('No valid job ID, navigating directly');
      Navigator.pushNamed(
        context,
        '/wash-progress',
        arguments: {
          ...routeArgs,
          'jobId': widget.jobId,
          'carModel': widget.carModel,
          'carColor': widget.carColor,
          'photoPath': _capturedPhoto?.path,
        },
      );
      return;
    }

    final token = AuthService().token;
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Not authenticated. Please login again.')),
      );
      return;
    }

    setState(() {
      _isUploading = true;
    });

    final response = await ApiService().startWash(
      jobId: jobId,
      photoPath: _capturedPhoto!.path,
      token: token,
    );

    // Print response for debugging/analysis
    debugPrint('=== START WASH API RESPONSE ===');
    debugPrint('Success: ${response['success']}');
    debugPrint('Data: ${response['data']}');
    debugPrint('Message: ${response['message']}');
    debugPrint('===============================');

    setState(() {
      _isUploading = false;
    });

    if (response['success'] == true) {
      // Photo uploaded, navigate to wash progress screen
      if (mounted) {
        final jobJson = response['data']?['job'] as Map<String, dynamic>?;
        Job? nextJob = _job;

        if (jobJson != null) {
          final newJob = Job.fromJson(jobJson);
          if (_job != null) {
            nextJob = _job!.mergeWith(newJob);
          } else {
            nextJob = newJob;
          }
        }

        Navigator.pushNamed(
          context,
          '/wash-progress',
          arguments: {
            ...routeArgs,
            'jobId': widget.jobId,
            'carModel': widget.carModel,
            'carColor': widget.carColor,
            'photoPath': _capturedPhoto?.path,
            'job': nextJob,
          },
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Failed to upload photo'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
    
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      body: Stack(
        children: [
          // 1. Premium Gradient Header
          Container(
            height: ResponsiveUtils.h(context, 260),
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF1E293B), // Dark Blue Grey
                  Color(0xFF334155), // Lighter Blue Grey
                ],
              ),
              borderRadius: BorderRadius.vertical(
                bottom: Radius.circular(ResponsiveUtils.r(context, 32)),
              ),
            ),
          ),

          // Decorative elements
           Positioned(
            top: -60,
            right: -60,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.05),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // AppBar
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: ResponsiveUtils.w(context, 16),
                    vertical: ResponsiveUtils.h(context, 8),
                  ),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pushNamedAndRemoveUntil(
                          context,
                          '/employee-home',
                          (route) => false,
                        ),
                        child: Container(
                          width: ResponsiveUtils.w(context, 40),
                          height: ResponsiveUtils.w(context, 40),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(ResponsiveUtils.r(context, 10)),
                          ),
                          child: Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: Colors.white,
                            size: ResponsiveUtils.r(context, 18),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'Arrival Verification',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.headline(context).copyWith(
                            color: Colors.white,
                            fontSize: ResponsiveUtils.sp(context, 18),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      SizedBox(width: ResponsiveUtils.w(context, 40)),
                    ],
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: ResponsiveUtils.w(context, 20),
                      vertical: ResponsiveUtils.h(context, 24),
                    ),
                    physics: BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Car Info Ticket
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(ResponsiveUtils.r(context, 20)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.06),
                                blurRadius: 20,
                                offset: Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              // Ticket Header
                              Container(
                                padding: EdgeInsets.all(ResponsiveUtils.w(context, 16)),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryTeal.withOpacity(0.08),
                                  borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(ResponsiveUtils.r(context, 20)),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.directions_car_filled_rounded, 
                                      color: AppColors.primaryTeal,
                                      size: ResponsiveUtils.r(context, 20),
                                    ),
                                    SizedBox(width: ResponsiveUtils.w(context, 8)),
                                    Text(
                                      'Vehicle Details',
                                      style: AppTextStyles.body(context).copyWith(
                                        color: AppColors.primaryTeal,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Ticket Content
                              Padding(
                                padding: EdgeInsets.all(ResponsiveUtils.w(context, 20)),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _job?.booking?.vehicle != null
                                                ? '${_job!.booking!.vehicle!.brandName} ${_job!.booking!.vehicle!.model}'
                                                : widget.carModel,
                                            style: AppTextStyles.headline(context).copyWith(
                                              fontSize: ResponsiveUtils.sp(context, 20),
                                              fontWeight: FontWeight.w800,
                                              color: Color(0xFF1E293B),
                                            ),
                                          ),
                                          SizedBox(height: ResponsiveUtils.h(context, 4)),
                                          Text(
                                            _job?.booking?.vehicle?.color ?? widget.carColor,
                                            style: AppTextStyles.body(context).copyWith(
                                              fontSize: ResponsiveUtils.sp(context, 15),
                                              color: Color(0xFF64748B),
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    // License Plate Badge (Mock or from data if available)
                                    if (_job?.booking?.vehicle?.numberPlate != null)
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: ResponsiveUtils.w(context, 8),
                                          vertical: ResponsiveUtils.h(context, 4),
                                        ),
                                        decoration: BoxDecoration(
                                          color: Color(0xFFF1F5F9),
                                          borderRadius: BorderRadius.circular(ResponsiveUtils.r(context, 6)),
                                          border: Border.all(color: Color(0xFFCBD5E1)),
                                        ),
                                        child: Text(
                                          _job!.booking!.vehicle!.numberPlate,
                                          style: TextStyle(
                                            fontFamily: 'Roboto', // License plate vibe
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF334155),
                                            fontSize: ResponsiveUtils.sp(context, 14),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: ResponsiveUtils.h(context, 32)),

                        Text(
                          'Proof of Arrival',
                          style: AppTextStyles.headline(context).copyWith(
                            fontSize: ResponsiveUtils.sp(context, 18),
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1E293B),
                          ),
                        ),

                        SizedBox(height: ResponsiveUtils.h(context, 20)),

                        // Photo Upload Area
                        if (_isPhotoUploaded && _capturedPhoto != null)
                          _buildPhotoPreview()
                        else
                          _buildUploadPlaceholder(context),

                        SizedBox(height: ResponsiveUtils.h(context, 40)),

                        // Verify Button
                        SizedBox(
                          width: double.infinity,
                          height: ResponsiveUtils.h(context, 56),
                          child: ElevatedButton(
                            onPressed: (_isPhotoUploaded && !_isUploading)
                                ? _verifyAndProceed
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryTeal,
                              // If disabled, use a lighter slate
                              disabledBackgroundColor: Color(0xFFE2E8F0), 
                              elevation: (_isPhotoUploaded && !_isUploading) ? 8 : 0,
                              shadowColor: AppColors.primaryTeal.withOpacity(0.4),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(ResponsiveUtils.r(context, 16)),
                              ),
                            ),
                            child: _isUploading
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
                                      Text(
                                        'Verify & Proceed',
                                        style: AppTextStyles.button(context).copyWith(
                                          fontSize: ResponsiveUtils.sp(context, 16),
                                          fontWeight: FontWeight.w700,
                                          color: (_isPhotoUploaded && !_isUploading) 
                                              ? Colors.white 
                                              : Color(0xFF94A3B8),
                                        ),
                                      ),
                                      if (_isPhotoUploaded && !_isUploading) ...[
                                        SizedBox(width: 8),
                                        Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
                                      ]
                                    ],
                                  ),
                          ),
                        ),
                        SizedBox(height: ResponsiveUtils.h(context, 20)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadPlaceholder(BuildContext context) {
    return GestureDetector(
      onTap: () => _showImageSourceModal(context),
      child: Container(
        height: ResponsiveUtils.h(context, 220),
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(ResponsiveUtils.r(context, 20)),
          border: Border.all(
            color: Color(0xFFCBD5E1),
            width: 2,
            style: BorderStyle.solid, // Dashed would be cool but solid is cleaner for premium feel sometimes
          ),
          boxShadow: [
             BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: Offset(0, 4),
            )
          ]
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Color(0xFFF1F5F9), // Slate 100
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.add_a_photo_rounded,
                size: ResponsiveUtils.r(context, 32),
                color: AppColors.primaryTeal,
              ),
            ),
            SizedBox(height: ResponsiveUtils.h(context, 16)),
            Text(
              'Tap to Upload Photo',
              style: AppTextStyles.body(context).copyWith(
                fontSize: ResponsiveUtils.sp(context, 16),
                color: Color(0xFF334155),
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: ResponsiveUtils.h(context, 4)),
            Text(
              'Supports JPG, PNG',
              style: AppTextStyles.body(context).copyWith(
                fontSize: ResponsiveUtils.sp(context, 12),
                color: Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoPreview() {
    return Stack(
      children: [
        Container(
          height: ResponsiveUtils.h(context, 300),
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(ResponsiveUtils.r(context, 20)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 15,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(ResponsiveUtils.r(context, 20)),
            child: Image.file(
              _capturedPhoto!,
              fit: BoxFit.cover,
            ),
          ),
        ),
        Positioned(
          top: 12,
          right: 12,
          child: GestureDetector(
            onTap: () {
              setState(() {
                _capturedPhoto = null;
                _isPhotoUploaded = false;
              });
            },
            child: Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withOpacity(0.5)),
              ),
              child: Icon(
                Icons.close_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 12,
          right: 12,
          child: GestureDetector(
            onTap: () => _showImageSourceModal(context),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                  )
                ]
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.edit_rounded, size: 14, color: AppColors.darkTeal),
                  SizedBox(width: 4),
                  Text(
                    'Retake',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkTeal,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showImageSourceModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: 24),
            Text(
              'Select Photo Source',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildSourceOption(
                  icon: Icons.camera_alt_rounded,
                  label: 'Camera',
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.camera);
                  },
                ),
                _buildSourceOption(
                  icon: Icons.photo_library_rounded,
                  label: 'Gallery',
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.gallery);
                  },
                ),
              ],
            ),
            SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSourceOption({required IconData icon, required String label, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.primaryTeal.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 32, color: AppColors.primaryTeal),
          ),
          SizedBox(height: 12),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF475569),
            ),
          ),
        ],
      ),
    );
  }
}
