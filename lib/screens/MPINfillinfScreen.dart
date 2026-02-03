import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/colors.dart';
import '../constants/text_styles.dart';
import '../models/job_model.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../utils/toast_utils.dart';
import '../utils/responsive_utils.dart';


class JobVerificationScreen extends StatefulWidget {
  const JobVerificationScreen({Key? key}) : super(key: key);

  @override
  State<JobVerificationScreen> createState() => _JobVerificationScreenState();
}

class _JobVerificationScreenState extends State<JobVerificationScreen> {
  final List<TextEditingController> _pinControllers =
      List.generate(4, (index) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(4, (index) => FocusNode());
  bool _isVerifying = false;
  Job? _job;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_job == null) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ?? {};
      if (args['job'] != null && args['job'] is Job) {
        _job = args['job'] as Job;
        
        // If the job is "lean" (missing booking info), fetch full details
        if (_job!.booking == null) {
          _fetchFullJobDetails();
        }
      }
    }
  }

  Future<void> _fetchFullJobDetails() async {
    final token = AuthService().token;
    if (token == null || _job == null) return;

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
    }
  }

  @override
  void dispose() {
    for (var controller in _pinControllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  bool _isPinComplete() {
    bool complete = _pinControllers.every((controller) => controller.text.isNotEmpty);
    return complete;
  }

  String _getEnteredPin() {
    return _pinControllers.map((c) => c.text).join();
  }

  Future<void> _verifyAndStart() async {
    if (!_isPinComplete()) {
      ToastUtils.showErrorToast(context, 'Please enter complete PIN');

      return;
    }

    final routeArgs = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ?? {};
    
    if (_job == null) {
      // Fallback: navigate without API call
      debugPrint('No job object, navigating directly');
      Navigator.pushNamed(
        context,
        '/job-arrival-photo',
        arguments: routeArgs,
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

    final otp = _getEnteredPin();
    final response = await ApiService().verifyStartOtp(
      jobId: _job!.id,
      otp: otp,
      token: token,
    );

    setState(() {
      _isVerifying = false;
    });

    if (response['success'] == true) {
      // OTP verified, navigate to photo upload screen
      if (mounted) {
        Navigator.pushNamed(
          context,
          '/job-arrival-photo',
          arguments: {
            ...routeArgs,
            'job': _job,
          },
        );
      }
    } else {
      if (mounted) {
        ToastUtils.showErrorToast(context, response['message'] ?? 'OTP verification failed');

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
          onPressed: () => Navigator.pushNamedAndRemoveUntil(
            context,
            '/employee-home',
            (route) => false,
          ),
        ),
        title: Text(
          'Job Verification',
          style: AppTextStyles.headline(context).copyWith(
            color: AppColors.white,
            fontSize: ResponsiveUtils.sp(context, 20), // AppBar size override
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(ResponsiveUtils.w(context, 24)),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.all(ResponsiveUtils.w(context, 24)),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(ResponsiveUtils.r(context, 16)),
                    border: Border.all(
                      color: AppColors.darkNavy,
                      width: ResponsiveUtils.w(context, 2),
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Enter Customer PIN',
                        style: AppTextStyles.headline(context).copyWith(
                          fontSize: ResponsiveUtils.sp(context, 20),
                          color: AppColors.darkNavy,
                        ),
                      ),
                      ResponsiveUtils.verticalSpace(context, 12),
                      Text(
                        'Ask the customer for the 4-digit PIN\nto start the wash.',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.body(context).copyWith(
                          color: AppColors.lightGray,
                        ),
                      ),
                      ResponsiveUtils.verticalSpace(context, 32),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: List.generate(
                          4,
                          (index) => SizedBox(
                            width: ResponsiveUtils.w(context, 60),
                            height: ResponsiveUtils.h(context, 60),
                            child: KeyboardListener(
                              focusNode: FocusNode(), // Node for listener
                              onKeyEvent: (event) {
                                if (event is KeyDownEvent &&
                                    event.logicalKey ==
                                        LogicalKeyboardKey.backspace) {
                                  if (_pinControllers[index].text.isEmpty &&
                                      index > 0) {
                                    _focusNodes[index - 1].requestFocus();
                                  }
                                }
                              },
                              child: TextField(
                                controller: _pinControllers[index],
                                focusNode: _focusNodes[index],
                                textAlign: TextAlign.center,
                                keyboardType: TextInputType.number,
                                maxLength: 1,
                                onChanged: (value) {
                                  if (value.isNotEmpty) {
                                    if (index < 3) {
                                      _focusNodes[index + 1].requestFocus();
                                    } else {
                                      // Last digit entered, dismiss keyboard
                                      _focusNodes[index].unfocus();
                                    }
                                  } else {
                                    // Value became empty
                                    if (index > 0) {
                                      _focusNodes[index - 1].requestFocus();
                                    }
                                  }
                                  setState(() {});
                                },
                                decoration: InputDecoration(
                                  counterText: '',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(ResponsiveUtils.r(context, 12)),
                                    borderSide: BorderSide(
                                      color: AppColors.darkNavy,
                                      width: ResponsiveUtils.w(context, 2),
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(ResponsiveUtils.r(context, 12)),
                                    borderSide: BorderSide(
                                      color: AppColors.darkNavy,
                                      width: ResponsiveUtils.w(context, 2),
                                    ),
                                  ),
                                ),
                                style: AppTextStyles.title(context).copyWith(
                                  fontSize: ResponsiveUtils.sp(context, 24),
                                  color: AppColors.darkNavy,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      ResponsiveUtils.verticalSpace(context, 32),
                      SizedBox(
                        width: double.infinity,
                        height: ResponsiveUtils.h(context, 56),
                        child: ElevatedButton(
                          onPressed: (_isPinComplete() && !_isVerifying)
                              ? _verifyAndStart
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.amber,
                            disabledBackgroundColor:
                                AppColors.amber.withOpacity(0.5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(ResponsiveUtils.r(context, 12)),
                            ),
                          ),
                          child: _isVerifying
                              ? SizedBox(
                                  width: ResponsiveUtils.w(context, 24),
                                  height: ResponsiveUtils.h(context, 24),
                                  child: CircularProgressIndicator(
                                    color: AppColors.darkNavy,
                                    strokeWidth: ResponsiveUtils.w(context, 2),
                                  ),
                                )
                              : Text(
                                  'Verify & Start Wash',
                                  style: AppTextStyles.button(context).copyWith(
                                    color: AppColors.darkNavy,
                                  ),
                                ),
                        ),
                      ),
                      ResponsiveUtils.verticalSpace(context, 16),
                      GestureDetector(
                        onTap: () {
                          ToastUtils.showSuccessToast(context, 'PIN resent');
        
                        },
                        child: Text(
                          'Resend PIN',
                          style: AppTextStyles.body(context).copyWith(
                            color: AppColors.primaryTeal,
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
      ),
    );
  }
}
