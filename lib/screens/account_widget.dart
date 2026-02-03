import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constants/colors.dart';
import '../constants/text_styles.dart';
import '../utils/responsive_utils.dart';
import '../models/employee_profile_model.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import 'job_history_screen.dart';
import 'performance_rating_screen.dart';
import 'equipment_support_screen.dart';
import 'settings_screen.dart';
import 'help_support_screen.dart';
import 'customer_lookup_screen.dart';

import '../utils/toast_utils.dart';
import '../services/background_location_service.dart';


class AccountWidget extends StatefulWidget {
  final VoidCallback? onShiftEnded;
  final bool isShiftStarted;

  const AccountWidget({
    Key? key, 
    this.onShiftEnded,
    required this.isShiftStarted,
  }) : super(key: key);

  @override
  State<AccountWidget> createState() => _AccountWidgetState();
}

class _AccountWidgetState extends State<AccountWidget> {
  final ApiService _apiService = ApiService();
  final AuthService _authService = AuthService();
  bool _isLoggingOut = false;
  bool _isEndingShift = false;
  bool _isLoadingProfile = true;
  EmployeeProfileModel? _profile;
  String? _profileError;
  bool _isShiftStarted = false;

  @override
  void initState() {
    super.initState();
    _isShiftStarted = widget.isShiftStarted;
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    setState(() {
      _isLoadingProfile = true;
      _profileError = null;
    });

    final token = _authService.token;
    if (token == null) {
      setState(() {
        _isLoadingProfile = false;
        _profileError = 'Not authenticated';
      });
      return;
    }

    final result = await _apiService.getProfile(token: token);

    if (!mounted) return;
    if (result['success'] == true) {
      final userData = result['data']['user'] as Map<String, dynamic>;
      final sessionStatus = result['data']['session_status'];
      
      // Sync shift status
      if (sessionStatus != null) {
        final bool apiShiftStarted = sessionStatus == 1 || sessionStatus == true || sessionStatus == '1';
        if (_isShiftStarted != apiShiftStarted) {
          _authService.setShiftStatus(apiShiftStarted);
          setState(() {
            _isShiftStarted = apiShiftStarted;
          });
        }
      }

      setState(() {
        _profile = EmployeeProfileModel.fromJson(userData);
        _isLoadingProfile = false;
      });
    } else {
      setState(() {
        _isLoadingProfile = false;
        _profileError = result['message'] ?? 'Failed to load profile';
      });
    }
  }

  Future<void> _handleCheckOut() async {
    final token = _authService.token;
    if (token == null) return;

    setState(() {
      _isEndingShift = true;
    });

    final result = await _apiService.checkOut(token: token);

    if (mounted) {
      if (result['success'] == true) {
        _authService.setShiftStatus(false);
        setState(() {
          _isShiftStarted = false;
          _isEndingShift = false;
        });
        
        // Stop background tracking service
        BackgroundLocationService.stop();
        
        ToastUtils.showSuccessToast(context, 'Shift ended successfully');
        widget.onShiftEnded?.call();
      } else {
        setState(() {
          _isEndingShift = false;
        });
        
        final String errorMessage = result['message']?.toString() ?? 'Failed to end shift';
        
        // If backend says no active session, we should just sync locally as the goal of ending the shift is achieved
        if (errorMessage.toLowerCase().contains('no active session')) {
          _authService.setShiftStatus(false);
          setState(() {
            _isShiftStarted = false;
          });
          
          // Stop background tracking service
          BackgroundLocationService.stop();
          
          ToastUtils.showSuccessToast(context, 'Shift status synchronized');
          widget.onShiftEnded?.call();
        } else {
          ToastUtils.showErrorToast(context, errorMessage);
        }
      }
    }
  }

