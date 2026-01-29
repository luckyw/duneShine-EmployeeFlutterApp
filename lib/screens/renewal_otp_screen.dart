import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/colors.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import 'subscription_details_screen.dart';

class RenewalOtpScreen extends StatefulWidget {
  final String phoneNumber;

  const RenewalOtpScreen({
    Key? key,
    required this.phoneNumber,
  }) : super(key: key);

  @override
  State<RenewalOtpScreen> createState() => _RenewalOtpScreenState();
}

class _RenewalOtpScreenState extends State<RenewalOtpScreen> {
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  bool _isLoading = false;
  int _resendTimer = 30;
  Timer? _timer;
  final ApiService _apiService = ApiService();
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _startResendTimer();
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

  void _resendOtp() async {
    if (_resendTimer == 0) {
      final token = _authService.token;
      if (token == null) return;
      
      await _apiService.sendRenewalOtp(phoneNumber: widget.phoneNumber, token: token);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('OTP resent successfully'),
            backgroundColor: AppColors.primaryTeal,
          ),
        );
        _startResendTimer();
      }
    }
  }

  void _verifyOtp() async {
    String otp = _controllers.map((c) => c.text).join();
    if (otp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter complete OTP'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final token = _authService.token;
    if (token == null) {
        setState(() => _isLoading = false);
        return;
    }

    final result = await _apiService.verifyRenewalOtp(
      phoneNumber: widget.phoneNumber,
      otp: otp,
      token: token,
    );

    if (result['success'] == true) {
      // Fetch user details immediately after OTP verification success
      final uDetails = await _apiService.getCustomerDetails(phoneNumber: widget.phoneNumber, token: token);

      setState(() {
        _isLoading = false;
      });

      if (uDetails['success'] == true && mounted) {
           Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => SubscriptionDetailsScreen(
                customerData: uDetails['data']['customer'],
              ),
            ),
          );
      } else {
         if (mounted) {
             ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(uDetails['message'] ?? 'Failed to load customer details'),
                backgroundColor: Colors.red,
              ),
            );
         }
      }

    } else {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Invalid OTP'),
            backgroundColor: Colors.red,
          ),
        );
      }
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
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              const Text(
                'Verify Customer',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.white,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Enter the 6-digit code sent to customer',
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.white.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.phoneNumber,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryTeal,
                ),
              ),
              const SizedBox(height: 48),
              // OTP Input boxes
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(6, (index) {
                  return SizedBox(
                    width: 50,
                    height: 60,
                    child: RawKeyboardListener(
                      focusNode: FocusNode(),
                      onKey: (event) => _onKeyPress(event, index),
                      child: TextFormField(
                        controller: _controllers[index],
                        focusNode: _focusNodes[index],
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        maxLength: 1,
                        style: const TextStyle(
                          fontSize: 24,
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
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: AppColors.white.withOpacity(0.2),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: AppColors.white.withOpacity(0.2),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: AppColors.primaryTeal,
                              width: 2,
                            ),
                          ),
                        ),
                        onChanged: (value) => _onOtpChanged(value, index),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 32),
              // Resend timer
              Center(
                child: _resendTimer > 0
                    ? Text(
                        'Resend OTP in ${_resendTimer}s',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.white.withOpacity(0.5),
                        ),
                      )
                    : TextButton(
                        onPressed: _resendOtp,
                        child: const Text(
                          'Resend OTP',
                          style: TextStyle(
                            fontSize: 14,
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
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _verifyOtp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryTeal,
                    foregroundColor: AppColors.white,
                    disabledBackgroundColor:
                        AppColors.primaryTeal.withOpacity(0.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 4,
                    shadowColor: AppColors.primaryTeal.withOpacity(0.4),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: AppColors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Verify & Continue',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
