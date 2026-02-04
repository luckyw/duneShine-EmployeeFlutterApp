import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/colors.dart';
import '../constants/text_styles.dart';
import '../utils/toast_utils.dart';
import '../utils/responsive_utils.dart';


class OtpVerificationScreen extends StatefulWidget {
  const OtpVerificationScreen({Key? key}) : super(key: key);

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  bool _isLoading = false;
  int _resendTimer = 30;
  Timer? _timer;
  String? _phoneNumber;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    _phoneNumber = args?['phoneNumber'] ?? '+971 XXXXXXXX';
  }

  void _startResendTimer() {
    _resendTimer = 30;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendTimer > 0) {
        setState(() {
          _resendTimer--;
        });
      } else {
        timer.cancel();
      }
    });
  }

  void _resendOtp() {
    if (_resendTimer == 0) {
      // Simulate resend OTP
      ToastUtils.showSuccessToast(context, 'OTP resent successfully');

      _startResendTimer();
    }
  }

  void _verifyOtp() async {
    String otp = _controllers.map((c) => c.text).join();
    if (otp.length != 6) {
      ToastUtils.showErrorToast(context, 'Please enter complete OTP');

      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Simulate API call
    await Future.delayed(const Duration(seconds: 1));

    setState(() {
      _isLoading = false;
    });

    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/employee-home',
        (route) => false,
      );
    }
  }

  void _onOtpChanged(String value, int index) {
    if (value.length == 1 && index < 5) {
      _focusNodes[index + 1].requestFocus();
    }
    
    // Auto verify when all digits entered
    if (index == 5 && value.isNotEmpty) {
      String otp = _controllers.map((c) => c.text).join();
      if (otp.length == 6) {
        _verifyOtp();
      }
    }
  }

  void _onKeyPress(RawKeyEvent event, int index) {
    if (event is RawKeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.backspace &&
        _controllers[index].text.isEmpty &&
        index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Premium Status Bar
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);

    return Scaffold(
      backgroundColor: AppColors.darkNavy, // Fallback
      body: Stack(
        children: [
          // 1. Immersive Gradient Background
          Container(
            width: double.infinity,
            height: double.infinity,
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
            ),
          ),

          // 2. Abstract Geometric Accents (Glassmorphism)
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
            bottom: -50,
            left: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.05),
              ),
            ),
          ),

          // 3. Main Content with Entrance Animation
          SafeArea(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOutQuart,
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: Transform.translate(
                    offset: Offset(0, 30 * (1 - value)),
                    child: child,
                  ),
                );
              },
              child: Column(
                children: [
                  // Custom AppBar
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: ResponsiveUtils.w(context, 16),
                      vertical: ResponsiveUtils.h(context, 8),
                    ),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            width: ResponsiveUtils.w(context, 44),
                            height: ResponsiveUtils.w(context, 44),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(ResponsiveUtils.r(context, 12)),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.2),
                                width: 1,
                              ),
                            ),
                            child: Icon(
                              Icons.arrow_back_ios_new_rounded,
                              color: Colors.white,
                              size: ResponsiveUtils.r(context, 18),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  Expanded(
                    child: SingleChildScrollView(
                      physics: BouncingScrollPhysics(),
                      padding: EdgeInsets.symmetric(
                        horizontal: ResponsiveUtils.w(context, 24),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ResponsiveUtils.verticalSpace(context, 20),
                          
                          // Hero Content
                          Container(
                            padding: EdgeInsets.all(ResponsiveUtils.r(context, 16)),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.lock_open_rounded,
                              size: ResponsiveUtils.r(context, 40),
                              color: Colors.white,
                            ),
                          ),
                          ResponsiveUtils.verticalSpace(context, 24),

                          Text(
                            'Verify Authentication',
                            style: AppTextStyles.headline(context).copyWith(
                              color: Colors.white,
                              fontSize: ResponsiveUtils.sp(context, 28),
                            ),
                          ),
                          ResponsiveUtils.verticalSpace(context, 12),
                          Text(
                            'Enter the 6-digit code sent to',
                            style: AppTextStyles.body(context).copyWith(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: ResponsiveUtils.sp(context, 16),
                            ),
                          ),
                          ResponsiveUtils.verticalSpace(context, 4),
                          Text(
                            _phoneNumber ?? 'Unknown Number',
                            style: AppTextStyles.title(context).copyWith(
                              color: Colors.white,
                              fontSize: ResponsiveUtils.sp(context, 18),
                              letterSpacing: 0.5,
                            ),
                          ),

                          ResponsiveUtils.verticalSpace(context, 48),

                          // OTP Fields
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: List.generate(6, (index) {
                              return SizedBox(
                                width: ResponsiveUtils.w(context, 48),
                                height: ResponsiveUtils.h(context, 64),
                                child: RawKeyboardListener(
                                  focusNode: FocusNode(),
                                  onKey: (event) => _onKeyPress(event, index),
                                  child: TextFormField(
                                    controller: _controllers[index],
                                    focusNode: _focusNodes[index],
                                    keyboardType: TextInputType.number,
                                    textAlign: TextAlign.center,
                                    maxLength: 1,
                                    style: AppTextStyles.headline(context).copyWith(
                                      color: Colors.white,
                                      fontSize: ResponsiveUtils.sp(context, 24),
                                    ),
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                    ],
                                    decoration: InputDecoration(
                                      counterText: '',
                                      filled: true,
                                      fillColor: _controllers[index].text.isNotEmpty
                                          ? Colors.white.withOpacity(0.2)
                                          : Colors.white.withOpacity(0.1),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(ResponsiveUtils.r(context, 16)),
                                        borderSide: BorderSide(
                                          color: Colors.white.withOpacity(0.1),
                                        ),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(ResponsiveUtils.r(context, 16)),
                                        borderSide: BorderSide(
                                          color: Colors.white.withOpacity(0.1),
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(ResponsiveUtils.r(context, 16)),
                                        borderSide: BorderSide(
                                          color: Colors.white,
                                          width: 1.5,
                                        ),
                                      ),
                                    ),
                                    onChanged: (value) => _onOtpChanged(value, index),
                                  ),
                                ),
                              );
                            }),
                          ),

                          ResponsiveUtils.verticalSpace(context, 40),

                          // Actions
                          SizedBox(
                            width: double.infinity,
                            height: ResponsiveUtils.h(context, 56),
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _verifyOtp,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: AppColors.primaryTeal,
                                disabledBackgroundColor: Colors.white.withOpacity(0.5),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(ResponsiveUtils.r(context, 16)),
                                ),
                                elevation: 0,
                                shadowColor: Colors.black.withOpacity(0.1),
                              ),
                              child: _isLoading
                                  ? SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        color: AppColors.primaryTeal,
                                        strokeWidth: 2.5,
                                      ),
                                    )
                                  : Text(
                                      'Verify & Continue',
                                      style: AppTextStyles.button(context).copyWith(
                                        color: AppColors.primaryTeal,
                                        fontSize: ResponsiveUtils.sp(context, 16),
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                            ),
                          ),

                          ResponsiveUtils.verticalSpace(context, 32),

                          Center(
                            child: _resendTimer > 0
                                ? Text(
                                    'Resend code in 00:${_resendTimer.toString().padLeft(2, '0')}',
                                    style: AppTextStyles.body(context).copyWith(
                                      color: Colors.white.withOpacity(0.6),
                                    ),
                                  )
                                : GestureDetector(
                                    onTap: _resendOtp,
                                    child: Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: ResponsiveUtils.w(context, 16),
                                        vertical: ResponsiveUtils.h(context, 8),
                                      ),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(color: Colors.white.withOpacity(0.3)),
                                      ),
                                      child: Text(
                                        'Resend Code',
                                        style: AppTextStyles.body(context).copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                          ),

                          ResponsiveUtils.verticalSpace(context, 20),
                        ],
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
