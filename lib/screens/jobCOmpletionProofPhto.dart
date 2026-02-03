import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:employeapplication/constants/colors.dart';
import '../models/job_model.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

class JobCompletionProofScreen extends StatefulWidget {
  const JobCompletionProofScreen({Key? key}) : super(key: key);

  @override
  State<JobCompletionProofScreen> createState() =>
      _JobCompletionProofScreenState();
}

class _JobCompletionProofScreenState extends State<JobCompletionProofScreen> {
  File? _capturedPhoto;
  final ImagePicker _picker = ImagePicker();
  bool _isPhotoUploaded = false;
  bool _isSubmitting = false;
  Job? _job;
  int? _washDurationSeconds;
  String? _washDurationFormatted;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_job == null) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ??
          {};
      if (args['job'] != null && args['job'] is Job) {
        _job = args['job'] as Job;
      }
      // Get wash duration from previous screen
      if (args['washDurationSeconds'] != null) {
        _washDurationSeconds = args['washDurationSeconds'] as int;
      }
      if (args['washDurationFormatted'] != null) {
        _washDurationFormatted = args['washDurationFormatted'] as String;
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
        setState(() {
          _capturedPhoto = File(image.path);
          _isPhotoUploaded = true;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error picking image: $e')));
    }
  }

  Future<void> _submitJob() async {
    if (!_isPhotoUploaded || _capturedPhoto == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please upload a photo before submitting'),
        ),
      );
      return;
    }

    final routeArgs =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ??
        {};

    // Get job ID - try from Job object first, then parse from args
    int? jobId;
    if (_job != null) {
      jobId = _job!.id;
    } else {
      final jobIdStr =
          routeArgs['jobId']?.toString().replaceAll('JOB-', '') ?? '';
      jobId = int.tryParse(jobIdStr);
    }

    if (jobId == null) {
      // Fallback: navigate without API call
      debugPrint('No valid job ID, navigating directly to OTP screen');
      Navigator.pushNamed(
        context,
        '/job-completion-otp',
        arguments: {
          ...routeArgs,
          'photoPath': _capturedPhoto?.path,
          'washDurationSeconds': _washDurationSeconds,
          'washDurationFormatted': _washDurationFormatted,
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
      _isSubmitting = true;
    });

    final response = await ApiService().finishWash(
      jobId: jobId,
      photoPath: _capturedPhoto!.path,
      token: token,
      durationSeconds: _washDurationSeconds,
    );

    setState(() {
      _isSubmitting = false;
    });

    if (response['success'] == true) {
      // Photo uploaded, navigate to end OTP screen
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
          '/job-completion-otp',
          arguments: {
            ...routeArgs,
            'photoPath': _capturedPhoto?.path,
            'job': nextJob,
            'finishWashResponse': response['data'],
          },
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Failed to submit job'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.primaryTeal,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Job Completion Proof',
          style: TextStyle(
            color: AppColors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Show wash duration if available
              if (_washDurationFormatted != null) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primaryTeal.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.primaryTeal),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.timer, color: AppColors.primaryTeal),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Wash Duration',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textGray,
                            ),
                          ),
                          Text(
                            _washDurationFormatted!,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryTeal,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
              const Text(
                'Please take a clear photo of the clean\ncar as proof of completion.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: AppColors.darkTeal),
              ),
              const SizedBox(height: 32),
              Container(
                height: 300,
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.darkNavy, width: 2),
                  borderRadius: BorderRadius.circular(16),
                  color: AppColors.veryLightGray,
                ),
                child: _isPhotoUploaded && _capturedPhoto != null
                    ? Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.file(
                              _capturedPhoto!,
                              fit: BoxFit.cover,
                              height: 300,
                              width: double.infinity,
                            ),
                          ),
                          Positioned(
                            top: 12,
                            right: 12,
                            child: GestureDetector(
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
                                          title: const Text(
                                            'Choose from Gallery',
                                          ),
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
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.2,
                                      ),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.edit,
                                  color: AppColors.primaryTeal,
                                  size: 24,
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                    : GestureDetector(
                        behavior: HitTestBehavior.opaque,
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
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.camera_alt,
                              size: 64,
                              color: AppColors.darkNavy,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Tap to Take Photo',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.darkNavy,
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: (_isPhotoUploaded && !_isSubmitting)
                      ? _submitJob
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.darkTeal,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppColors.darkTeal.withOpacity(
                      0.4,
                    ),
                    disabledForegroundColor: Colors.white.withOpacity(0.6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Submit Job',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
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
