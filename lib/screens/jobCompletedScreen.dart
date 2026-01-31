import 'package:flutter/material.dart';
import '../constants/colors.dart';

import '../models/job_model.dart';

class JobCompletedScreen extends StatefulWidget {
  final String employeeName;
  final double earnedAmount;
  final String jobId;
  final Job? job;

  const JobCompletedScreen({
    Key? key,
    required this.employeeName,
    required this.earnedAmount,
    required this.jobId,
    this.job,
  }) : super(key: key);

  @override
  State<JobCompletedScreen> createState() => _JobCompletedScreenState();
}

class _JobCompletedScreenState extends State<JobCompletedScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _backToHome(BuildContext context) {
    Navigator.pushNamedAndRemoveUntil(
      context,
      '/employee-home',
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _backToHome(context);
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.white,
        body: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ScaleTransition(
                    scale: Tween<double>(begin: 0, end: 1).animate(
                      CurvedAnimation(
                        parent: _animationController,
                        curve: Curves.elasticOut,
                      ),
                    ),
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.success.withOpacity(0.1),
                      ),
                      child: const Icon(
                        Icons.check_circle,
                        size: 80,
                        color: AppColors.success,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'Job Completed!',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkNavy,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Great work, ${widget.employeeName}!',
                    style: const TextStyle(
                      fontSize: 16,
                      color: AppColors.lightGray,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.lightGold),
                      borderRadius: BorderRadius.circular(16),
                      color: AppColors.veryLightGray,
                    ),
                    child: Column(
                      children: [
                        _buildResultRow('Job ID', widget.jobId),
                        _buildResultRow('Employee', widget.employeeName),
                        if (widget.job?.booking?.vehicle != null)
                          _buildResultRow('Vehicle', widget.job!.booking!.vehicle!.displayName),
                        if (widget.job?.booking != null)
                          _buildResultRow('Location', widget.job!.booking!.locationName),
                        if (widget.job?.booking?.servicesPayload.isNotEmpty == true)
                          _buildResultRow('Services', widget.job!.booking!.servicesPayload.map((s) => s.name).join(', ')),
                        _buildResultRow('Amount Earned', 'AED ${widget.earnedAmount.toStringAsFixed(2)}'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 48),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () => _backToHome(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.darkTeal,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Back to Home',
                        style: TextStyle(
                          color: AppColors.white,
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
        ),
      ),
    );
  }

  Widget _buildResultRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.lightGray,
              fontSize: 14,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: AppColors.darkNavy,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

