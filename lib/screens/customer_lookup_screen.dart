import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import '../constants/colors.dart';
import '../constants/text_styles.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../utils/responsive_utils.dart';
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

  // Flow State
  Map<String, dynamic>? _customerData;
  bool _isRenewed = false;
  bool _isProcessingAction = false;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleLookup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _customerData = null; // Clear previous result
      _isRenewed = false;
    });

    final phoneNumber = '+971${_phoneController.text.trim()}';
    final token = _authService.token;

    if (token == null) {
      setState(() => _isLoading = false);
      return;
    }

    // Call API to fetch customer details directly
    final result = await _apiService.getCustomerDetails(
      phoneNumber: phoneNumber,
      token: token,
    );

    setState(() => _isLoading = false);

    if (mounted) {
      if (result['success'] == true) {
        setState(() {
          _customerData = result['data']['customer'];
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Customer not found'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleCollectCash() async {
    if (_customerData == null) return;

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Cash Collection'),
        content: Text('Did you collect ${_customerData!['plan_price'] ?? 'X'} AED from the customer?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryTeal),
            child: const Text('Yes, Collected', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isProcessingAction = true);

    final token = _authService.token;
    if (token == null) return;

    final result = await _apiService.sendRenewalOtp(
      phoneNumber: _customerData!['phone'],
      token: token,
    );

    setState(() => _isProcessingAction = false);

    if (mounted && result['success'] == true) {
      // Step 5: Navigate to OTP Screen
      final dynamic renewalData = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => RenewalOtpScreen(customerData: _customerData!),
        ),
      );

      // Step 6: On success, update UI with new status
      if (renewalData != null && mounted) {
        setState(() {
          _isRenewed = true;
          // Update local data to reflect active status and new expiry
          _customerData!['is_subscription_active'] = true;
          _customerData!['subscription_end_date'] = renewalData['new_end_date'] ?? DateTime.now().add(const Duration(days: 30)).toIso8601String();
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Subscription renewed successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? 'Failed to send OTP'), backgroundColor: Colors.red),
      );
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
      body: SingleChildScrollView(
        padding: EdgeInsets.all(ResponsiveUtils.w(context, 20)),
        child: Column(
          children: [
            _buildSearchSection(),
            if (_customerData != null) ...[
              SizedBox(height: ResponsiveUtils.h(context, 20)),
              _buildCustomerDetailsCard(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSearchSection() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Lookup Customer',
            style: AppTextStyles.headline(context).copyWith(
              color: AppColors.darkNavy,
              fontSize: ResponsiveUtils.sp(context, 22),
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: ResponsiveUtils.h(context, 8)),
          Text(
            'Enter phone number to see details.',
            style: AppTextStyles.body(context).copyWith(
              color: AppColors.lightGray,
              fontSize: ResponsiveUtils.sp(context, 14),
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: ResponsiveUtils.h(context, 24)),
          TextFormField(
            controller: _phoneController,
            maxLength: 9,
            decoration: InputDecoration(
              counterText: "",
              labelText: 'Phone Number',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              prefixIcon: const Icon(Icons.phone),
              prefixText: '+971 ',
              prefixStyle: const TextStyle(color: AppColors.darkNavy, fontWeight: FontWeight.bold),
              hintText: '50xxxxxxx',
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            validator: (value) {
              if (value == null || value.isEmpty) return 'Please enter phone number';
              if (value.length != 9) return 'Phone number must be exactly 9 digits';
              return null;
            },
          ),
          SizedBox(height: ResponsiveUtils.h(context, 16)),
          SizedBox(
            height: ResponsiveUtils.h(context, 52),
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleLookup,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryTeal,
                foregroundColor: AppColors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isLoading
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: AppColors.white, strokeWidth: 2))
                  : Text('Lookup', style: TextStyle(fontSize: ResponsiveUtils.sp(context, 16), fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerDetailsCard() {
    final data = _customerData!;
    final bool isActive = data['is_subscription_active'] ?? false;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(ResponsiveUtils.w(context, 20)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: ResponsiveUtils.r(context, 25),
                backgroundColor: AppColors.primaryTeal.withOpacity(0.1),
                child: const Icon(Icons.person, color: AppColors.primaryTeal),
              ),
              SizedBox(width: ResponsiveUtils.w(context, 12)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(data['name'] ?? 'Unknown', style: AppTextStyles.title(context)),
                    Text(data['phone'] ?? '', style: AppTextStyles.caption(context).copyWith(color: AppColors.lightGray)),
                  ],
                ),
              ),
              if (_isRenewed)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                  child: const Text('RENEWED', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12)),
                ),
            ],
          ),
          SizedBox(height: ResponsiveUtils.h(context, 20)),
          _buildDetailRow('Car Model', data['car_model']),
          _buildDetailRow('Plate No', data['car_plate']),
          _buildDetailRow('Plan', data['current_plan']),
          _buildDetailRow(
            'Status',
            isActive ? 'Active' : 'Expired',
            textColor: isActive ? Colors.green : Colors.red,
            isBold: true,
          ),
          if (!_isRenewed) _buildDetailRow('Expiry', data['subscription_end_date']?.split('T')[0] ?? 'N/A'),
          if (_isRenewed) _buildDetailRow('New Expiry', data['subscription_end_date']?.split('T')[0] ?? 'N/A', textColor: Colors.green, isBold: true),
          
          SizedBox(height: ResponsiveUtils.h(context, 24)),
          _buildActionSection(),
        ],
      ),
    );
  }

  Widget _buildActionSection() {
    if (_isRenewed) {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.all(ResponsiveUtils.w(context, 12)),
        decoration: BoxDecoration(color: Colors.green.withOpacity(0.05), borderRadius: BorderRadius.circular(ResponsiveUtils.r(context, 8))),
        child: Text(
          'Subscription successfully reactivated for another month!',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.green, 
            fontWeight: FontWeight.w500,
            fontSize: ResponsiveUtils.sp(context, 14),
          ),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      height: ResponsiveUtils.h(context, 50),
      child: ElevatedButton(
        onPressed: _isProcessingAction ? null : _handleCollectCash,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryTeal,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: _isProcessingAction
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text('Collect Cash', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ),
    );
  }

  Widget _buildDetailRow(String label, String? value, {Color? textColor, bool isBold = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: ResponsiveUtils.h(context, 6)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: AppColors.lightGray, fontSize: ResponsiveUtils.sp(context, 14))),
          Text(
            value ?? '',
            style: TextStyle(
              color: textColor ?? AppColors.darkNavy,
              fontSize: ResponsiveUtils.sp(context, 14),
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
