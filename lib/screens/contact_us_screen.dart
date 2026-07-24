import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constants/colors.dart';
import '../utils/responsive_utils.dart';
import '../utils/toast_utils.dart';
import '../constants/text_styles.dart';

class ContactUsScreen extends StatelessWidget {
  const ContactUsScreen({super.key});

  Future<void> _launchURL(BuildContext context, String urlString) async {
    final Uri url = Uri.parse(urlString);
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          ToastUtils.showErrorToast(context, 'Could not open link');
        }
      }
    } catch (e) {
      if (context.mounted) {
        ToastUtils.showErrorToast(context, 'Could not open link');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundMilkWhite,
      appBar: AppBar(
        title: Text(
          'Contact Us',
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
              Icons.headset_mic_outlined,
              size: ResponsiveUtils.r(context, 80),
              color: AppColors.primaryTeal,
            ),
            ResponsiveUtils.verticalSpace(context, 24),
            Text(
              'Get In Touch',
              style: AppTextStyles.headline(context).copyWith(
                color: AppColors.textDark,
              ),
              textAlign: TextAlign.center,
            ),
            ResponsiveUtils.verticalSpace(context, 12),
            Text(
              'If you need any assistance regarding jobs, app support, or have any other questions, please contact the DuneShine support team.',
              style: AppTextStyles.body(context).copyWith(
                color: AppColors.textGray,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            ResponsiveUtils.verticalSpace(context, 40),
            
            // Email Contact
            _buildContactCard(
              context: context,
              icon: Icons.email_outlined,
              title: 'Email Us',
              subtitle: 'support@duneshine.ae',
              onTap: () => _launchURL(context, 'mailto:support@duneshine.ae'),
            ),
            
            ResponsiveUtils.verticalSpace(context, 16),
            
            // Phone Contact
            _buildContactCard(
              context: context,
              icon: Icons.phone_outlined,
              title: 'Call Us',
              subtitle: '+971 058 990 1611',
              onTap: () => _launchURL(context, 'tel:+9710589901611'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ResponsiveUtils.r(context, 16)),
        side: const BorderSide(color: AppColors.onDemandBorder),
      ),
      color: AppColors.white,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(ResponsiveUtils.r(context, 16)),
        child: Padding(
          padding: EdgeInsets.all(ResponsiveUtils.w(context, 20)),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(ResponsiveUtils.w(context, 12)),
                decoration: BoxDecoration(
                  color: AppColors.primaryTeal.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
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
                      title,
                      style: AppTextStyles.subtitle(context).copyWith(
                        color: AppColors.textDark,
                      ),
                    ),
                    ResponsiveUtils.verticalSpace(context, 4),
                    Text(
                      subtitle,
                      style: AppTextStyles.body(context).copyWith(
                        color: AppColors.primaryTeal,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: AppColors.textGray,
                size: ResponsiveUtils.r(context, 16),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
