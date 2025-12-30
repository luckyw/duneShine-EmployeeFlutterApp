import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../models/employee_profile_model.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

class AccountWidget extends StatefulWidget {
  const AccountWidget({Key? key}) : super(key: key);

  @override
  State<AccountWidget> createState() => _AccountWidgetState();
}

class _AccountWidgetState extends State<AccountWidget> {
  final ApiService _apiService = ApiService();
  final AuthService _authService = AuthService();
  bool _isLoggingOut = false;
  bool _isLoadingProfile = true;
  EmployeeProfileModel? _profile;
  String? _profileError;

  @override
  void initState() {
    super.initState();
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

    if (result['success'] == true) {
      final userData = result['data']['user'] as Map<String, dynamic>;
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

    setState(() {
      _isLoggingOut = false;
    });

    if (mounted) {
      // Clear auth data from secure storage
      await _authService.clearAuthData();

      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Logged out successfully'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }

      // Navigate to login screen
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/login',
        (route) => false,
      );
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
              color: AppColors.darkBlue,
              padding: const EdgeInsets.symmetric(vertical: 24),
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
                                const SizedBox(height: 8),
                                Text(
                                  _profileError!,
                                  style: const TextStyle(color: AppColors.white),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 16),
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
                                  width: 100,
                                  height: 100,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppColors.lightGray,
                                  ),
                                  child: _profile?.idProofImageUrl != null
                                      ? ClipOval(
                                          child: Image.network(
                                            _profile!.idProofImageUrl!,
                                            fit: BoxFit.cover,
                                            width: 100,
                                            height: 100,
                                            errorBuilder:
                                                (context, error, stackTrace) =>
                                                    const Icon(Icons.person,
                                                        size: 60,
                                                        color: AppColors.white),
                                          ),
                                        )
                                      : const Icon(Icons.person,
                                          size: 60, color: AppColors.white),
                                ),
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: AppColors.white,
                                    ),
                                    child: const Icon(Icons.edit,
                                        size: 20, color: AppColors.primaryTeal),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _profile?.name ?? _authService.employeeName,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppColors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (_profile?.phone != null &&
                                _profile!.phone!.isNotEmpty)
                              Text(
                                _profile!.phone!,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppColors.white.withValues(alpha: 0.8),
                                ),
                              ),
                            const SizedBox(height: 12),
                            if (_profile?.vendor != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppColors.gold.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (_profile!.vendorLogoUrl != null)
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(right: 8),
                                        child: ClipOval(
                                          child: Image.network(
                                            _profile!.vendorLogoUrl!,
                                            width: 24,
                                            height: 24,
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (context, error, stackTrace) =>
                                                    const Icon(
                                                        Icons.business,
                                                        size: 16,
                                                        color: AppColors.gold),
                                          ),
                                        ),
                                      ),
                                    Text(
                                      _profile!.vendorName,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: AppColors.gold,
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
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  _buildMenuItem(
                    icon: Icons.history,
                    title: 'Job History',
                    onTap: () {},
                  ),
                  _buildMenuItem(
                    icon: Icons.star,
                    title: 'Performance Rating',
                    // TODO: Add real rating when API is ready
                    onTap: () {},
                  ),
                  _buildMenuItem(
                    icon: Icons.build,
                    title: 'Equipment Support',
                    onTap: () {},
                  ),
                  _buildMenuItem(
                    icon: Icons.settings,
                    title: 'Settings',
                    onTap: () {},
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoggingOut
                      ? null
                      : () {
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
                                  child: const Text('Log Out'),
                                ),
                              ],
                            ),
                          );
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    disabledBackgroundColor: Colors.red.withValues(alpha: 0.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoggingOut
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: AppColors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.logout, color: AppColors.white),
                            SizedBox(width: 8),
                            Text(
                              'Log Out',
                              style: TextStyle(
                                color: AppColors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'App Version 1.2.0',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.lightGray,
              ),
            ),
            const SizedBox(height: 24),
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
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
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
            Icon(icon, color: AppColors.primaryTeal, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.darkNavy,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.lightGray,
                      ),
                    ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios,
                color: AppColors.lightGray, size: 16),
          ],
        ),
      ),
    );
  }
}