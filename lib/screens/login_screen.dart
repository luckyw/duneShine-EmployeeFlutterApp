import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pinput/pinput.dart';
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
  bool _isLoading = false;

  final ApiService _apiService = ApiService();
  final AuthService _authService = AuthService();

  final TextEditingController _otpController = TextEditingController();
  final FocusNode _otpFocusNode = FocusNode();



  void _login() async {
    if (_formKey.currentState!.validate()) {
      // Check OTP is complete
      if (_otpController.text.length < 6) {
        ToastUtils.showErrorToast(context, 'Please enter all 6 OTP digits');
        return;
      }

      setState(() {
        _isLoading = true;
      });

      // Construct full phone number with country code
      final phoneNumber = '+971${_phoneController.text}';
      final otp = _otpController.text;

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
    _otpController.dispose();
    _otpFocusNode.dispose();
    super.dispose();
  }

  // Removed manual _buildOtpBox and _isOtpComplete since we use Pinput now

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
                  // Pinput OTP component
                  Center(
                    child: Pinput(
                      length: 6,
                      controller: _otpController,
                      focusNode: _otpFocusNode,
                      defaultPinTheme: PinTheme(
                        width: ResponsiveUtils.w(context, 46),
                        height: ResponsiveUtils.h(context, 56),
                        textStyle: AppTextStyles.title(context).copyWith(
                          color: AppColors.primaryTeal,
                          fontSize: ResponsiveUtils.sp(context, 20),
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryTeal.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(ResponsiveUtils.r(context, 12)),
                          border: Border.all(
                            color: AppColors.primaryTeal.withValues(alpha: 0.3),
                          ),
                        ),
                      ),
                      focusedPinTheme: PinTheme(
                        width: ResponsiveUtils.w(context, 46),
                        height: ResponsiveUtils.h(context, 56),
                        textStyle: AppTextStyles.title(context).copyWith(
                          color: AppColors.primaryTeal,
                          fontSize: ResponsiveUtils.sp(context, 20),
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryTeal.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(ResponsiveUtils.r(context, 12)),
                          border: Border.all(
                            color: AppColors.primaryTeal,
                            width: 2,
                          ),
                        ),
                      ),
                      errorPinTheme: PinTheme(
                        width: ResponsiveUtils.w(context, 46),
                        height: ResponsiveUtils.h(context, 56),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(ResponsiveUtils.r(context, 12)),
                          border: Border.all(color: Colors.red),
                        ),
                      ),
                      onChanged: (value) {
                        setState(() {});
                      },
                    ),
                  ),
                  // Error message for OTP validation
                  if (_otpController.text.isNotEmpty && _otpController.text.length < 6)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Center(
                        child: Text(
                          'Please enter all 6 digits',
                          style: AppTextStyles.caption(context).copyWith(
                            color: Colors.red.shade300,
                          ),
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
