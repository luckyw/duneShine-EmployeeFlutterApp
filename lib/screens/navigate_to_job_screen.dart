import 'package:flutter/material.dart';
import '../constants/colors.dart';

class NavigateToJobScreen extends StatefulWidget {
  const NavigateToJobScreen({Key? key}) : super(key: key);

  @override
  State<NavigateToJobScreen> createState() => _NavigateToJobScreenState();
}

class _NavigateToJobScreenState extends State<NavigateToJobScreen> {
  bool _hasArrived = false;

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
        backgroundColor: const Color(0xFF1A3A52),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Navigate to Job',
          style: TextStyle(
            color: AppColors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Stack(
        children: [
          Container(
            color: const Color(0xFFF5F5F5),
            child: Column(
              children: [
                Expanded(
                  child: Container(
                    color: const Color(0xFFE8E8E8),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.map,
                            size: 80,
                            color: AppColors.lightGray,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Google Maps Integration',
                            style: TextStyle(
                              fontSize: 16,
                              color: AppColors.lightGray,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
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
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                  ),
                ],
              ),
              padding: const EdgeInsets.all(24),
              child: _hasArrived
                  ? Column(
                      children: [
                        const Text(
                          'You Have Arrived',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.darkNavy,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Ready to start the job',
                          style: TextStyle(
                            fontSize: 14,
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
                                '/job-arrival-photo',
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
                              'Proceed to Job',
                              style: TextStyle(
                                color: AppColors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'En Route to Building A',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.darkNavy,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Icon(Icons.directions_car,
                                color: AppColors.primaryTeal, size: 20),
                            const SizedBox(width: 8),
                            const Text(
                              'Estimated Time: 12 mins',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.darkNavy,
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
                            child: const Text(
                              'I Have Arrived',
                              style: TextStyle(
                                color: AppColors.darkNavy,
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
        ],
      ),
    );
  }
}
