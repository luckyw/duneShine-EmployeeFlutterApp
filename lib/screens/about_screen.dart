import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../constants/text_styles.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.primaryTeal,
        foregroundColor: AppColors.white,
        title: const Text('About DuneShine'),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Logo and app info header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                color: AppColors.primaryTeal,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(40),
                  bottomRight: Radius.circular(40),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Image.asset(
                        'assets/images/app_logo.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'DuneShine Employee',
                    style: AppTextStyles.headline(context).copyWith(
                      color: AppColors.white,
                      fontSize: 28,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Version 1.2.0',
                    style: AppTextStyles.body(context).copyWith(
                      color: AppColors.white.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // About description
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'DuneShine is a premium car care service that brings professional detailing to your doorstep. As a DuneShine employee, you\'re part of a team dedicated to providing exceptional car care services.',
                textAlign: TextAlign.center,
                style: AppTextStyles.body(context).copyWith(
                  color: AppColors.textGray,
                  height: 1.6,
                ),
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Links section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  _buildLinkTile(
                    context,
                    icon: Icons.language,
                    title: 'Visit Website',
                    subtitle: 'www.duneshine.com',
                    onTap: () {
                      // TODO: Open URL in future
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Website coming soon!'),
                          backgroundColor: AppColors.primaryTeal,
                        ),
                      );
                    },
                  ),
                  _buildLinkTile(
                    context,
                    icon: Icons.description,
                    title: 'Terms of Service',
                    onTap: () {
                      // TODO: Open URL in future
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Terms of Service coming soon!'),
                          backgroundColor: AppColors.primaryTeal,
                        ),
                      );
                    },
                  ),
                  _buildLinkTile(
                    context,
                    icon: Icons.privacy_tip,
                    title: 'Privacy Policy',
                    onTap: () {
                      // TODO: Open URL in future
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Privacy Policy coming soon!'),
                          backgroundColor: AppColors.primaryTeal,
                        ),
                      );
                    },
                  ),
                  _buildLinkTile(
                    context,
                    icon: Icons.star,
                    title: 'Rate App',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('App Store rating coming soon!'),
                          backgroundColor: AppColors.primaryTeal,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Social media
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  Text(
                    'Follow Us',
                    style: AppTextStyles.title(context).copyWith(
                      color: AppColors.darkNavy,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildSocialButton(
                        icon: Icons.facebook,
                        onTap: () {},
                      ),
                      const SizedBox(width: 16),
                      _buildSocialButton(
                        icon: Icons.camera_alt,
                        onTap: () {},
                      ),
                      const SizedBox(width: 16),
                      _buildSocialButton(
                        icon: Icons.alternate_email,
                        onTap: () {},
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 40),
            
            // Copyright
            Text(
              '© 2024 DuneShine. All rights reserved.',
              style: AppTextStyles.caption(context).copyWith(
                color: AppColors.lightGray,
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildLinkTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.veryLightGray,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primaryTeal.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.primaryTeal, size: 24),
        ),
        title: Text(
          title,
          style: AppTextStyles.body(context).copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.darkNavy,
          ),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle,
                style: AppTextStyles.caption(context).copyWith(
                  color: AppColors.textGray,
                ),
              )
            : null,
        trailing: Icon(
          Icons.arrow_forward_ios,
          color: AppColors.lightGray,
          size: 16,
        ),
        onTap: onTap,
      ),
    );
  }

  Widget _buildSocialButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.primaryTeal.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: AppColors.primaryTeal,
          size: 28,
        ),
      ),
    );
  }
}
