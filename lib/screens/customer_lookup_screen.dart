import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/colors.dart';
import '../constants/text_styles.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import 'renewal_otp_screen.dart';

class CustomerLookupScreen extends StatefulWidget {
  const CustomerLookupScreen({Key? key}) : super(key: key);

  @override
  State<CustomerLookupScreen> createState() => _CustomerLookupScreenState();
}

class _CustomerLookupScreenState extends State<CustomerLookupScreen> {
  final _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  final ApiService _apiService = ApiService();
  final AuthService _authService = AuthService();

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleLookup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final phoneNumber = '+971${_phoneController.text.trim()}';
    final token = _authService.token;

    if (token == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Not authenticated')),
        );
      }
      setState(() => _isLoading = false);
      return;
    }

    // Call Mock API to send OTP
    final result = await _apiService.sendRenewalOtp(
      phoneNumber: phoneNumber,
      token: token,
    );

    setState(() => _isLoading = false);

    if (mounted) {
      if (result['success'] == true) {
        // Navigate to OTP Screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RenewalOtpScreen(
              phoneNumber: phoneNumber,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Failed to send OTP'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundMilkWhite,
      appBar: AppBar(
        title: const Text('Customer Lookup'),
        backgroundColor: AppColors.primaryTeal,
        foregroundColor: AppColors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              Text(
                'Enter Customer Phone Number',
                style: AppTextStyles.headline(context).copyWith(
                  color: AppColors.darkNavy,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'We will send an OTP to verify the customer.',
                style: AppTextStyles.body(context).copyWith(
                  color: AppColors.lightGray,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              TextFormField(
                controller: _phoneController,
                maxLength: 9,
                decoration: InputDecoration(
                  counterText: "",
                  labelText: 'Phone Number',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.phone),
                  prefixText: '+971 ',
                  prefixStyle: const TextStyle(
                    color: AppColors.darkNavy,
                    fontWeight: FontWeight.bold,
                  ),
                  hintText: '50xxxxxxx',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter phone number';
                  }
                  if (value.length != 9) {
                    return 'Phone number must be exactly 9 digits';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleLookup,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryTeal,
                    foregroundColor: AppColors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
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
                          'Send OTP',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
