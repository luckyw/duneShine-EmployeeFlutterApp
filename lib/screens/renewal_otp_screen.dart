import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/colors.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../utils/responsive_utils.dart';
import '../utils/toast_utils.dart';


class RenewalOtpScreen extends StatefulWidget {
  final Map<String, dynamic> customerData;

  const RenewalOtpScreen({
    Key? key,
    required this.customerData,
  }) : super(key: key);

  @override
  State<RenewalOtpScreen> createState() => _RenewalOtpScreenState();
}

class _RenewalOtpScreenState extends State<RenewalOtpScreen> {
  final List<TextEditingController> _controllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  final ApiService _apiService = ApiService();
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _onOtpChanged(String value, int index) {
    if (value.length == 1 && index < 5) {
      _focusNodes[index + 1].requestFocus();
    }
    if (index == 5 && value.isNotEmpty) {
      _verifyOtp();
    }
  }

  void _onKeyPress(RawKeyEvent event, int index) {
    if (event is RawKeyDownEvent && event.logicalKey == LogicalKeyboardKey.backspace) {
      if (_controllers[index].text.isEmpty && index > 0) {
        _focusNodes[index - 1].requestFocus();
      }
    }
  }

  Future<void> _verifyOtp() async {
    String otp = _controllers.map((c) => c.text).join();
    if (otp.length != 6) return;

    setState(() => _isLoading = true);

    final token = _authService.token;
    if (token == null) {
      setState(() => _isLoading = false);
      return;
    }

    final result = await _apiService.verifyRenewalOtp(
      phoneNumber: widget.customerData['phone'],
      otp: otp,
      token: token,
    );

    if (result['success'] == true) {
      final renewalResult = await _apiService.renewSubscription(
        customerId: widget.customerData['id'],
        token: token,
      );

      setState(() => _isLoading = false);

      if (mounted) {
        if (renewalResult['success'] == true) {
          // Success: Return the new expiry data to the lookup screen
          Navigator.pop(context, renewalResult['data']);
        } else {
          ToastUtils.showErrorToast(context, renewalResult['message'] ?? 'Failed to renew subscription');

        }
      }
    } else {
      setState(() => _isLoading = false);
      if (mounted) {
        ToastUtils.showErrorToast(context, result['message'] ?? 'Invalid OTP');

      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundMilkWhite,
      appBar: AppBar(
        title: const Text('Verify OTP'),
        backgroundColor: AppColors.primaryTeal,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(ResponsiveUtils.w(context, 20)),
        child: Column(
          children: [
            SizedBox(height: ResponsiveUtils.h(context, 20)),
            Text(
              'Enter the 6-digit code sent to customer',
              style: TextStyle(
                fontSize: ResponsiveUtils.sp(context, 16),
                color: AppColors.darkNavy,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: ResponsiveUtils.h(context, 8)),
            Text(
              widget.customerData['phone'] ?? '',
              style: TextStyle(
                fontSize: ResponsiveUtils.sp(context, 18),
                fontWeight: FontWeight.bold,
                color: AppColors.primaryTeal,
              ),
            ),
            SizedBox(height: ResponsiveUtils.h(context, 40)),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(6, (index) {
                return SizedBox(
                  width: ResponsiveUtils.w(context, 45),
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
                        fontSize: ResponsiveUtils.sp(context, 20),
                        fontWeight: FontWeight.bold,
                      ),
                      decoration: InputDecoration(
                        counterText: '',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onChanged: (value) => _onOtpChanged(value, index),
                    ),
                  ),
                );
              }),
            ),
            SizedBox(height: ResponsiveUtils.h(context, 40)),
            SizedBox(
              width: double.infinity,
              height: ResponsiveUtils.h(context, 52),
              child: ElevatedButton(
                onPressed: _isLoading ? null : _verifyOtp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryTeal,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        'Verify & Complete', 
                        style: TextStyle(
                          fontWeight: FontWeight.bold, 
                          fontSize: ResponsiveUtils.sp(context, 16),
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
