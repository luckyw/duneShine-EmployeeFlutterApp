import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/colors.dart';
import '../constants/text_styles.dart';
import '../utils/responsive_utils.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../utils/toast_utils.dart';


class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String _selectedCountryCode = '+971';
  bool _isLoading = false;

  final ApiService _apiService = ApiService();
  final AuthService _authService = AuthService();

  // 6 OTP digit controllers and focus nodes
  final List<TextEditingController> _otpControllers = List.generate(
    6,
    (index) => TextEditingController(),
  );
  final List<FocusNode> _otpFocusNodes = List.generate(
    6,
    (index) => FocusNode(),
  );

  final List<Map<String, String>> _countryCodes = [
    {'code': '+971', 'country': 'UAE'},
    {'code': '+966', 'country': 'KSA'},
    {'code': '+1', 'country': 'USA'},
    {'code': '+44', 'country': 'UK'},
    {'code': '+91', 'country': 'IND'},
  ];

  void _login() async {
    if (_formKey.currentState!.validate()) {
      // Check OTP is complete
      if (!_isOtpComplete()) {
        ToastUtils.showErrorToast(context, 'Please enter all 6 OTP digits');

        return;
      }

      setState(() {
        _isLoading = true;
      });

      // Construct full phone number with country code
      final phoneNumber = '+971${_phoneController.text}';
      // Combine all 6 OTP digits
      final otp = _otpControllers.map((c) => c.text).join();

      // Call login API
      final result = await _apiService.login(
        phone: phoneNumber,
        otp: otp,
      );

      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        if (result['success'] == true && result['data']?['success'] == true) {
          // Extract employee data and token from response
          final responseData = result['data']['data'];
          final token = responseData['token'] as String;
          final employeeData = responseData['employee'] as Map<String, dynamic>;

          // Store auth data securely (persistent storage)
          await _authService.setAuthData(
            token: token,
            employeeData: employeeData,
          );

          // Navigate to home screen
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/employee-home',
            (route) => false,
          );
        } else {
          // Show error message
          final message = result['data']?['message'] ?? result['message'] ?? 'Login failed';
          ToastUtils.showErrorToast(context, message);

        }
      }
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var focusNode in _otpFocusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  /// Build a single OTP digit box
  Widget _buildOtpBox(int index) {
    return Container(
      width: ResponsiveUtils.w(context, 46),
      height: ResponsiveUtils.h(context, 56),
      decoration: BoxDecoration(
        color: AppColors.primaryTeal.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(ResponsiveUtils.r(context, 12)),
        border: Border.all(
          color: _otpFocusNodes[index].hasFocus
              ? AppColors.primaryTeal
              : AppColors.primaryTeal.withValues(alpha: 0.3),
          width: _otpFocusNodes[index].hasFocus ? 2 : 1,
        ),
      ),
      child: KeyboardListener(
        focusNode: FocusNode(),
        onKeyEvent: (event) {
          // Handle backspace key press
          if (event is KeyDownEvent && 
              event.logicalKey == LogicalKeyboardKey.backspace) {
            if (_otpControllers[index].text.isEmpty && index > 0) {
              // If current box is empty and backspace pressed, go to previous box
              _otpControllers[index - 1].clear();
              _otpFocusNodes[index - 1].requestFocus();
              setState(() {});
            }
          }
        },
        child: TextField(
          controller: _otpControllers[index],
          focusNode: _otpFocusNodes[index],
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          maxLength: 1,
          style: AppTextStyles.title(context).copyWith(
            color: AppColors.primaryTeal,
            fontSize: ResponsiveUtils.sp(context, 20),
          ),
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
          ],
          decoration: const InputDecoration(
            counterText: '',
            border: InputBorder.none,
            contentPadding: EdgeInsets.zero,
          ),
          onChanged: (value) {
            if (value.isNotEmpty && index < 5) {
              // Move to next box when digit entered
              _otpFocusNodes[index + 1].requestFocus();
            } else if (value.isEmpty && index > 0) {
              // Move to previous box when deleted
              _otpFocusNodes[index - 1].requestFocus();
            }
            setState(() {}); // Rebuild to update border color
          },
        ),
      ),
    );
  }

  /// Check if all OTP boxes are filled
  bool _isOtpComplete() {
    return _otpControllers.every((c) => c.text.isNotEmpty);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(ResponsiveUtils.w(context, 24)),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ResponsiveUtils.verticalSpace(context, 40),
                  // Logo and branding
                  Center(
                    child: Column(
                      children: [
                        Container(
                          width: ResponsiveUtils.r(context, 100),
                          height: ResponsiveUtils.r(context, 100),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(ResponsiveUtils.r(context, 20)),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(ResponsiveUtils.r(context, 20)),
                            child: Image.asset(
                              'assets/images/app_logo.png',
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        SizedBox(height: ResponsiveUtils.h(context, 20)),
                        Text(
                          'Welcome Back',
                          style: AppTextStyles.headline(context).copyWith(
                            color: AppColors.primaryTeal,
                          ),
                        ),
                        SizedBox(height: ResponsiveUtils.h(context, 8)),
                        Text(
                          'Sign in to continue',
                          style: AppTextStyles.subtitle(context).copyWith(
                            color: AppColors.primaryTeal.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: ResponsiveUtils.h(context, 60)),
                  // Phone number label
                  Text(
                    'Phone Number',
                    style: AppTextStyles.body(context).copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryTeal,
                    ),
                  ),
                  ResponsiveUtils.verticalSpace(context, 12),
                  // Phone input row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Static country code
                      Container(
                        height: ResponsiveUtils.h(context, 56),
                        padding: EdgeInsets.symmetric(horizontal: ResponsiveUtils.w(context, 16)),
                        decoration: BoxDecoration(
                          color: AppColors.primaryTeal.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(ResponsiveUtils.r(context, 12)),
                          border: Border.all(
                            color: AppColors.primaryTeal.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            '+971',
                            style: TextStyle(
                              color: AppColors.primaryTeal,
                              fontSize: ResponsiveUtils.sp(context, 16),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      ResponsiveUtils.horizontalSpace(context, 12),
                      // Phone number input
                      Expanded(
                        child: TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          style: TextStyle(
                            color: AppColors.primaryTeal,
                            fontSize: ResponsiveUtils.sp(context, 16),
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(9),
                          ],
                          decoration: InputDecoration(
                            hintText: 'Enter phone number',
                            hintStyle: TextStyle(
                              color: AppColors.primaryTeal.withValues(alpha: 0.4),
                            ),
                            filled: true,
                            fillColor: AppColors.primaryTeal.withValues(alpha: 0.05),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(ResponsiveUtils.r(context, 12)),
                              borderSide: BorderSide(
                                color: AppColors.primaryTeal.withValues(alpha: 0.3),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(ResponsiveUtils.r(context, 12)),
                              borderSide: BorderSide(
                                color: AppColors.primaryTeal.withValues(alpha: 0.3),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(ResponsiveUtils.r(context, 12)),
                              borderSide: const BorderSide(
                                color: AppColors.primaryTeal,
                                width: 2,
                              ),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(ResponsiveUtils.r(context, 12)),
                              borderSide: const BorderSide(
                                color: Colors.red,
                              ),
                            ),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: ResponsiveUtils.w(context, 16),
                              vertical: ResponsiveUtils.h(context, 16),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter phone number';
                            }
                            if (value.length < 9) {
                              return 'Invalid phone number';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: ResponsiveUtils.h(context, 24)),
                  // OTP Key label
                  Text(
                    'Enter OTP Key',
                    style: AppTextStyles.body(context).copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryTeal,
                    ),
                  ),
                  SizedBox(height: ResponsiveUtils.h(context, 4)),
                  // Professional message about vendor OTP
                  Text(
                    'Please enter the 6-digit OTP provided by your vendor',
                    style: AppTextStyles.caption(context).copyWith(
                      color: AppColors.primaryTeal.withValues(alpha: 0.6),
                    ),
                  ),
                  ResponsiveUtils.verticalSpace(context, 12),
                  // 6 OTP boxes
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(
                      6,
                      (index) => _buildOtpBox(index),
                    ),
                  ),
                  // Error message for OTP validation
                  if (!_isOtpComplete() && _otpControllers.any((c) => c.text.isNotEmpty))
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'Please enter all 6 digits',
                        style: AppTextStyles.caption(context).copyWith(
                          color: Colors.red.shade300,
                        ),
                      ),
                    ),
                  ResponsiveUtils.verticalSpace(context, 40),
                  // Login button
                  SizedBox(
                    width: double.infinity,
                    height: ResponsiveUtils.h(context, 56),
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _login,
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
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: AppColors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              'Login',
                              style: AppTextStyles.button(context).copyWith(
                                fontSize: ResponsiveUtils.sp(context, 18),
                              ),
                            ),
                    ),
                  ),
                  ResponsiveUtils.verticalSpace(context, 24),
                  // Terms text
                  Center(
                    child: Text(
                      'By continuing, you agree to our Terms of Service\nand Privacy Policy',
                      style: AppTextStyles.caption(context).copyWith(
                        color: AppColors.primaryTeal.withValues(alpha: 0.6),
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
