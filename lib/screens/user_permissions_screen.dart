import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../utils/responsive_utils.dart';
import '../constants/text_styles.dart';

class UserPermissionsScreen extends StatelessWidget {
  const UserPermissionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundMilkWhite,
      appBar: AppBar(
        title: Text(
          'User Permissions',
          style: AppTextStyles.title(context).copyWith(color: AppColors.white),
        ),
        backgroundColor: AppColors.primaryTeal,
        iconTheme: const IconThemeData(color: AppColors.white),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(ResponsiveUtils.w(context, 20)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(
              Icons.privacy_tip_outlined,
              size: ResponsiveUtils.r(context, 80),
              color: AppColors.primaryTeal,
            ),
            ResponsiveUtils.verticalSpace(context, 24),
            Text(
              'How We Use Permissions',
              style: AppTextStyles.headline(context).copyWith(
                color: AppColors.textDark,
              ),
              textAlign: TextAlign.center,
            ),
            ResponsiveUtils.verticalSpace(context, 12),
            Text(
              'DuneShine requires certain device permissions to provide a seamless job tracking and scheduling experience. Below is a detailed explanation of what we ask for and why.',
              style: AppTextStyles.body(context).copyWith(
                color: AppColors.textGray,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            ResponsiveUtils.verticalSpace(context, 32),
            
            // Location Permission
            _buildPermissionItem(
              context: context,
              icon: Icons.location_on_outlined,
              title: 'Location Services (Background & Foreground)',
              description: 'We need your location to track your progress to customer locations, ensure you arrive on time, and enable the dispatch team to monitor active shifts. Background tracking only occurs while you are actively on a shift.',
            ),
            
            ResponsiveUtils.verticalSpace(context, 20),
            
            // Camera & Photos Permission
            _buildPermissionItem(
              context: context,
              icon: Icons.camera_alt_outlined,
              title: 'Camera & Photos',
              description: 'Used when you need to upload a profile picture or submit proof-of-completion photos for a job. We only access the photos you explicitly select or take within the app.',
            ),
            
            ResponsiveUtils.verticalSpace(context, 20),
            
            // Notifications Permission
            _buildPermissionItem(
              context: context,
              icon: Icons.notifications_active_outlined,
              title: 'Push Notifications',
              description: 'Used to alert you when a new job is assigned to you, when your shift starts, and to keep background location services running smoothly. You can manage notifications in your device settings.',
            ),
            
            ResponsiveUtils.verticalSpace(context, 40),
            Container(
              padding: EdgeInsets.all(ResponsiveUtils.w(context, 16)),
              decoration: BoxDecoration(
                color: AppColors.primaryTeal.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(ResponsiveUtils.r(context, 12)),
                border: Border.all(color: AppColors.primaryTeal.withValues(alpha: 0.3)),
              ),
              child: Text(
                'Data Privacy: DuneShine does not sell or share your permission data with third parties. All data collected is strictly for operational purposes.',
                style: AppTextStyles.body(context).copyWith(
                  color: AppColors.darkTeal,
                  fontStyle: FontStyle.italic,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(ResponsiveUtils.r(context, 16)),
        border: Border.all(color: AppColors.onDemandBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: EdgeInsets.all(ResponsiveUtils.w(context, 20)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(ResponsiveUtils.w(context, 10)),
            decoration: BoxDecoration(
              color: AppColors.creamBg,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: AppColors.gold,
              size: ResponsiveUtils.r(context, 24),
            ),
          ),
          ResponsiveUtils.horizontalSpace(context, 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.subtitle(context).copyWith(
                    color: AppColors.textDark,
                  ),
                ),
                ResponsiveUtils.verticalSpace(context, 8),
                Text(
                  description,
                  style: AppTextStyles.body(context).copyWith(
                    color: AppColors.textGray,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
