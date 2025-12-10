import 'package:flutter/material.dart';
import '../constants/colors.dart';

class JobDetailsScreen extends StatefulWidget {
  const JobDetailsScreen({Key? key}) : super(key: key);

  @override
  State<JobDetailsScreen> createState() => _JobDetailsScreenState();
}

class _JobDetailsScreenState extends State<JobDetailsScreen> {
  bool _photoUploaded = false;

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ?? {};
    final String jobId = args['jobId'] ?? 'JOB-56392';
    final String carModel = args['carModel'] ?? 'Kia Stinger';
    final String carColor = args['carColor'] ?? 'Blue';
    final String employeeName = args['employeeName'] ?? 'Ahmed';
    final double earnedAmount = (args['earnedAmount'] ?? 120.0).toDouble();

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A3A52),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Job Details',
          style: TextStyle(
            color: AppColors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.veryLightGray,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.directions_car,
                            color: AppColors.gold, size: 32),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$carModel ($carColor)',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.darkNavy,
                              ),
                            ),
                            Text(
                              'Plate: $jobId',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.lightGray,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.lightGold,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Premium Wash',
                        style: TextStyle(
                          color: AppColors.darkNavy,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Tasks for Today',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryTeal,
                ),
              ),
              const SizedBox(height: 12),
              _buildTaskItem('Exterior Foam Wash'),
              _buildTaskItem('Tyre Polishing'),
              _buildTaskItem('Window Cleaning'),
              const SizedBox(height: 24),
              const Text(
                'Vehicle Condition',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkNavy,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Take a photo of the car before starting.',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.lightGray,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                height: 200,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: AppColors.lightGray,
                    style: BorderStyle.solid,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  color: AppColors.veryLightGray,
                ),
                child: _photoUploaded
                    ? Center(
                        child: Image.asset('assets/placeholder.png'),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _photoUploaded = true;
                              });
                            },
                            child: const Icon(
                              Icons.camera_alt,
                              size: 48,
                              color: AppColors.gold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Tap to Upload Photo',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.lightGray,
                            ),
                          ),
                        ],
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
                      '/navigate-to-job',
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
                  child: const Text(
                    'Navigate to Job',
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
    );
  }

  Widget _buildTaskItem(String task) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          const Icon(Icons.check_circle,
              color: AppColors.primaryTeal, size: 24),
          const SizedBox(width: 12),
          Text(
            task,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.darkNavy,
            ),
          ),
        ],
      ),
    );
  }
}
