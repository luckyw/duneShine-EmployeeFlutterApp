import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:employeapplication/constants/colors.dart';
import 'package:employeapplication/constants/text_styles.dart';
import '../models/job_model.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../utils/responsive_utils.dart';

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
        // Save to permanent storage to avoid "path not found" errors
        // during the upload process if the temp file gets cleaned up
        final directory = await getApplicationDocumentsDirectory();
        final fileName = 'completion_${DateTime.now().millisecondsSinceEpoch}.jpg';
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
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);

    return Scaffold(
      backgroundColor: AppColors.veryLightGray,
      body: Column(
        children: [
          // 1. Premium Header
          Container(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + ResponsiveUtils.h(context, 16),
              bottom: ResponsiveUtils.h(context, 24),
              left: ResponsiveUtils.w(context, 24),
              right: ResponsiveUtils.w(context, 24),
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF0F172A), // Dark Navy
                  Color(0xFF1E293B), // Slate
                ],
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(ResponsiveUtils.r(context, 32)),
                bottomRight: Radius.circular(ResponsiveUtils.r(context, 32)),
              ),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: EdgeInsets.all(ResponsiveUtils.w(context, 10)),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(ResponsiveUtils.r(context, 12)),
                    ),
                    child: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Colors.white,
                      size: ResponsiveUtils.sp(context, 20),
                    ),
                  ),
                ),
                SizedBox(width: ResponsiveUtils.w(context, 16)),
                Expanded(
                  child: Text(
                    'Job Completion',
                    style: AppTextStyles.headline(context).copyWith(
                      color: Colors.white,
                      fontSize: ResponsiveUtils.sp(context, 22),
                    ),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.all(ResponsiveUtils.w(context, 24)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 2. Wash Duration Card
                  if (_washDurationFormatted != null) ...[
                    Container(
                      padding: EdgeInsets.all(ResponsiveUtils.w(context, 20)),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(ResponsiveUtils.r(context, 20)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 15,
                            offset: Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(ResponsiveUtils.w(context, 12)),
                            decoration: BoxDecoration(
                              color: AppColors.primaryTeal.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.timer_outlined,
                              color: AppColors.primaryTeal,
                              size: ResponsiveUtils.sp(context, 28),
                            ),
                          ),
                          SizedBox(width: ResponsiveUtils.w(context, 16)),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Total Wash Duration',
                                style: AppTextStyles.body(context).copyWith(
                                  color: AppColors.textGray,
                                  fontSize: ResponsiveUtils.sp(context, 14),
                                ),
                              ),
                              SizedBox(height: ResponsiveUtils.h(context, 4)),
                              Text(
                                _washDurationFormatted!,
                                style: AppTextStyles.headline(context).copyWith(
                                  color: AppColors.textDark,
                                  fontSize: ResponsiveUtils.sp(context, 20),
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    ResponsiveUtils.verticalSpace(context, 24),
                  ],

                  // 3. Photo Upload Section
                  Text(
                    'Proof of Completion',
                    style: AppTextStyles.headline(context).copyWith(
                      fontSize: ResponsiveUtils.sp(context, 18),
                      color: AppColors.textDark,
                    ),
                  ),
                  SizedBox(height: ResponsiveUtils.h(context, 8)),
                  Text(
                    'Upload a clear photo of the clean vehicle to verify the job is done.',
                    style: AppTextStyles.body(context).copyWith(
                      fontSize: ResponsiveUtils.sp(context, 14),
                      color: AppColors.textGray,
                      height: 1.5,
                    ),
                  ),
                  ResponsiveUtils.verticalSpace(context, 24),

                  Container(
                    height: ResponsiveUtils.h(context, 260),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(ResponsiveUtils.r(context, 24)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 20,
                          offset: Offset(0, 4),
                        )
                      ],
                    ),
                    child: _isPhotoUploaded && _capturedPhoto != null
                        ? Stack(
                            fit: StackFit.expand,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(ResponsiveUtils.r(context, 24)),
                                child: Image.file(
                                  _capturedPhoto!,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Positioned(
                                bottom: ResponsiveUtils.h(context, 16),
                                right: ResponsiveUtils.w(context, 16),
                                child: GestureDetector(
                                  onTap: () {
                                    showModalBottomSheet(
                                      context: context,
                                      builder: (context) => _buildPhotoOptionsSheet(context),
                                    );
                                  },
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: ResponsiveUtils.w(context, 16),
                                      vertical: ResponsiveUtils.h(context, 8),
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.7),
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.refresh, color: Colors.white, size: 16),
                                        SizedBox(width: 8),
                                        Text(
                                          'Retake',
                                          style: AppTextStyles.button(context).copyWith(fontSize: 14),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          )
                        : Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                showModalBottomSheet(
                                  context: context,
                                  builder: (context) => _buildPhotoOptionsSheet(context),
                                );
                              },
                              borderRadius: BorderRadius.circular(ResponsiveUtils.r(context, 24)),
                              child: DottedBorderPainter(
                                strokeWidth: 2,
                                color: AppColors.primaryTeal.withOpacity(0.3),
                                gap: 6,
                                radius: 24,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: EdgeInsets.all(ResponsiveUtils.w(context, 20)),
                                      decoration: BoxDecoration(
                                        color: AppColors.primaryTeal.withOpacity(0.08),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.add_a_photo_outlined,
                                        size: ResponsiveUtils.sp(context, 40),
                                        color: AppColors.primaryTeal,
                                      ),
                                    ),
                                    SizedBox(height: ResponsiveUtils.h(context, 16)),
                                    Text(
                                      'Tap to Upload Photo',
                                      style: AppTextStyles.subtitle(context).copyWith(
                                        color: AppColors.primaryTeal,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                  ),
                  
                  ResponsiveUtils.verticalSpace(context, 40),

                  // 4. Submit Button
                  SizedBox(
                    width: double.infinity,
                    height: ResponsiveUtils.h(context, 56),
                    child: ElevatedButton(
                      onPressed: (_isPhotoUploaded && !_isSubmitting)
                          ? _submitJob
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryTeal,
                        foregroundColor: Colors.white,
                        elevation: 8,
                        shadowColor: AppColors.primaryTeal.withOpacity(0.4),
                        disabledBackgroundColor: AppColors.textGray.withOpacity(0.2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(ResponsiveUtils.r(context, 16)),
                        ),
                      ),
                      child: _isSubmitting
                          ? SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : Text(
                              'Complete Job',
                              style: AppTextStyles.button(context).copyWith(
                                fontSize: ResponsiveUtils.sp(context, 18),
                                letterSpacing: 0.5,
                              ),
                            ),
                    ),
                  ),
                  ResponsiveUtils.verticalSpace(context, 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoOptionsSheet(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(ResponsiveUtils.w(context, 20)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          SizedBox(height: 20),
          ListTile(
            leading: Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.camera_alt, color: Colors.blue),
            ),
            title: Text('Take Photo', style: AppTextStyles.subtitle(context)),
            onTap: () {
              Navigator.pop(context);
              _pickImage(ImageSource.camera);
            },
          ),
          ListTile(
            leading: Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.purple.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.image, color: Colors.purple),
            ),
            title: Text('Choose from Gallery', style: AppTextStyles.subtitle(context)),
            onTap: () {
              Navigator.pop(context);
              _pickImage(ImageSource.gallery);
            },
          ),
          SizedBox(height: 20),
        ],
      ),
    );
  }
}

