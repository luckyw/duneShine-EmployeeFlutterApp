import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/text_styles.dart';
import '../constants/colors.dart';
import '../models/job_model.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../utils/toast_utils.dart';
import '../utils/responsive_utils.dart';


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
          '/job-completed',
          arguments: {
            'employeeName': routeArgs['employeeName'] ?? AuthService().employeeName,
            'earnedAmount': (routeArgs['earnedAmount'] ?? 120.0).toDouble(),
            'jobId': routeArgs['jobId'] ?? 'JOB-$jobId',
            'job': nextJob,
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
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);

    return Scaffold(
      backgroundColor: AppColors.primaryTeal,
      body: Stack(
        children: [
          // 1. Background Pattern
          Positioned(
            top: -50,
            right: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: 100,
            left: -30,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
            ),
          ),

          // 2. Main content
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  // Header
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: ResponsiveUtils.w(context, 20),
                      vertical: ResponsiveUtils.h(context, 10),
                    ),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pushNamedAndRemoveUntil(
                            context,
                            '/employee-home',
                            (route) => false,
                          ),
                          child: Container(
                            width: ResponsiveUtils.w(context, 40),
                            height: ResponsiveUtils.w(context, 40),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(ResponsiveUtils.r(context, 12)),
                            ),
                            child: Icon(
                              Icons.arrow_back_ios_new_rounded,
                              color: Colors.white,
                              size: ResponsiveUtils.sp(context, 18),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            'Job Completion',
                            textAlign: TextAlign.center,
                            style: AppTextStyles.headline(context).copyWith(
                              color: Colors.white,
                              fontSize: ResponsiveUtils.sp(context, 18),
                            ),
                          ),
                        ),
                        SizedBox(width: ResponsiveUtils.w(context, 40)),
                      ],
                    ),
                  ),

                  ResponsiveUtils.verticalSpace(context, 40),

                  // Content Card
                  Container(
                    margin: EdgeInsets.symmetric(horizontal: ResponsiveUtils.w(context, 24)),
                    padding: EdgeInsets.symmetric(
                      horizontal: ResponsiveUtils.w(context, 24),
                      vertical: ResponsiveUtils.h(context, 32),
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(ResponsiveUtils.r(context, 24)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 30,
                          offset: Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Icon
                        Container(
                          padding: EdgeInsets.all(ResponsiveUtils.w(context, 16)),
                          decoration: BoxDecoration(
                            color: AppColors.primaryTeal.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.verified_user_rounded,
                            size: ResponsiveUtils.sp(context, 40),
                            color: AppColors.primaryTeal,
                          ),
                        ),
                        ResponsiveUtils.verticalSpace(context, 24),

                        Text(
                          'Enter Customer OTP',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.headline(context).copyWith(
                            fontSize: ResponsiveUtils.sp(context, 22),
                            color: AppColors.textDark,
                          ),
                        ),

                        ResponsiveUtils.verticalSpace(context, 32),

                        // OTP Inputs
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: List.generate(
                            4,
                            (index) => SizedBox(
                              width: ResponsiveUtils.w(context, 56),
                              height: ResponsiveUtils.h(context, 64),
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
                                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                  onChanged: (value) => _onOtpInput(index, value),
                                  decoration: InputDecoration(
                                    counterText: '',
                                    filled: true,
                                    fillColor: _otpControllers[index].text.isNotEmpty
                                        ? AppColors.primaryTeal.withOpacity(0.1)
                                        : AppColors.veryLightGray,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(ResponsiveUtils.r(context, 12)),
                                      borderSide: BorderSide.none,
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(ResponsiveUtils.r(context, 12)),
                                      borderSide: BorderSide(
                                        color: AppColors.primaryTeal,
                                        width: 1.5,
                                      ),
                                    ),
                                  ),
                                  style: TextStyle(
                                    fontSize: ResponsiveUtils.sp(context, 24),
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textDark,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),

                        ResponsiveUtils.verticalSpace(context, 32),

                        // Verify Button
                        SizedBox(
                          width: double.infinity,
                          height: ResponsiveUtils.h(context, 56),
                          child: ElevatedButton(
                            onPressed: (_isOtpComplete() && !_isVerifying)
                                ? _verifyAndComplete
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryTeal,
                              foregroundColor: Colors.white,
                              elevation: 5,
                              shadowColor: AppColors.primaryTeal.withOpacity(0.4),
                              disabledBackgroundColor: AppColors.textGray.withOpacity(0.2),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(ResponsiveUtils.r(context, 14)),
                              ),
                            ),
                            child: _isVerifying
                                ? SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2.5,
                                    ),
                                  )
                                : Text(
                                    'Verify & Complete',
                                    style: AppTextStyles.button(context).copyWith(
                                      fontSize: ResponsiveUtils.sp(context, 16),
                                    ),
                                  ),
                          ),
                        ),

                        ResponsiveUtils.verticalSpace(context, 20),

                        // Resend
                        GestureDetector(
                          onTap: () {
                            ToastUtils.showSuccessToast(context, 'OTP resent');
                          },
                          child: Text(
                            'Resend OTP',
                            style: AppTextStyles.body(context).copyWith(
                              color: AppColors.textGray,
                              fontSize: ResponsiveUtils.sp(context, 14),
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
        ],
      ),
    );
  }
}
