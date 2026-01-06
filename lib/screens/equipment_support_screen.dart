import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../constants/text_styles.dart';

class EquipmentSupportScreen extends StatefulWidget {
  const EquipmentSupportScreen({Key? key}) : super(key: key);

  @override
  State<EquipmentSupportScreen> createState() => _EquipmentSupportScreenState();
}

class _EquipmentSupportScreenState extends State<EquipmentSupportScreen> {
  final List<Map<String, dynamic>> _equipment = [
    {
      'name': 'Car Wash Kit',
      'icon': Icons.wash,
      'status': 'Good',
      'statusColor': Colors.green,
    },
    {
      'name': 'Portable Vacuum',
      'icon': Icons.cleaning_services,
      'status': 'Good',
      'statusColor': Colors.green,
    },
    {
      'name': 'Microfiber Towels',
      'icon': Icons.dry_cleaning,
      'status': 'Need Replacement',
      'statusColor': Colors.orange,
    },
    {
      'name': 'Tire Shine Kit',
      'icon': Icons.tire_repair,
      'status': 'Good',
      'statusColor': Colors.green,
    },
    {
      'name': 'Glass Cleaner',
      'icon': Icons.window,
      'status': 'Low Stock',
      'statusColor': Colors.orange,
    },
    {
      'name': 'Interior Cleaner',
      'icon': Icons.airline_seat_recline_normal,
      'status': 'Good',
      'statusColor': Colors.green,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.primaryTeal,
        foregroundColor: AppColors.white,
        title: const Text('Equipment Support'),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              color: AppColors.primaryTeal.withOpacity(0.1),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your Equipment',
                    style: AppTextStyles.title(context).copyWith(
                      color: AppColors.darkNavy,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Request support or replacement for your equipment',
                    style: AppTextStyles.body(context).copyWith(
                      color: AppColors.textGray,
                    ),
                  ),
                ],
              ),
            ),
            
            // Equipment list
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: _equipment.map((item) => _buildEquipmentCard(item)).toList(),
              ),
            ),
            
            // Contact support section
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.creamBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.gold, width: 1),
              ),
              child: Column(
                children: [
                  Icon(Icons.headset_mic, color: AppColors.gold, size: 48),
                  const SizedBox(height: 12),
                  Text(
                    'Need Urgent Support?',
                    style: AppTextStyles.title(context).copyWith(
                      color: AppColors.darkNavy,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Contact our equipment support team for immediate assistance',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.body(context).copyWith(
                      color: AppColors.textGray,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Contacting support...'),
                            backgroundColor: AppColors.primaryTeal,
                          ),
                        );
                      },
                      icon: const Icon(Icons.phone),
                      label: const Text('Call Support'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryTeal,
                        foregroundColor: AppColors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildEquipmentCard(Map<String, dynamic> item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.lightGray.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primaryTeal.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              item['icon'] as IconData,
              color: AppColors.primaryTeal,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['name'] as String,
                  style: AppTextStyles.body(context).copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.darkNavy,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: item['statusColor'] as Color,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      item['status'] as String,
                      style: AppTextStyles.caption(context).copyWith(
                        color: item['statusColor'] as Color,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () {
              _showRequestDialog(item['name'] as String);
            },
            child: Text(
              'Request',
              style: TextStyle(
                color: AppColors.primaryTeal,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showRequestDialog(String itemName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Request Support'),
        content: Text('Request support for $itemName?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Support request sent for $itemName'),
                  backgroundColor: AppColors.success,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryTeal,
            ),
            child: const Text('Request'),
          ),
        ],
      ),
    );
  }
}