// Custom painter for dashed border
class DottedBorderPainter extends StatelessWidget {
  final Widget child;
  final double strokeWidth;
  final Color color;
  final double gap;
  final double radius;

  const DottedBorderPainter({
    Key? key,
    required this.child,
    this.strokeWidth = 1,
    this.color = Colors.black,
    this.gap = 4,
    this.radius = 0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DottedPainter(
        strokeWidth: strokeWidth,
        color: color,
        gap: gap,
        radius: radius,
      ),
      child: Center(child: child),
    );
  }
}

class _DottedPainter extends CustomPainter {
  final double strokeWidth;
  final Color color;
  final double gap;
  final double radius;

  _DottedPainter({
    required this.strokeWidth,
    required this.color,
    required this.gap,
    required this.radius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final Path path = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Radius.circular(radius),
      ));

    final Path dashedPath = _dashPath(path, width: 8, space: gap);
    canvas.drawPath(dashedPath, paint);
  }

  Path _dashPath(Path source, {required double width, required double space}) {
    final Path dest = Path();
    for (final PathMetric metric in source.computeMetrics()) {
      double distance = 0.0;
      while (distance < metric.length) {
        dest.addPath(
          metric.extractPath(distance, distance + width),
          Offset.zero,
        );
        distance += width + space;
      }
    }
    return dest;
  }

  @override
  bool shouldRepaint(_DottedPainter oldDelegate) {
    return oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.color != color ||
        oldDelegate.gap != gap ||
        oldDelegate.radius != radius;
  }
}
