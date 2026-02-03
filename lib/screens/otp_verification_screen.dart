import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/colors.dart';
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
    return Scaffold(
      backgroundColor: AppColors.darkNavy,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: EdgeInsets.all(ResponsiveUtils.w(context, 24)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ResponsiveUtils.verticalSpace(context, 20),
                    // Header
                    Text(
                      'Verify OTP',
                      style: TextStyle(
                        fontSize: ResponsiveUtils.sp(context, 28),
                        fontWeight: FontWeight.bold,
                        color: AppColors.white,
                      ),
                    ),
                    ResponsiveUtils.verticalSpace(context, 12),
                    Text(
                      'Enter the 6-digit code sent to',
                      style: TextStyle(
                        fontSize: ResponsiveUtils.sp(context, 16),
                        color: AppColors.white.withOpacity(0.7),
                      ),
                    ),
                    ResponsiveUtils.verticalSpace(context, 4),
                    Text(
                      _phoneNumber ?? '',
                      style: TextStyle(
                        fontSize: ResponsiveUtils.sp(context, 16),
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryTeal,
                      ),
                    ),
                    ResponsiveUtils.verticalSpace(context, 48),
                    // OTP Input boxes
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(6, (index) {
                        return SizedBox(
                          width: ResponsiveUtils.w(context, 50),
                          height: ResponsiveUtils.h(context, 60),
                          child: RawKeyboardListener(
                            focusNode: FocusNode(),
                            onKey: (event) => _onKeyPress(event, index),
                            child: TextFormField(
                              controller: _controllers[index],
                              focusNode: _focusNodes[index],
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              maxLength: 1,
                              style: TextStyle(
                                fontSize: ResponsiveUtils.sp(context, 24),
                                fontWeight: FontWeight.bold,
                                color: AppColors.white,
                              ),
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              decoration: InputDecoration(
                                counterText: '',
                                filled: true,
                                fillColor: AppColors.white.withOpacity(0.1),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(ResponsiveUtils.r(context, 12)),
                                  borderSide: BorderSide(
                                    color: AppColors.white.withOpacity(0.2),
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(ResponsiveUtils.r(context, 12)),
                                  borderSide: BorderSide(
                                    color: AppColors.white.withOpacity(0.2),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(ResponsiveUtils.r(context, 12)),
                                  borderSide: BorderSide(
                                    color: AppColors.primaryTeal,
                                    width: ResponsiveUtils.w(context, 2),
                                  ),
                                ),
                              ),
                              onChanged: (value) => _onOtpChanged(value, index),
                            ),
                          ),
                        );
                      }),
                    ),
                    ResponsiveUtils.verticalSpace(context, 32),
                    // Resend timer
                    Center(
                      child: _resendTimer > 0
                          ? Text(
                              'Resend OTP in ${_resendTimer}s',
                              style: TextStyle(
                                fontSize: ResponsiveUtils.sp(context, 14),
                                color: AppColors.white.withOpacity(0.5),
                              ),
                            )
                          : TextButton(
                              onPressed: _resendOtp,
                              child: Text(
                                'Resend OTP',
                                style: TextStyle(
                                  fontSize: ResponsiveUtils.sp(context, 14),
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryTeal,
                                ),
                              ),
                            ),
                    ),
                    const Spacer(),
                    // Verify button
                    SizedBox(
                      width: double.infinity,
                      height: ResponsiveUtils.h(context, 56),
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _verifyOtp,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryTeal,
                          foregroundColor: AppColors.white,
                          disabledBackgroundColor:
                              AppColors.primaryTeal.withOpacity(0.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(ResponsiveUtils.r(context, 16)),
                          ),
                          elevation: 4,
                          shadowColor: AppColors.primaryTeal.withOpacity(0.4),
                        ),
                        child: _isLoading
                            ? SizedBox(
                                width: ResponsiveUtils.w(context, 24),
                                height: ResponsiveUtils.h(context, 24),
                                child: CircularProgressIndicator(
                                  color: AppColors.white,
                                  strokeWidth: ResponsiveUtils.w(context, 2),
                                ),
                              )
                            : Text(
                                'Verify & Continue',
                                style: TextStyle(
                                  fontSize: ResponsiveUtils.sp(context, 18),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                    ResponsiveUtils.verticalSpace(context, 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
