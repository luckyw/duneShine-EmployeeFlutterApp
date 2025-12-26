import 'package:flutter/material.dart';
import 'dart:async';

import '../constants/colors.dart';
import '../constants/text_styles.dart';
import '../models/job_model.dart';

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
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ?? {};
      if (args['job'] != null && args['job'] is Job) {
        _job = args['job'] as Job;
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
    final routeArgs = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ?? {};
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
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Wash in Progress',
          style: AppTextStyles.headline(context).copyWith(
            color: AppColors.white,
            fontSize: 20,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Stopwatch display
                  Container(
                    width: 220,
                    height: 220,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primaryTeal,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryTeal.withValues(alpha: 0.3),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.timer,
                          size: 32,
                          color: AppColors.white.withValues(alpha: 0.8),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _formatDuration(_elapsedSeconds),
                          style: AppTextStyles.headline(context).copyWith(
                            fontSize: 42,
                            color: AppColors.white,
                            fontFeatures: const [
                              FontFeature.tabularFigures()
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _isRunning ? 'Washing...' : 'Paused',
                          style: AppTextStyles.body(context).copyWith(
                            color: AppColors.white,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Pause/Resume Button
                  TextButton.icon(
                    onPressed: _isRunning ? _pauseStopwatch : _resumeStopwatch,
                    icon: Icon(
                      _isRunning ? Icons.pause_circle_outline : Icons.play_circle_outline,
                      color: AppColors.primaryTeal,
                    ),
                    label: Text(
                      _isRunning ? 'Pause Timer' : 'Resume Timer',
                      style: TextStyle(color: AppColors.primaryTeal),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            width: MediaQuery.of(context).size.width,
            decoration: const BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.veryLightGray,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Job Details',
                        style: AppTextStyles.subtitle(context).copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.darkNavy,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        vehicle?.displayName ?? 'Unknown Vehicle',
                        style: AppTextStyles.body(context).copyWith(
                          color: AppColors.darkNavy,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        services.isNotEmpty 
                            ? services.map((s) => s.name).join(', ')
                            : 'Car Wash Service',
                        style: AppTextStyles.caption(context).copyWith(
                          color: AppColors.lightGray,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _finishWash,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.darkTeal,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Take Photo & Finish Wash',
                      style: AppTextStyles.button(context).copyWith(
                        color: Colors.white,
                      ),
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
}
