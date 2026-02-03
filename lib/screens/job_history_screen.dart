import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../constants/text_styles.dart';
import '../models/job_model.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../utils/toast_utils.dart';
import '../utils/responsive_utils.dart';

class JobHistoryScreen extends StatefulWidget {
  const JobHistoryScreen({Key? key}) : super(key: key);

  @override
  State<JobHistoryScreen> createState() => _JobHistoryScreenState();
}

class _JobHistoryScreenState extends State<JobHistoryScreen> {
  final ApiService _apiService = ApiService();
  final AuthService _authService = AuthService();

  bool _isLoading = true;
  String? _errorMessage;
  List<Job> _completedJobs = [];

  @override
  void initState() {
    super.initState();
    _fetchCompletedJobs();
  }

  Future<void> _fetchCompletedJobs() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final token = _authService.token;
    if (token == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Not authenticated. Please login again.';
      });
      return;
    }

    final response = await _apiService.getTodaysJobs(token: token);

    if (!mounted) return;

    if (response['success'] == true) {
      final data = response['data'] as Map<String, dynamic>;
      final jobsList = data['jobs'] as List<dynamic>? ?? [];

      setState(() {
        _completedJobs = jobsList
            .map((json) => Job.fromJson(json as Map<String, dynamic>))
            .where((job) => job.isCompleted)
            .toList();
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
        _errorMessage = response['message'] ?? 'Failed to load jobs';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.primaryTeal,
        foregroundColor: AppColors.white,
        title: Text(
          'Job History',
          style: AppTextStyles.title(context).copyWith(
            color: AppColors.white,
            fontSize: ResponsiveUtils.sp(context, 20),
          ),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _fetchCompletedJobs,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primaryTeal),
      );
    }

    if (_errorMessage != null) {
      // Show user-friendly toast instead of raw error text
      ToastUtils.showErrorToast(context, _errorMessage!);

      // Clear error message and show loading state
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Return loading indicator while retrying
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primaryTeal),
      );
    }

    if (_completedJobs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history,
              color: AppColors.lightGray,
              size: ResponsiveUtils.r(context, 80),
            ),
            ResponsiveUtils.verticalSpace(context, 16),
            Text(
              'No completed jobs yet',
              style: AppTextStyles.title(context).copyWith(
                color: AppColors.textGray,
                fontSize: ResponsiveUtils.sp(context, 18),
              ),
            ),
            ResponsiveUtils.verticalSpace(context, 8),
            Text(
              'Your completed jobs will appear here',
              style: AppTextStyles.body(context).copyWith(
                color: AppColors.lightGray,
                fontSize: ResponsiveUtils.sp(context, 14),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(ResponsiveUtils.w(context, 16)),
      itemCount: _completedJobs.length,
      itemBuilder: (context, index) {
        return _buildJobCard(_completedJobs[index]);
      },
    );
  }

  Widget _buildJobCard(Job job) {
    final vehicle = job.booking?.vehicle;
    final timeSlot = job.timeSlot;

    return Container(
      margin: EdgeInsets.only(bottom: ResponsiveUtils.h(context, 12)),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(ResponsiveUtils.r(context, 12)),
        border: Border.all(
          color: AppColors.lightGray.withValues(alpha: 0.3),
          width: ResponsiveUtils.w(context, 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: ResponsiveUtils.r(context, 10),
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(ResponsiveUtils.w(context, 16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Flexible(
                  child: Text(
                    timeSlot?.formattedStartTime ?? 'N/A',
                    style: AppTextStyles.body(context).copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkNavy,
                      fontSize: ResponsiveUtils.sp(context, 16),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(width: ResponsiveUtils.w(context, 8)),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: ResponsiveUtils.w(context, 10),
                    vertical: ResponsiveUtils.h(context, 4),
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(
                      ResponsiveUtils.r(context, 20),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: AppColors.success,
                        size: ResponsiveUtils.r(context, 14),
                      ),
                      SizedBox(width: ResponsiveUtils.w(context, 4)),
                      Text(
                        'Completed',
                        style: AppTextStyles.caption(context).copyWith(
                          color: AppColors.success,
                          fontWeight: FontWeight.bold,
                          fontSize: ResponsiveUtils.sp(context, 12),
                        ),
                        maxLines: 1,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            ResponsiveUtils.verticalSpace(context, 12),
            Row(
              children: [
                Icon(
                  Icons.directions_car,
                  color: AppColors.primaryTeal,
                  size: ResponsiveUtils.r(context, 20),
                ),
                SizedBox(width: ResponsiveUtils.w(context, 8)),
                Expanded(
                  child: Text(
                    vehicle?.displayName ?? 'Vehicle',
                    style: AppTextStyles.body(context).copyWith(
                      color: AppColors.darkNavy,
                      fontSize: ResponsiveUtils.sp(context, 14),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            ResponsiveUtils.verticalSpace(context, 8),
            Row(
              children: [
                Icon(
                  Icons.location_on,
                  color: AppColors.gold,
                  size: ResponsiveUtils.r(context, 20),
                ),
                SizedBox(width: ResponsiveUtils.w(context, 8)),
                Expanded(
                  child: Text(
                    job.booking?.locationName ?? 'Property',
                    style: AppTextStyles.caption(context).copyWith(
                      color: AppColors.textGray,
                      fontSize: ResponsiveUtils.sp(context, 12),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
