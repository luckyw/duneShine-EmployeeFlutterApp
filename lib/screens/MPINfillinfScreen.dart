import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/colors.dart';
import '../constants/text_styles.dart';
import '../models/job_model.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter complete PIN'),
          backgroundColor: Colors.red,
        ),
      );
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Not authenticated. Please login again.')),
      );
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
    debugPrint('Verify OTP response: $response');

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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'OTP verification failed'),
            backgroundColor: AppColors.error,
          ),
        );
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
        title: Text(
          'Job Verification',
          style: AppTextStyles.headline(context).copyWith(
            color: AppColors.white,
            fontSize: 20, // AppBar size override
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
                    Text(
                      'Enter Customer PIN',
                      style: AppTextStyles.headline(context).copyWith(
                        fontSize: 20,
                        color: AppColors.darkNavy,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Ask the customer for the 4-digit PIN\nto start the wash.',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.body(context).copyWith(
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
                              style: AppTextStyles.title(context).copyWith(
                                fontSize: 24,
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
                        onPressed: (_isPinComplete() && !_isVerifying)
                            ? _verifyAndStart
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.amber,
                          disabledBackgroundColor:
                              AppColors.amber.withOpacity(0.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isVerifying
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: AppColors.darkNavy,
                                  strokeWidth: 2,
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
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('PIN resent')),
                        );
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
    );
  }
}
