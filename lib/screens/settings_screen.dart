import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../constants/text_styles.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _jobReminders = true;
  bool _soundEnabled = true;
  String _selectedLanguage = 'English';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.primaryTeal,
        foregroundColor: AppColors.white,
        title: const Text('Settings'),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            
            // Notifications section
            _buildSectionHeader('Notifications'),
            _buildSwitchTile(
              icon: Icons.notifications,
              title: 'Push Notifications',
              subtitle: 'Receive push notifications',
              value: _notificationsEnabled,
              onChanged: (value) {
                setState(() {
                  _notificationsEnabled = value;
                });
              },
            ),
            _buildSwitchTile(
              icon: Icons.alarm,
              title: 'Job Reminders',
              subtitle: 'Get reminded before scheduled jobs',
              value: _jobReminders,
              onChanged: (value) {
                setState(() {
                  _jobReminders = value;
                });
              },
            ),
            _buildSwitchTile(
              icon: Icons.volume_up,
              title: 'Sound',
              subtitle: 'Play sound for notifications',
              value: _soundEnabled,
              onChanged: (value) {
                setState(() {
                  _soundEnabled = value;
                });
              },
            ),
            
            const SizedBox(height: 24),
            
            // App Preferences section
            _buildSectionHeader('App Preferences'),
            _buildListTile(
              icon: Icons.language,
              title: 'Language',
              trailing: Text(
                _selectedLanguage,
                style: AppTextStyles.body(context).copyWith(
                  color: AppColors.primaryTeal,
                ),
              ),
              onTap: () {
                _showLanguageDialog();
              },
            ),
            _buildListTile(
              icon: Icons.dark_mode,
              title: 'Dark Mode',
              trailing: Text(
                'Coming Soon',
                style: AppTextStyles.caption(context).copyWith(
                  color: AppColors.lightGray,
                ),
              ),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Dark mode coming soon!'),
                    backgroundColor: AppColors.primaryTeal,
                  ),
                );
              },
            ),
            
            const SizedBox(height: 24),
            
            // Data section
            _buildSectionHeader('Data'),
            _buildListTile(
              icon: Icons.cached,
              title: 'Clear Cache',
              onTap: () {
                _showClearCacheDialog();
              },
            ),
            
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        title,
        style: AppTextStyles.title(context).copyWith(
          color: AppColors.primaryTeal,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
        trailing: Switch(
          value: value,
          onChanged: onChanged,
          activeColor: AppColors.primaryTeal,
        ),
      ),
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required String title,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
        trailing: trailing ?? Icon(
          Icons.arrow_forward_ios,
          color: AppColors.lightGray,
          size: 16,
        ),
        onTap: onTap,
      ),
    );
  }

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Language'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildLanguageOption('English'),
            _buildLanguageOption('العربية'),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageOption(String language) {
    return ListTile(
      title: Text(language),
      trailing: _selectedLanguage == language
          ? Icon(Icons.check, color: AppColors.primaryTeal)
          : null,
      onTap: () {
        setState(() {
          _selectedLanguage = language;
        });
        Navigator.pop(context);
      },
    );
  }

  void _showClearCacheDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cache'),
        content: const Text('Are you sure you want to clear the app cache?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Cache cleared successfully'),
                  backgroundColor: AppColors.success,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryTeal,
            ),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }
}
