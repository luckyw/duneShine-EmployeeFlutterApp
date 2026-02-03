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
      backgroundColor: AppColors.white,
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
          style: AppTextStyles.headline(
            context,
          ).copyWith(color: AppColors.white, fontSize: ResponsiveUtils.sp(context, 20)),
        ),
      ),
      body: CustomScrollView(
        slivers: [
          SliverFillRemaining(
            hasScrollBody: false,
            child: Column(
              children: [
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Stopwatch display
                        Container(
                          width: ResponsiveUtils.r(context, 220),
                          height: ResponsiveUtils.r(context, 220),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.primaryTeal,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primaryTeal.withValues(alpha: 0.3),
                                blurRadius: ResponsiveUtils.r(context, 20),
                                spreadRadius: ResponsiveUtils.r(context, 5),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.timer,
                                size: ResponsiveUtils.r(context, 32),
                                color: AppColors.white.withValues(alpha: 0.8),
                              ),
                              ResponsiveUtils.verticalSpace(context, 8),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: ResponsiveUtils.w(context, 16)),
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    _formatDuration(_elapsedSeconds),
                                    style: AppTextStyles.headline(context).copyWith(
                                      fontSize: ResponsiveUtils.sp(context, 42),
                                      color: AppColors.white,
                                      fontFeatures: const [FontFeature.tabularFigures()],
                                    ),
                                  ),
                                ),
                              ),
                              ResponsiveUtils.verticalSpace(context, 8),
                              Text(
                                _isRunning ? 'Washing...' : 'Paused',
                                style: AppTextStyles.body(
                                  context,
                                ).copyWith(
                                  color: AppColors.white, 
                                  fontSize: ResponsiveUtils.sp(context, 16)
                                ),
                              ),
                            ],
                          ),
                        ),
                        ResponsiveUtils.verticalSpace(context, 24),
                        // Pause/Resume Button
                        TextButton.icon(
                          onPressed: _isRunning ? _pauseStopwatch : _resumeStopwatch,
                          icon: Icon(
                            _isRunning
                                ? Icons.pause_circle_outline
                                : Icons.play_circle_outline,
                            color: AppColors.primaryTeal,
                            size: ResponsiveUtils.sp(context, 24),
                          ),
                          label: Text(
                            _isRunning ? 'Pause Timer' : 'Resume Timer',
                            style: TextStyle(
                              color: AppColors.primaryTeal,
                              fontSize: ResponsiveUtils.sp(context, 16),
                            ),
                          ),
                        ),
                        ResponsiveUtils.verticalSpace(context, 16),
                      ],
                    ),
                  ),
                ),
                Container(
                  width: MediaQuery.of(context).size.width,
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(ResponsiveUtils.r(context, 24)),
                      topRight: Radius.circular(ResponsiveUtils.r(context, 24)),
                    ),
                  ),
                  padding: EdgeInsets.all(ResponsiveUtils.w(context, 24)),
                  child: Column(
                    children: [
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(ResponsiveUtils.w(context, 16)),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(ResponsiveUtils.r(context, 16)),
                          border: Border.all(color: AppColors.lightGray.withValues(alpha: 0.2)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'JOB-${_job?.id}',
                                  style: AppTextStyles.subtitle(context).copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primaryTeal,
                                  ),
                                ),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: ResponsiveUtils.w(context, 10), vertical: ResponsiveUtils.h(context, 4)),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryTeal.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(ResponsiveUtils.r(context, 20)),
                                  ),
                                  child: Text(
                                    _job?.displayStatus ?? 'IN PROGRESS',
                                    style: AppTextStyles.caption(context).copyWith(
                                      color: AppColors.primaryTeal,
                                      fontWeight: FontWeight.bold,
                                      fontSize: ResponsiveUtils.sp(context, 10),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(vertical: ResponsiveUtils.h(context, 12)),
                              child: const Divider(height: 1),
                            ),
                            _buildInfoRow(
                              Icons.location_on_outlined,
                              'Location',
                              _job?.booking?.fullAddress ?? 'Unknown Location',
                            ),
                            ResponsiveUtils.verticalSpace(context, 12),
                            _buildInfoRow(
                              Icons.directions_car_outlined,
                              'Vehicle',
                              '${vehicle?.brandName} ${vehicle?.model} (${vehicle?.color})\nPlate: ${vehicle?.numberPlate}',
                            ),
                            ResponsiveUtils.verticalSpace(context, 12),
                            _buildInfoRow(
                              Icons.person_outline,
                              'Customer',
                              '${_job?.booking?.customer?.name ?? 'Unknown'}\n${_job?.booking?.customer?.phone ?? ''}',
                            ),
                            ResponsiveUtils.verticalSpace(context, 12),
                            _buildInfoRow(
                              Icons.list_alt_outlined,
                              'Services',
                              services.isNotEmpty
                                  ? services.map((s) => s.name).join(', ')
                                  : 'Car Wash Service',
                            ),
                            if (_job?.booking?.notes != null &&
                                _job!.booking!.notes!.isNotEmpty) ...[
                              ResponsiveUtils.verticalSpace(context, 12),
                              _buildInfoRow(
                                Icons.note_alt_outlined,
                                'Customer Notes',
                                _job!.booking!.notes!,
                              ),
                            ],
                            if (vehicle?.parkingNotes != null &&
                                vehicle!.parkingNotes!.isNotEmpty) ...[
                              ResponsiveUtils.verticalSpace(context, 12),
                              _buildInfoRow(
                                Icons.local_parking_outlined,
                                'Parking Notes',
                                vehicle!.parkingNotes!,
                              ),
                            ],
                          ],
                        ),
                      ),
                      ResponsiveUtils.verticalSpace(context, 20),
                      SizedBox(
                        width: double.infinity,
                        height: ResponsiveUtils.h(context, 56),
                        child: ElevatedButton(
                          onPressed: _finishWash,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.darkTeal,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(ResponsiveUtils.r(context, 12)),
                            ),
                          ),
                          child: Text(
                            'Take Photo & Finish Wash',
                            style: AppTextStyles.button(
                              context,
                            ).copyWith(color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: ResponsiveUtils.r(context, 20), color: AppColors.primaryTeal),
        ResponsiveUtils.horizontalSpace(context, 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTextStyles.caption(context).copyWith(
                  color: AppColors.lightGray,
                  fontWeight: FontWeight.w500,
                ),
              ),
              ResponsiveUtils.verticalSpace(context, 2),
              Text(
                value,
                style: AppTextStyles.body(context).copyWith(
                  color: AppColors.darkNavy,
                  fontSize: ResponsiveUtils.sp(context, 14),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
