import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../constants/text_styles.dart';
import '../utils/toast_utils.dart';
import '../utils/responsive_utils.dart';

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
        title: Text(
          'Equipment Support',
          style: AppTextStyles.title(context).copyWith(
            color: AppColors.white,
            fontSize: ResponsiveUtils.sp(context, 20),
          ),
        ),
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
              padding: EdgeInsets.all(ResponsiveUtils.w(context, 24)),
              color: AppColors.primaryTeal.withValues(alpha: 0.1),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your Equipment',
                    style: AppTextStyles.title(context).copyWith(
                      color: AppColors.darkNavy,
                      fontWeight: FontWeight.bold,
                      fontSize: ResponsiveUtils.sp(context, 20),
                    ),
                  ),
                  ResponsiveUtils.verticalSpace(context, 4),
                  Text(
                    'Request support or replacement for your equipment',
                    style: AppTextStyles.body(context).copyWith(
                      color: AppColors.textGray,
                      fontSize: ResponsiveUtils.sp(context, 14),
                    ),
                  ),
                ],
              ),
            ),

            // Equipment list
            Padding(
              padding: EdgeInsets.all(ResponsiveUtils.w(context, 16)),
              child: Column(
                children: _equipment
                    .map((item) => _buildEquipmentCard(item))
                    .toList(),
              ),
            ),

            // Contact support section
            Container(
              margin: EdgeInsets.all(ResponsiveUtils.w(context, 16)),
              padding: EdgeInsets.all(ResponsiveUtils.w(context, 20)),
              decoration: BoxDecoration(
                color: AppColors.creamBg,
                borderRadius: BorderRadius.circular(
                  ResponsiveUtils.r(context, 16),
                ),
                border: Border.all(
                  color: AppColors.gold,
                  width: ResponsiveUtils.w(context, 1),
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.headset_mic,
                    color: AppColors.gold,
                    size: ResponsiveUtils.r(context, 48),
                  ),
                  ResponsiveUtils.verticalSpace(context, 12),
                  Text(
                    'Need Urgent Support?',
                    style: AppTextStyles.title(context).copyWith(
                      color: AppColors.darkNavy,
                      fontWeight: FontWeight.bold,
                      fontSize: ResponsiveUtils.sp(context, 18),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  ResponsiveUtils.verticalSpace(context, 8),
                  Text(
                    'Contact our equipment support team for immediate assistance',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.body(context).copyWith(
                      color: AppColors.textGray,
                      fontSize: ResponsiveUtils.sp(context, 14),
                    ),
                  ),
                  ResponsiveUtils.verticalSpace(context, 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        ToastUtils.showSuccessToast(
                          context,
                          'Contacting support...',
                        );
                      },
                      icon: Icon(
                        Icons.phone,
                        size: ResponsiveUtils.r(context, 20),
                      ),
                      label: Text(
                        'Call Support',
                        style: TextStyle(
                          fontSize: ResponsiveUtils.sp(context, 16),
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryTeal,
                        foregroundColor: AppColors.white,
                        padding: EdgeInsets.symmetric(
                          vertical: ResponsiveUtils.h(context, 14),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            ResponsiveUtils.r(context, 12),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            ResponsiveUtils.verticalSpace(context, 24),
          ],
        ),
      ),
    );
  }

  Widget _buildEquipmentCard(Map<String, dynamic> item) {
    return Container(
      margin: EdgeInsets.only(bottom: ResponsiveUtils.h(context, 12)),
      padding: EdgeInsets.all(ResponsiveUtils.w(context, 16)),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(ResponsiveUtils.r(context, 12)),
        border: Border.all(
          color: AppColors.lightGray.withValues(alpha: 0.3),
          width: ResponsiveUtils.w(context, 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: ResponsiveUtils.r(context, 8),
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(ResponsiveUtils.w(context, 12)),
            decoration: BoxDecoration(
              color: AppColors.primaryTeal.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(
                ResponsiveUtils.r(context, 12),
              ),
            ),
            child: Icon(
              item['icon'] as IconData,
              color: AppColors.primaryTeal,
              size: ResponsiveUtils.r(context, 28),
            ),
          ),
          ResponsiveUtils.horizontalSpace(context, 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['name'] as String,
                  style: AppTextStyles.body(context).copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.darkNavy,
                    fontSize: ResponsiveUtils.sp(context, 16),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                ResponsiveUtils.verticalSpace(context, 4),
                Row(
                  children: [
                    Container(
                      width: ResponsiveUtils.w(context, 8),
                      height: ResponsiveUtils.h(context, 8),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: item['statusColor'] as Color,
                      ),
                    ),
                    ResponsiveUtils.horizontalSpace(context, 6),
                    Expanded(
                      child: Text(
                        item['status'] as String,
                        style: AppTextStyles.caption(context).copyWith(
                          color: item['statusColor'] as Color,
                          fontSize: ResponsiveUtils.sp(context, 12),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                'Request',
                style: TextStyle(
                  color: AppColors.primaryTeal,
                  fontWeight: FontWeight.w600,
                  fontSize: ResponsiveUtils.sp(context, 14),
                ),
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
        title: Text(
          'Request Support',
          style: AppTextStyles.title(
            context,
          ).copyWith(fontSize: ResponsiveUtils.sp(context, 20)),
        ),
        content: Text(
          'Request support for $itemName?',
          style: AppTextStyles.body(
            context,
          ).copyWith(fontSize: ResponsiveUtils.sp(context, 16)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(fontSize: ResponsiveUtils.sp(context, 14)),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ToastUtils.showSuccessToast(
                context,
                'Support request sent for $itemName',
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryTeal,
            ),
            child: Text(
              'Request',
              style: TextStyle(fontSize: ResponsiveUtils.sp(context, 14)),
            ),
          ),
        ],
      ),
    );
  }
}
