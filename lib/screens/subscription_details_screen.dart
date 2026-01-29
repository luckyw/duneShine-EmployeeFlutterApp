import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../constants/text_styles.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

class SubscriptionDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> customerData;

  const SubscriptionDetailsScreen({
    Key? key,
    required this.customerData,
  }) : super(key: key);

  @override
  State<SubscriptionDetailsScreen> createState() => _SubscriptionDetailsScreenState();
}

class _SubscriptionDetailsScreenState extends State<SubscriptionDetailsScreen> {
  final ApiService _apiService = ApiService();
  final AuthService _authService = AuthService();
  bool _isRenewing = false;

  Future<void> _handleRenewal() async {
    setState(() => _isRenewing = true);

    final token = _authService.token;
    if (token == null) {
        setState(() => _isRenewing = false);
        return;
    }

    final result = await _apiService.renewSubscription(
      customerId: widget.customerData['id'],
      token: token,
    );

    setState(() => _isRenewing = false);

    if (mounted) {
      if (result['success'] == true) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('Success'),
            content: const Text('Subscription renewed successfully!'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  // Navigate back to Home or Account
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Failed to renew subscription'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.customerData;
    final bool isActive = data['is_subscription_active'] ?? false;

    return Scaffold(
      backgroundColor: AppColors.backgroundMilkWhite,
      appBar: AppBar(
        title: const Text('Subscription Details'),
        backgroundColor: AppColors.primaryTeal,
        foregroundColor: AppColors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // Customer Info Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                   const CircleAvatar(
                    radius: 40,
                    backgroundColor: AppColors.lightGray,
                    child: Icon(Icons.person, size: 40, color: Colors.white),
                   ),
                   const SizedBox(height: 16),
                   Text(
                     data['name'] ?? 'Unknown Name',
                     style: AppTextStyles.headline(context).copyWith(fontSize: 22),
                   ),
                   const SizedBox(height: 4),
                   Text(
                     data['phone'] ?? '',
                     style: AppTextStyles.body(context).copyWith(color: AppColors.lightGray),
                   ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            
            // Car & Plan Details
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailRow('Car Model', data['car_model']),
                  const Divider(),
                  _buildDetailRow('Plate Number', data['car_plate']),
                  const Divider(),
                  _buildDetailRow('Current Plan', data['current_plan'] ?? 'N/A'),
                  const Divider(),
                  _buildDetailRow(
                    'Status',
                    isActive ? 'Active' : 'Expired',
                    textColor: isActive ? Colors.green : Colors.red,
                    isBold: true,
                  ),
                  const Divider(),
                  _buildDetailRow(
                    'Last Expiry', 
                     data['subscription_end_date'] != null 
                        ? data['subscription_end_date'].toString().split('T')[0] 
                        : 'N/A'
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Renew Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isRenewing ? null : _handleRenewal,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryTeal,
                  foregroundColor: AppColors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _isRenewing
                   ? const CircularProgressIndicator(color: Colors.white)
                   : const Text(
                       'Renew Subscription (Cash Received)',
                       style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                     ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String? value, {Color? textColor, bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.lightGray,
              fontSize: 16,
            ),
          ),
          Text(
            value ?? '',
            style: TextStyle(
              color: textColor ?? AppColors.darkNavy,
              fontSize: 16,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
