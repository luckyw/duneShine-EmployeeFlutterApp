import 'package:flutter/material.dart';
import 'dart:async';
import '../utils/toast_utils.dart';
import '../utils/responsive_utils.dart';

import '../constants/colors.dart';
import '../constants/text_styles.dart';
import '../models/job_model.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

class WashProgressScreen extends StatefulWidget {
  const WashProgressScreen({Key? key}) : super(key: key);

  @override
  State<WashProgressScreen> createState() => _WashProgressScreenState();
}

class _WashProgressScreenState extends State<WashProgressScreen> {
  late Timer _timer;
  int _elapsedSeconds = 0; // Stopwatch starts from 0
  bool _isRunning = true;
  Job? _job;

  @override
  void initState() {
    super.initState();
    _startStopwatch();
  }

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
      } else {
        // Try to get job ID from jobId argument and fetch
        final jobIdStr = args['jobId'] as String?;
        if (jobIdStr != null) {
          final idStr = jobIdStr.replaceAll('JOB-', '');
          final jobId = int.tryParse(idStr);
          if (jobId != null) {
            _fetchJobById(jobId);
          }
        }
      }
    }
  }

  Future<void> _fetchFullJobDetails() async {
    final token = AuthService().token;
    if (token == null || _job == null) return;

    try {
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
      } else if (mounted) {
        // Show user-friendly error message
        ToastUtils.showErrorToast(
          context,
          response['message'] ?? 'Failed to load job details',
        );
      }
    } catch (e) {
      if (mounted) {
        ToastUtils.showErrorToast(
          context,
          'Network error. Please check your connection.',
        );
      }
    }
  }

  Future<void> _fetchJobById(int jobId) async {
    final token = AuthService().token;
    if (token == null) return;

    try {
      final response = await ApiService().getJobDetails(
        jobId: jobId,
        token: token,
      );

      if (response['success'] == true && mounted) {
        final data = response['data'] as Map<String, dynamic>;
        final jobJson = data['job'] as Map<String, dynamic>?;
        if (jobJson != null) {
          setState(() {
            _job = Job.fromJson(jobJson);
          });
        }
      } else if (mounted) {
        // Show user-friendly error message
        ToastUtils.showErrorToast(
          context,
          response['message'] ?? 'Failed to load job details',
        );
      }
    } catch (e) {
      if (mounted) {
        ToastUtils.showErrorToast(
          context,
          'Network error. Please check your connection.',
        );
      }
    }
  }

  void _startStopwatch() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isRunning) {
        setState(() {
          _elapsedSeconds++;
        });
      }
    });
  }

  void _pauseStopwatch() {
    setState(() {
      _isRunning = false;
    });
  }

  void _resumeStopwatch() {
    setState(() {
      _isRunning = true;
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String _formatDuration(int totalSeconds) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    int hours = totalSeconds ~/ 3600;
    int minutes = (totalSeconds % 3600) ~/ 60;
    int seconds = totalSeconds % 60;
    return '${twoDigits(hours)}:${twoDigits(minutes)}:${twoDigits(seconds)}';
  }

  void _finishWash() {
    // Stop the timer
    _pauseStopwatch();

    // Navigate to photo proof screen with elapsed time
    final routeArgs =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ??
        {};
    Navigator.pushNamed(
      context,
      '/job-completion-proof',
      arguments: {
        ...routeArgs,
        'washDurationSeconds': _elapsedSeconds,
        'washDurationFormatted': _formatDuration(_elapsedSeconds),
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final vehicle = _job?.booking?.vehicle;
    final services = _job?.booking?.servicesPayload ?? [];

    return Scaffold(
      backgroundColor: AppColors.veryLightGray,
      appBar: AppBar(
        backgroundColor: AppColors.primaryTeal,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.white),
          onPressed: () => Navigator.pushNamedAndRemoveUntil(
            context,
            '/employee-home',
            (route) => false,
          ),
        ),
        title: Text(
          'Wash in Progress',
          style: AppTextStyles.headline(context).copyWith(
            color: AppColors.white,
            fontSize: ResponsiveUtils.sp(context, 20),
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Top Section with Timer
            Container(
              width: double.infinity,
              padding: EdgeInsets.only(
                top: ResponsiveUtils.h(context, 40),
                bottom: ResponsiveUtils.h(context, 50),
              ),
              decoration: BoxDecoration(
                color: AppColors.primaryTeal,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(ResponsiveUtils.r(context, 40)),
                  bottomRight: Radius.circular(ResponsiveUtils.r(context, 40)),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryTeal.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Timer Circle
                  Container(
                    width: ResponsiveUtils.r(context, 210),
                    height: ResponsiveUtils.r(context, 210),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.white.withValues(alpha: 0.2),
                        width: 8,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 15,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Container(
                      margin: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.white,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.timer_outlined,
                            size: ResponsiveUtils.r(context, 28),
                            color: AppColors.primaryTeal.withValues(alpha: 0.6),
                          ),
                          ResponsiveUtils.verticalSpace(context, 4),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: ResponsiveUtils.w(context, 12)),
                              child: Text(
                                _formatDuration(_elapsedSeconds),
                                style: AppTextStyles.headline(context).copyWith(
                                  fontSize: ResponsiveUtils.sp(context, 40),
                                  color: AppColors.primaryTeal,
                                  fontWeight: FontWeight.bold,
                                  fontFeatures: const [FontFeature.tabularFigures()],
                                ),
                              ),
                            ),
                          ),
                          ResponsiveUtils.verticalSpace(context, 4),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: ResponsiveUtils.w(context, 12),
                              vertical: ResponsiveUtils.h(context, 4),
                            ),
                            decoration: BoxDecoration(
                              color: _isRunning 
                                ? AppColors.success.withValues(alpha: 0.1)
                                : AppColors.gold.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              _isRunning ? 'WASHING' : 'PAUSED',
                              style: AppTextStyles.caption(context).copyWith(
                                color: _isRunning ? AppColors.success : AppColors.gold,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                                fontSize: ResponsiveUtils.sp(context, 10),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  ResponsiveUtils.verticalSpace(context, 30),
                  // Control Button
                  GestureDetector(
                    onTap: _isRunning ? _pauseStopwatch : _resumeStopwatch,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: ResponsiveUtils.w(context, 24),
                        vertical: ResponsiveUtils.h(context, 12),
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: AppColors.white.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
                            color: AppColors.white,
                            size: ResponsiveUtils.r(context, 24),
                          ),
                          ResponsiveUtils.horizontalSpace(context, 8),
                          Text(
                            _isRunning ? 'Pause Timer' : 'Resume Timer',
                            style: AppTextStyles.subtitle(context).copyWith(
                              color: AppColors.white,
                              fontSize: ResponsiveUtils.sp(context, 16),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Bottom Section with Job Details
            Padding(
              padding: EdgeInsets.all(ResponsiveUtils.w(context, 20)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'JOB DETAILS',
                    style: AppTextStyles.caption(context).copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                      color: AppColors.lightGray,
                    ),
                  ),
                  ResponsiveUtils.verticalSpace(context, 12),
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(ResponsiveUtils.r(context, 20)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    padding: EdgeInsets.all(ResponsiveUtils.w(context, 20)),
                    child: Column(
                      children: [
                        _buildDetailItem(
                          Icons.tag,
                          'Job ID',
                          'JOB-${_job?.id ?? "..."}',
                          color: AppColors.primaryTeal,
                        ),
                        _buildDivider(),
                        _buildDetailItem(
                          Icons.location_on_outlined,
                          'Address',
                          _job?.booking?.fullAddress ?? 'Fetching address...',
                        ),
                        _buildDivider(),
                        _buildDetailItem(
                          Icons.directions_car_outlined,
                          'Vehicle',
                          '${vehicle?.brandName} ${vehicle?.model} (${vehicle?.color ?? ""})\nPlate: ${vehicle?.numberPlate ?? ""}',
                        ),
                        _buildDivider(),
                        _buildDetailItem(
                          Icons.person_outline,
                          'Customer',
                          '${_job?.booking?.customer?.name ?? "..."}\n${_job?.booking?.customer?.phone ?? ""}',
                        ),
                        _buildDivider(),
                        _buildDetailItem(
                          Icons.settings_outlined,
                          'Services',
                          services.isNotEmpty
                              ? services.map((s) => s.name).join(', ')
                              : 'Standard Wash',
                        ),
                        if (_job?.booking?.notes != null && _job!.booking!.notes!.isNotEmpty) ...[
                          _buildDivider(),
                          _buildDetailItem(
                            Icons.info_outline,
                            'Notes',
                            _job!.booking!.notes!,
                          ),
                        ],
                        if (vehicle?.parkingNotes != null && vehicle!.parkingNotes!.isNotEmpty) ...[
                          _buildDivider(),
                          _buildDetailItem(
                            Icons.local_parking_outlined,
                            'Parking Notes',
                            vehicle!.parkingNotes!,
                            isLast: true,
                          ),
                        ],
                      ],
                    ),
                  ),
                  ResponsiveUtils.verticalSpace(context, 30),
                  // Finish Button
                  SizedBox(
                    width: double.infinity,
                    height: ResponsiveUtils.h(context, 60),
                    child: ElevatedButton(
                      onPressed: _finishWash,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.darkNavy,
                        foregroundColor: AppColors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(ResponsiveUtils.r(context, 16)),
                        ),
                        elevation: 4,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.camera_alt_outlined, size: ResponsiveUtils.r(context, 22)),
                          ResponsiveUtils.horizontalSpace(context, 10),
                          Text(
                            'FINISH WASH',
                            style: AppTextStyles.button(context).copyWith(
                              letterSpacing: 1.1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  ResponsiveUtils.verticalSpace(context, 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String label, String value, {Color? color, bool isLast = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: ResponsiveUtils.h(context, 4)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(ResponsiveUtils.r(context, 8)),
            decoration: BoxDecoration(
              color: (color ?? AppColors.primaryTeal).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              size: ResponsiveUtils.r(context, 20),
              color: color ?? AppColors.primaryTeal,
            ),
          ),
          ResponsiveUtils.horizontalSpace(context, 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: AppTextStyles.caption(context).copyWith(
                    fontSize: ResponsiveUtils.sp(context, 10),
                    fontWeight: FontWeight.bold,
                    color: AppColors.lightGray,
                  ),
                ),
                ResponsiveUtils.verticalSpace(context, 2),
                Text(
                  value,
                  style: AppTextStyles.body(context).copyWith(
                    color: AppColors.darkNavy,
                    fontSize: ResponsiveUtils.sp(context, 14),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: EdgeInsets.only(
        left: ResponsiveUtils.w(context, 52),
        top: ResponsiveUtils.h(context, 12),
        bottom: ResponsiveUtils.h(context, 12),
      ),
      child: Divider(
        height: 1,
        color: AppColors.lightGray.withValues(alpha: 0.1),
      ),
    );
  }
}
