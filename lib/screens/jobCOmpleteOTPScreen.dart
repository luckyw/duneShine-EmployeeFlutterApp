import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/colors.dart';
import '../models/job_model.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../utils/toast_utils.dart';


class JobCompletionOtpScreen extends StatefulWidget {
  const JobCompletionOtpScreen({Key? key}) : super(key: key);

  @override
  State<JobCompletionOtpScreen> createState() =>
      _JobCompletionOtpScreenState();
}

class _JobCompletionOtpScreenState extends State<JobCompletionOtpScreen> {
  final List<TextEditingController> _otpControllers =
      List.generate(4, (index) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(4, (index) => FocusNode());
  bool _isVerifying = false;
  Job? _job;

  @override
  void initState() {
    super.initState();
    for (var controller in _otpControllers) {
      controller.addListener(() {
        setState(() {});
      });
    }
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

  @override
  void dispose() {
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  bool _isOtpComplete() {
    return _otpControllers.every((controller) => controller.text.isNotEmpty);
  }

  String _getEnteredOtp() {
    return _otpControllers.map((c) => c.text).join();
  }

  void _onOtpInput(int index, String value) {
    if (value.isNotEmpty && index < 3) {
      _focusNodes[index + 1].requestFocus();
    }
  }

  Future<void> _verifyAndComplete() async {
    if (!_isOtpComplete()) {
      ToastUtils.showErrorToast(context, 'Please enter complete OTP');

      return;
    }

    final routeArgs = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ?? {};
    
    // Get job ID
    int? jobId;
    if (_job != null) {
      jobId = _job!.id;
    } else {
      final jobIdStr = routeArgs['jobId']?.toString().replaceAll('JOB-', '') ?? '';
      jobId = int.tryParse(jobIdStr);
    }

    if (jobId == null) {
      // Fallback: navigate without API call
      debugPrint('No valid job ID, navigating directly');
      Navigator.pushNamed(
        context,
        '/job-completed',
        arguments: {
          'employeeName': routeArgs['employeeName'] ?? 'Ahmed',
          'earnedAmount': (routeArgs['earnedAmount'] ?? 120.0).toDouble(),
          'jobId': routeArgs['jobId'] ?? 'JOB-56392',
        },
      );
      return;
    }

    final token = AuthService().token;
    if (token == null) {
      ToastUtils.showErrorToast(context, 'Not authenticated. Please login again.');

      return;
    }

    setState(() {
      _isVerifying = true;
    });

    final otp = _getEnteredOtp();
    final response = await ApiService().completeJob(
      jobId: jobId,
      otp: otp,
      token: token,
    );

    setState(() {
      _isVerifying = false;
    });

    if (response['success'] == true) {
      // Job completed, navigate to success screen
      if (mounted) {
        Navigator.pushNamed(
          context,
          '/job-completed',
          arguments: {
            'employeeName': routeArgs['employeeName'] ?? AuthService().employeeName,
            'earnedAmount': (routeArgs['earnedAmount'] ?? 120.0).toDouble(),
            'jobId': routeArgs['jobId'] ?? 'JOB-$jobId',
            'job': _job,
            'completeResponse': response['data'],
          },
        );
      }
    } else {
      // Show error snackbar
      if (mounted) {
        ToastUtils.showErrorToast(context, response['message'] ?? 'Failed to complete job');

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
          'Job Completion',
          style: TextStyle(
            color: AppColors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.darkNavy,
                    width: 2,
                  ),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Enter Customer\nOTP',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.darkNavy,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Ask for the 4-digit OTP to finalize\nthe job.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.lightGray,
                      ),
                    ),
                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(
                        4,
                        (index) => SizedBox(
                          width: 60,
                          height: 60,
                          child: KeyboardListener(
                            focusNode: FocusNode(),
                            onKeyEvent: (event) {
                              if (event is KeyDownEvent &&
                                  event.logicalKey == LogicalKeyboardKey.backspace) {
                                if (index > 0 && _otpControllers[index].text.isEmpty) {
                                  _otpControllers[index - 1].clear();
                                  _focusNodes[index - 1].requestFocus();
                                }
                              }
                            },
                            child: TextField(
                              controller: _otpControllers[index],
                              focusNode: _focusNodes[index],
                              textAlign: TextAlign.center,
                              keyboardType: TextInputType.number,
                              maxLength: 1,
                              onChanged: (value) => _onOtpInput(index, value),
                              decoration: InputDecoration(
                                counterText: '',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: AppColors.darkNavy,
                                    width: 2,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: AppColors.darkNavy,
                                    width: 2,
                                  ),
                                ),
                              ),
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppColors.darkNavy,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: (_isOtpComplete() && !_isVerifying)
                            ? _verifyAndComplete
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.darkTeal,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: AppColors.darkTeal.withOpacity(0.4),
                          disabledForegroundColor: Colors.white.withOpacity(0.6),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isVerifying
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Verify & Complete Job',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: () {
                        ToastUtils.showSuccessToast(context, 'OTP resent');

                      },
                      child: const Text(
                        'Resend OTP',
                        style: TextStyle(
                          color: AppColors.primaryTeal,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
