import 'package:flutter/material.dart';
import 'package:employeapplication/constants/colors.dart';

class JobCompletionProofScreen extends StatefulWidget {
  const JobCompletionProofScreen({Key? key}) : super(key: key);

  @override
  State<JobCompletionProofScreen> createState() =>
      _JobCompletionProofScreenState();
}

class _JobCompletionProofScreenState extends State<JobCompletionProofScreen> {
  bool _photoUploaded = false;

  @override
  Widget build(BuildContext context) {
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
              const Text(
                'Please take a clear photo of the clean\ncar as proof of completion.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.white,
                ),
              ),
              const SizedBox(height: 32),
              Container(
                height: 300,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: AppColors.darkNavy,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  color: AppColors.veryLightGray,
                ),
                child: _photoUploaded
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.check_circle,
                                color: AppColors.primaryTeal, size: 64),
                            const SizedBox(height: 16),
                            const Text(
                              'Photo Uploaded',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.darkNavy,
                              ),
                            ),
                            const SizedBox(height: 8),
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _photoUploaded = false;
                                });
                              },
                              child: const Text(
                                'Change Photo',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppColors.primaryTeal,
                                  fontWeight: FontWeight.bold,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    : GestureDetector(
                        onTap: () {
                          setState(() {
                            _photoUploaded = true;
                          });
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
              const SizedBox(height: 24),
              GestureDetector(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Skip Photo?'),
                      content:
                          const Text('Please provide a reason for skipping.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.pushNamed(context, '/job-completion-otp');
                          },
                          child: const Text('Skip'),
                        ),
                      ],
                    ),
                  );
                },
                child: const Text(
                  'Skip Photo (Requires Reason)',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.primaryTeal,
                    fontWeight: FontWeight.bold,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _photoUploaded
                      ? () {
                          Navigator.pushNamed(context, '/job-completion-otp');
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFC107),
                    disabledBackgroundColor:
                        const Color(0xFFFFC107).withOpacity(0.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Submit Job',
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
    );
  }
}
