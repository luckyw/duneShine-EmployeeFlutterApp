import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../constants/colors.dart';
import '../models/job_model.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

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
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ?? {};
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
      final XFile? image = await _picker.pickImage(source: source);
      if (image != null) {
        setState(() {
          _capturedPhoto = File(image.path);
          _isPhotoUploaded = true;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }

  Future<void> _verifyAndProceed() async {
    if (!_isPhotoUploaded || _capturedPhoto == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload a photo before verifying')),
      );
      return;
    }

    final routeArgs = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ?? {};
    
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
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.darkTeal,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Job Arrival',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.directions_car,
                      size: 40,
                      color: AppColors.primaryTeal,
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _job?.booking?.vehicle != null 
                              ? '${_job!.booking!.vehicle!.brandName} ${_job!.booking!.vehicle!.model}'
                              : widget.carModel,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.darkTeal,
                          ),
                        ),
                        Text(
                          _job?.booking?.vehicle?.color ?? widget.carColor,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              const Text(
                'Capture Before Photo',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkTeal,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Take a clear photo of the car before starting the wash',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 24),
              if (_isPhotoUploaded && _capturedPhoto != null)
                Stack(
                  children: [
                    Container(
                      width: double.infinity,
                      height: 300,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.primaryTeal, width: 2),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.file(
                          _capturedPhoto!,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _capturedPhoto = null;
                            _isPhotoUploaded = false;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              else
                GestureDetector(
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      builder: (context) => Container(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ListTile(
                              leading: const Icon(Icons.camera_alt),
                              title: const Text('Take Photo'),
                              onTap: () {
                                Navigator.pop(context);
                                _pickImage(ImageSource.camera);
                              },
                            ),
                            ListTile(
                              leading: const Icon(Icons.image),
                              title: const Text('Choose from Gallery'),
                              onTap: () {
                                Navigator.pop(context);
                                _pickImage(ImageSource.gallery);
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  child: Container(
                    width: double.infinity,
                    height: 300,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.grey.shade300,
                        width: 2,
                        style: BorderStyle.solid,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.camera_alt,
                          size: 60,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Tap to Upload Photo',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: (_isPhotoUploaded && !_isUploading) ? _verifyAndProceed : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.darkTeal,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppColors.darkTeal.withOpacity(0.4),
                    disabledForegroundColor: Colors.white.withOpacity(0.6),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isUploading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Verify & Proceed',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