  Future<void> _performLogout() async {
    final token = _authService.token;
    if (token == null) {
      // No token, just clear and navigate
      await _authService.clearAuthData();
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/login',
          (route) => false,
        );
      }
      return;
    }

    setState(() {
      _isLoggingOut = true;
    });

    final result = await _apiService.logout(token: token);

    if (!mounted) return;
    setState(() {
      _isLoggingOut = false;
    });

    if (mounted) {
      // Clear auth data from secure storage
      await _authService.clearAuthData();
      
      if (!mounted) return; // In case clearAuthData was slow

      if (result['success'] == true) {
        ToastUtils.showSuccessToast(context, 'Logged out successfully');

      }

      // Navigate to login screen
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/login',
        (route) => false,
      );
    }
  }

  Future<void> _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ToastUtils.showErrorToast(context, 'Could not launch website');

      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _fetchProfile,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              color: AppColors.primaryTeal,
              padding: EdgeInsets.symmetric(vertical: ResponsiveUtils.h(context, 24)),
              child: _isLoadingProfile
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(40),
                        child: CircularProgressIndicator(color: AppColors.white),
                      ),
                    )
                  : _profileError != null
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              children: [
                                const Icon(Icons.error_outline,
                                    color: Colors.red, size: 48),
                                ResponsiveUtils.verticalSpace(context, 8),
                                Text(
                                  _profileError!,
                                  style: const TextStyle(color: AppColors.white),
                                  textAlign: TextAlign.center,
                                ),
                                ResponsiveUtils.verticalSpace(context, 16),
                                ElevatedButton(
                                  onPressed: _fetchProfile,
                                  child: const Text('Retry'),
                                ),
                              ],
                            ),
                          ),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Stack(
                              children: [
                                Container(
                                  width: ResponsiveUtils.r(context, 100),
                                  height: ResponsiveUtils.r(context, 100),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppColors.lightGray,
                                  ),
                                  child: _profile?.idProofImageUrl != null
                                      ? ClipOval(
                                          child: Image.network(
                                            _profile!.idProofImageUrl!,
                                            fit: BoxFit.cover,
                                            width: ResponsiveUtils.r(context, 100),
                                            height: ResponsiveUtils.r(context, 100),
                                            errorBuilder:
                                                (context, error, stackTrace) =>
                                                    Icon(Icons.person,
                                                        size: ResponsiveUtils.r(context, 60),
                                                        color: AppColors.white),
                                          ),
                                        )
                                      : Icon(Icons.person,
                                          size: ResponsiveUtils.r(context, 60), color: AppColors.white),
                                ),
                                ],
                              ),

                            ResponsiveUtils.verticalSpace(context, 16),
                            Text(
                              _profile?.name ?? _authService.employeeName,
                              style: AppTextStyles.headline(context).copyWith(
                                color: AppColors.white,
                              ),
                            ),
                            ResponsiveUtils.verticalSpace(context, 8),
                            if (_profile?.phone != null &&
                                _profile!.phone!.isNotEmpty)
                              Text(
                                _profile!.phone!,
                                style: AppTextStyles.body(context).copyWith(
                                  color: AppColors.white.withValues(alpha: 0.8),
                                ),
                              ),

                            ResponsiveUtils.verticalSpace(context, 12),
                            if (_profile?.vendor != null)
                              Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: ResponsiveUtils.w(context, 12), vertical: ResponsiveUtils.h(context, 6)),
                                decoration: BoxDecoration(
                                  color: AppColors.gold.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(ResponsiveUtils.r(context, 20)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (_profile!.vendorLogoUrl != null)
                                      Padding(
                                        padding:
                                            EdgeInsets.only(right: ResponsiveUtils.w(context, 8)),
                                        child: ClipOval(
                                          child: Image.network(
                                            _profile!.vendorLogoUrl!,
                                            width: ResponsiveUtils.r(context, 24),
                                            height: ResponsiveUtils.r(context, 24),
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (context, error, stackTrace) =>
                                                    Icon(
                                                        Icons.business,
                                                        size: ResponsiveUtils.r(context, 16),
                                                        color: AppColors.gold),
                                          ),
                                        ),
                                      ),
                                    Flexible(
                                      child: Text(
                                        _profile!.vendorName,
                                        style: AppTextStyles.caption(context).copyWith(
                                          fontWeight: FontWeight.w500,
                                          color: AppColors.gold,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
            ),
            // TODO: Uncomment when earnings API is integrated
            // const SizedBox(height: 24),
            // Container(
            //   width: double.infinity,
            //   padding: const EdgeInsets.all(20),
            //   decoration: BoxDecoration(
            //     color: AppColors.gold,
            //     borderRadius: BorderRadius.circular(16),
            //   ),
            //   child: Column(
            //     children: [
            //       const Text('Weekly Earnings', style: TextStyle(fontSize: 14, color: AppColors.darkNavy)),
            //       const SizedBox(height: 8),
            //       const Text('350.00 AED', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.white)),
            //       const SizedBox(height: 8),
            //       const Text('12 Jobs Completed', style: TextStyle(fontSize: 14, color: AppColors.darkNavy)),
            //     ],
            //   ),
            // ),
            ResponsiveUtils.verticalSpace(context, 24),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: ResponsiveUtils.w(context, 16)),
              child: Column(
                children: [
                  _buildMenuItem(
                    icon: Icons.history,
                    title: 'Job History',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const JobHistoryScreen(),
                        ),
                      );
                    },
                  ),
                  _buildMenuItem(
                    icon: Icons.star,
                    title: 'Performance Rating',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const PerformanceRatingScreen(),
                        ),
                      );
                    },
                  ),
                  _buildMenuItem(
                    icon: Icons.build,
                    title: 'Equipment Support',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const EquipmentSupportScreen(),
                        ),
                      );
                    },
                  ),
                  _buildMenuItem(
                    icon: Icons.settings,
                    title: 'Settings',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SettingsScreen(),
                        ),
                      );
                    },
                  ),
                  _buildMenuItem(
                    icon: Icons.help_outline,
                    title: 'Help & Support',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const HelpSupportScreen(),
                        ),
                      );
                    },
                  ),
                  _buildMenuItem(
                    icon: Icons.info_outline,
                    title: 'About DuneShine',
                    onTap: () => _launchURL('https://duneshine.bztechhub.com'),
                  ),
                   _buildMenuItem(
                    icon: Icons.autorenew,
                    title: 'Reactivate Subscription of User',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CustomerLookupScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            ResponsiveUtils.verticalSpace(context, 24),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: ResponsiveUtils.w(context, 16)),
                child: Column(
                  children: [
                    // End Shift button (Always show for debugging)
                    if (widget.isShiftStarted || _isShiftStarted) ...[
                      SizedBox(
                        width: double.infinity,
                        height: ResponsiveUtils.h(context, 56),
                        child: ElevatedButton.icon(
                          onPressed: _isEndingShift ? null : _handleCheckOut,
                          icon: _isEndingShift
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: AppColors.white),
                                )
                              : const Icon(Icons.stop_circle_outlined, color: AppColors.white),
                          label: Text(
                            'End Shift',
                            style: AppTextStyles.button(context).copyWith(
                              color: AppColors.white,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange.shade700,
                            foregroundColor: AppColors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                  ResponsiveUtils.r(context, 12)),
                            ),
                          ),
                        ),
                      ),
                      ResponsiveUtils.verticalSpace(context, 16),
                    ],

                    SizedBox(
                      width: double.infinity,
                      height: ResponsiveUtils.h(context, 56),
                      child: OutlinedButton(
                  onPressed: _isLoggingOut
                      ? null
                      : () {
                          // Prevent logout if shift is active
                          if (widget.isShiftStarted || _isShiftStarted) {
                            ToastUtils.showErrorToast(context, 'Please end your shift before logging out');
                            return;
                          }
                          
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Log Out?'),
                              content: const Text(
                                  'Are you sure you want to log out?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    _performLogout();
                                  },
                                  child: const Text('Log Out', style: TextStyle(color: Colors.red)),
                                ),
                              ],
                            ),
                          );
                        },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red, width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(ResponsiveUtils.r(context, 12)),
                    ),
                  ),
                  child: _isLoggingOut
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.red,
                            strokeWidth: 2,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.logout, color: Colors.red, size: ResponsiveUtils.r(context, 24)),
                            ResponsiveUtils.horizontalSpace(context, 8),
                            Text(
                              'Log Out',
                              style: AppTextStyles.button(context).copyWith(
                                color: Colors.red,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              ],
            ),
            ),

            ResponsiveUtils.verticalSpace(context, 16),
            Text(
              'App Version 1.2.0',
              style: AppTextStyles.caption(context).copyWith(
                color: AppColors.lightGray,
              ),
            ),
            ResponsiveUtils.verticalSpace(context, 24),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
            vertical: ResponsiveUtils.h(context, 16),
            horizontal: ResponsiveUtils.w(context, 12)),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: AppColors.veryLightGray,
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primaryTeal, size: ResponsiveUtils.r(context, 24)),
            ResponsiveUtils.horizontalSpace(context, 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.body(context).copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkNavy,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle,
                      style: AppTextStyles.caption(context).copyWith(
                        color: AppColors.lightGray,
                      ),
                    ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios,
                color: AppColors.lightGray, size: ResponsiveUtils.r(context, 16)),
          ],
        ),
      ),
    );
  }
}