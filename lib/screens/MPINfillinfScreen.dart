import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/colors.dart';
import '../constants/text_styles.dart';
import '../models/job_model.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../utils/toast_utils.dart';
import '../utils/responsive_utils.dart';
import 'package:url_launcher/url_launcher.dart';

class JobVerificationScreen extends StatefulWidget {
  const JobVerificationScreen({Key? key}) : super(key: key);

  @override
  State<JobVerificationScreen> createState() => _JobVerificationScreenState();
}

class _JobVerificationScreenState extends State<JobVerificationScreen> {
  final List<TextEditingController> _pinControllers = List.generate(
    4,
    (index) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(4, (index) => FocusNode());
  bool _isVerifying = false;
  Job? _job;

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

  Future<void> _callCustomer() async {
    final phone = _job?.booking?.customer?.phone;
    if (phone != null && phone.isNotEmpty) {
      final Uri launchUri = Uri(scheme: 'tel', path: phone);
      try {
        if (await canLaunchUrl(launchUri)) {
          await launchUrl(launchUri);
        } else {
          if (mounted) {
            ToastUtils.showErrorToast(context, 'Could not launch dialer');
          }
        }
      } catch (e) {
        if (mounted) {
          ToastUtils.showErrorToast(context, 'Error launching dialer: $e');
        }
      }
    } else {
      ToastUtils.showErrorToast(context, 'Customer phone number not found');
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
    bool complete = _pinControllers.every(
      (controller) => controller.text.isNotEmpty,
    );
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

    final routeArgs =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ??
        {};

    if (_job == null) {
      // Fallback: navigate without API call
      debugPrint('No job object, navigating directly');
      Navigator.pushNamed(context, '/job-arrival-photo', arguments: routeArgs);
      return;
    }

    final token = AuthService().token;
    if (token == null) {
      ToastUtils.showErrorToast(
        context,
        'Not authenticated. Please login again.',
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

    setState(() {
      _isVerifying = false;
    });

    if (response['success'] == true) {
      // OTP verified, navigate to photo upload screen
      if (mounted) {
        Navigator.pushNamed(
          context,
          '/job-arrival-photo',
          arguments: {...routeArgs, 'job': _job},
        );
      }
    } else {
      if (mounted) {
        ToastUtils.showErrorToast(
          context,
          response['message'] ?? 'OTP verification failed',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Premium Status Bar Overlay
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);

    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      body: Stack(
        children: [
          // 1. Immersive Gradient Background
          Container(
            height: ResponsiveUtils.h(context, 320),
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF00695C), // Deep Teal
                  Color(0xFF00897B), // Rich Teal
                  Color(0xFF26A69A), // Lighter Teal
                ],
              ),
              borderRadius: BorderRadius.vertical(
                bottom: Radius.circular(ResponsiveUtils.r(context, 40)),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryTeal.withOpacity(0.3),
                  blurRadius: 20,
                  offset: Offset(0, 10),
                ),
              ],
            ),
          ),

          // 2. Abstract Geometric Accents (Glassmorphism feel)
          Positioned(
            top: -100,
            right: -80,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.05),
              ),
            ),
          ),
          Positioned(
            top: 50,
            left: -40,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.08),
              ),
            ),
          ),

          // 3. Main Content
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  // Custom Navigation Bar
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: ResponsiveUtils.w(context, 20),
                      vertical: ResponsiveUtils.h(context, 10),
                    ),
                    child: Row(
                      children: [
                        _buildBackButton(context),
                        Expanded(
                          child: Text(
                            'Security Verification',
                            textAlign: TextAlign.center,
                            style: AppTextStyles.headline(context).copyWith(
                              color: Colors.white,
                              fontSize: ResponsiveUtils.sp(context, 18),
                              letterSpacing: 0.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: ResponsiveUtils.w(context, 44),
                        ), // Balance back button
                      ],
                    ),
                  ),

                  ResponsiveUtils.verticalSpace(context, 40),

                  // Verification Card
                  Container(
                    margin: EdgeInsets.symmetric(
                      horizontal: ResponsiveUtils.w(context, 24),
                    ),
                    padding: EdgeInsets.symmetric(
                      horizontal: ResponsiveUtils.w(context, 16), // Reduced padding for more space
                      vertical: ResponsiveUtils.h(context, 40),
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(
                        ResponsiveUtils.r(context, 28),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 40,
                          offset: const Offset(0, 16),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Lock Icon
                        Container(
                          padding: EdgeInsets.all(
                            ResponsiveUtils.r(context, 18),
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryTeal.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.lock_person_rounded,
                            size: ResponsiveUtils.r(context, 36),
                            color: AppColors.primaryTeal,
                          ),
                        ),
                        ResponsiveUtils.verticalSpace(context, 24),

                        Text(
                          'Enter Customer PIN',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.headline(context).copyWith(
                            fontSize: ResponsiveUtils.sp(context, 24),
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1E293B), // Slate 800
                          ),
                        ),
                        ResponsiveUtils.verticalSpace(context, 36),

                        // PIN Input Area
                        _buildPinRow(),

                        ResponsiveUtils.verticalSpace(context, 36),

                        // Action Buttons
                        _buildVerifyButton(),

                        // Call Customer Section
                        if (_job?.booking?.customer?.phone != null &&
                            _job!.booking!.customer!.phone.isNotEmpty) ...[
                          ResponsiveUtils.verticalSpace(context, 24),
                          _buildDivider(),
                          ResponsiveUtils.verticalSpace(context, 24),
                          _buildCallCustomerButton(),
                        ],
                      ],
                    ),
                  ),
                  
                  ResponsiveUtils.verticalSpace(context, 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackButton(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pushNamedAndRemoveUntil(
        context,
        '/employee-home',
        (route) => false,
      ),
      child: Container(
        width: ResponsiveUtils.w(context, 44),
        height: ResponsiveUtils.w(context, 44),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(ResponsiveUtils.r(context, 12)),
          border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
        ),
        child: Icon(
          Icons.arrow_back_ios_new_rounded,
          color: Colors.white,
          size: ResponsiveUtils.r(context, 18),
        ),
      ),
    );
  }

  Widget _buildPinRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(
        4,
        (index) => SizedBox(
          width: ResponsiveUtils.w(context, 68), // Increased width
          height: ResponsiveUtils.h(context, 75), // Increased height
          child: KeyboardListener(
            focusNode: FocusNode(),
            onKeyEvent: (event) {
              if (event is KeyDownEvent &&
                  event.logicalKey == LogicalKeyboardKey.backspace) {
                if (_pinControllers[index].text.isEmpty && index > 0) {
                  _focusNodes[index - 1].requestFocus();
                }
              }
            },
            child: TextField(
              controller: _pinControllers[index],
              focusNode: _focusNodes[index],
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              maxLength: 1,
              onChanged: (value) {
                if (value.isNotEmpty) {
                  if (index < 3) {
                    _focusNodes[index + 1].requestFocus();
                  } else {
                    _focusNodes[index].unfocus();
                  }
                } else if (index > 0) {
                  _focusNodes[index - 1].requestFocus();
                }
                setState(() {});
              },
              decoration: InputDecoration(
                contentPadding: EdgeInsets.zero, // Ensure content isn't clipped
                counterText: '',
                filled: true,
                fillColor: _pinControllers[index].text.isNotEmpty
                    ? AppColors.primaryTeal.withOpacity(0.08)
                    : Color(0xFFF1F5F9), // Slate 100
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(
                    ResponsiveUtils.r(context, 16),
                  ),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(
                    ResponsiveUtils.r(context, 16),
                  ),
                  borderSide: BorderSide(color: Colors.transparent),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(
                    ResponsiveUtils.r(context, 16),
                  ),
                  borderSide: BorderSide(
                    color: AppColors.primaryTeal,
                    width: 2,
                  ),
                ),
              ),
              style: AppTextStyles.headline(context).copyWith(
                fontSize: ResponsiveUtils.sp(context, 28), // Slightly larger font
                color: Color(0xFF1E293B),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVerifyButton() {
    bool isEnabled = _isPinComplete() && !_isVerifying;

    return Container(
      width: double.infinity,
      height: ResponsiveUtils.h(context, 54),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(ResponsiveUtils.r(context, 16)),
        boxShadow: isEnabled
            ? [
                BoxShadow(
                  color: AppColors.primaryTeal.withOpacity(0.4),
                  blurRadius: 15,
                  offset: Offset(0, 8),
                ),
              ]
            : [],
      ),
      child: ElevatedButton(
        onPressed: isEnabled ? _verifyAndStart : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryTeal,
          disabledBackgroundColor: Color(0xFFE2E8F0), // Slate 200
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(ResponsiveUtils.r(context, 16)),
          ),
          elevation: 0, // Handled by Container
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
                'Verify & Start Wash',
                style: AppTextStyles.button(context).copyWith(
                  color: isEnabled ? Colors.white : Color(0xFF94A3B8),
                  fontSize: ResponsiveUtils.sp(context, 16),
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
      ),
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(child: Container(height: 1, color: Color(0xFFE2E8F0))),
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: ResponsiveUtils.w(context, 12),
          ),
          child: Text(
            'OR',
            style: AppTextStyles.body(context).copyWith(
              color: Color(0xFF94A3B8),
              fontSize: ResponsiveUtils.sp(context, 12),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(child: Container(height: 1, color: Color(0xFFE2E8F0))),
      ],
    );
  }

  Widget _buildCallCustomerButton() {
    return Container(
      width: double.infinity,
      height: ResponsiveUtils.h(context, 50),
      child: OutlinedButton.icon(
        onPressed: _callCustomer,
        icon: Icon(
          Icons.phone_in_talk_rounded,
          size: ResponsiveUtils.r(context, 20),
          color: AppColors.primaryTeal,
        ),
        label: Text(
          'Call Customer',
          style: AppTextStyles.body(context).copyWith(
            color: AppColors.primaryTeal,
            fontWeight: FontWeight.w700,
            fontSize: ResponsiveUtils.sp(context, 15),
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: BorderSide(
            color: AppColors.primaryTeal.withOpacity(0.3),
            width: 1.5,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(ResponsiveUtils.r(context, 16)),
          ),
          backgroundColor: AppColors.primaryTeal.withOpacity(0.04),
        ),
      ),
    );
  }
}
