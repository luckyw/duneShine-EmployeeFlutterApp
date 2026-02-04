import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../constants/text_styles.dart';
import '../models/job_model.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../utils/toast_utils.dart';
import '../utils/responsive_utils.dart';

class JobDetailsScreen extends StatefulWidget {
  const JobDetailsScreen({Key? key}) : super(key: key);

  @override
  State<JobDetailsScreen> createState() => _JobDetailsScreenState();
}

class _JobDetailsScreenState extends State<JobDetailsScreen> {
  bool _isLoading = true;
  bool _isNavigating = false;
  String? _errorMessage;
  Job? _job;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Fetch job details when dependencies are ready
    if (_isLoading && _job == null && _errorMessage == null) {
      _fetchJobDetails();
    }
  }

  Future<void> _fetchJobDetails() async {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ??
        {};

    // Check if Job object was passed directly
    if (args['job'] != null && args['job'] is Job) {
      setState(() {
        _job = args['job'] as Job;
        _isLoading = false;
      });
      return;
    }

    // Otherwise fetch from API using job ID
    final jobIdStr = args['jobId'] as String? ?? '';
    final jobId = int.tryParse(jobIdStr.replaceAll('JOB-', '')) ?? 0;

    if (jobId == 0) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Invalid job ID';
      });
      return;
    }

    final token = AuthService().token;
    if (token == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Not authenticated. Please login again.';
      });
      return;
    }

    final response = await ApiService().getJobDetails(
      jobId: jobId,
      token: token,
    );
    debugPrint('Job details response: $response');

    if (response['success'] == true) {
      final data = response['data'] as Map<String, dynamic>;
      final jobJson = data['job'] as Map<String, dynamic>?;

      if (jobJson != null) {
        setState(() {
          _job = Job.fromJson(jobJson);
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Job data not found';
        });
      }
    } else {
      setState(() {
        _isLoading = false;
        _errorMessage = response['message'] ?? 'Failed to load job details';
      });
    }
  }

  Future<void> _handleNavigateToJob() async {
    if (_job == null) return;

    final token = AuthService().token;
    if (token == null) {
      ToastUtils.showErrorToast(
        context,
        'Not authenticated. Please login again.',
      );

      return;
    }

    setState(() {
      _isNavigating = true;
    });

    final response = await ApiService().navigateToJob(
      jobId: _job!.id,
      token: token,
    );
    debugPrint('Navigate to job response: $response');

    setState(() {
      _isNavigating = false;
    });

    if (response['success'] == true) {
      final data = response['data'] as Map<String, dynamic>;
      final jobJson = data['job'] as Map<String, dynamic>?;

      // Update local job with new status
      Job updatedJob = _job!;
      if (jobJson != null) {
        // Use mergeWith to preserve booking details from the original job
        updatedJob = _job!.mergeWith(Job.fromJson(jobJson));
        setState(() {
          _job = updatedJob;
        });
      }

      // Navigate to map screen
      if (mounted) {
        final vehicle = updatedJob.booking?.vehicle;
        final carModel = vehicle != null
            ? '${vehicle.brandName} ${vehicle.model}'
            : 'Unknown Vehicle';
        final carColor = vehicle?.color ?? 'Unknown';
        final employeeName = AuthService().employeeName;

        double earnedAmount = 0;
        if (updatedJob.booking != null) {
          for (var service in updatedJob.booking!.servicesPayload) {
            earnedAmount += double.tryParse(service.price) ?? 0;
          }
        }

        Navigator.pushNamed(
          context,
          '/navigate-to-job',
          arguments: {
            'jobId': 'JOB-${updatedJob.id}',
            'carModel': carModel,
            'carColor': carColor,
            'employeeName': employeeName,
            'earnedAmount': earnedAmount,
            'job': updatedJob,
          },
        );
      }
    } else {
      if (mounted) {
        ToastUtils.showErrorToast(
          context,
          response['message'] ?? 'Failed to start navigation',
        );
      }
    }
  }

  /// Refresh job details from API (for pull-to-refresh)
  Future<void> _refreshJobDetails() async {
    final jobId = _job?.id ?? 0;
    if (jobId == 0) return;

    final token = AuthService().token;
    if (token == null) return;

    final response = await ApiService().getJobDetails(
      jobId: jobId,
      token: token,
    );
    debugPrint('Refreshed job details: $response');

    if (response['success'] == true && mounted) {
      final data = response['data'] as Map<String, dynamic>;
      final jobJson = data['job'] as Map<String, dynamic>?;

      if (jobJson != null) {
        setState(() {
          _job = Job.fromJson(jobJson);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.primaryTeal,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Job Details',
          style: AppTextStyles.headline(context).copyWith(
            color: AppColors.white,
            fontSize: ResponsiveUtils.sp(context, 20),
          ),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
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
      return const Center(child: CircularProgressIndicator());
    }

    if (_job == null) {
      return const Center(child: Text('No job data available'));
    }

    return _buildJobContent();
  }

  Widget _buildJobContent() {
    final booking = _job!.booking;
    final property = booking?.property;
    final customer = booking?.customer;
    final vehicle = booking?.vehicle;

    final carModel = vehicle != null
        ? '${vehicle.brandName} ${vehicle.model}'
        : 'Unknown Vehicle';
    final carColor = vehicle?.color ?? 'Unknown';
    final jobId = 'JOB-${_job!.id}';

    // Calculate total price from services
    double earnedAmount = 0;
    if (booking != null) {
      for (var service in booking.servicesPayload) {
        earnedAmount += double.tryParse(service.price) ?? 0;
      }
    }

    // Get services list
    final services = booking?.servicesPayload ?? [];
    final serviceName = services.isNotEmpty ? services.first.name : 'Car Wash';

    return RefreshIndicator(
      onRefresh: _refreshJobDetails,
      color: AppColors.primaryTeal,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Header with Gradient
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primaryTeal,
                    AppColors.primaryTeal.withValues(alpha: 0.85),
                  ],
                ),
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: EdgeInsets.all(ResponsiveUtils.w(context, 20)),
                  child: Column(
                    children: [
                      // Job ID and Status Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: ResponsiveUtils.w(context, 14),
                              vertical: ResponsiveUtils.h(context, 8),
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(
                                ResponsiveUtils.r(context, 20),
                              ),
                            ),
                            child: Text(
                              jobId,
                              style: AppTextStyles.caption(context).copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: ResponsiveUtils.w(context, 14),
                              vertical: ResponsiveUtils.h(context, 8),
                            ),
                            decoration: BoxDecoration(
                              color: _getStatusColor(_job!.status),
                              borderRadius: BorderRadius.circular(
                                ResponsiveUtils.r(context, 20),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: _getStatusColor(_job!.status)
                                      .withValues(alpha: 0.4),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Text(
                              _job!.displayStatus,
                              style: AppTextStyles.caption(context).copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      ResponsiveUtils.verticalSpace(context, 20),
                      // Vehicle Info
                      Row(
                        children: [
                          // Vehicle Image or Icon
                          Container(
                            width: ResponsiveUtils.w(context, 80),
                            height: ResponsiveUtils.h(context, 60),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(
                                ResponsiveUtils.r(context, 12),
                              ),
                            ),
                            child: vehicle?.imageUrl != null && vehicle!.imageUrl!.isNotEmpty
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(
                                      ResponsiveUtils.r(context, 12),
                                    ),
                                    child: Image.network(
                                      vehicle.imageUrl!,
                                      fit: BoxFit.cover,
                                      loadingBuilder: (context, child, loadingProgress) {
                                        if (loadingProgress == null) return child;
                                        return Center(
                                          child: SizedBox(
                                            width: ResponsiveUtils.w(context, 20),
                                            height: ResponsiveUtils.h(context, 20),
                                            child: CircularProgressIndicator(
                                              color: Colors.white.withValues(alpha: 0.7),
                                              strokeWidth: 2,
                                            ),
                                          ),
                                        );
                                      },
                                      errorBuilder: (context, error, stackTrace) => Center(
                                        child: Icon(
                                          Icons.directions_car_rounded,
                                          color: Colors.white,
                                          size: ResponsiveUtils.r(context, 32),
                                        ),
                                      ),
                                    ),
                                  )
                                : Center(
                                    child: Icon(
                                      Icons.directions_car_rounded,
                                      color: Colors.white,
                                      size: ResponsiveUtils.r(context, 32),
                                    ),
                                  ),
                          ),
                          ResponsiveUtils.horizontalSpace(context, 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  carModel,
                                  style: AppTextStyles.headline(context).copyWith(
                                    color: Colors.white,
                                    fontSize: ResponsiveUtils.sp(context, 22),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                ResponsiveUtils.verticalSpace(context, 8),
                                Row(
                                  children: [
                                    Text(
                                      carColor,
                                      style: AppTextStyles.body(context).copyWith(
                                        color: Colors.white.withValues(alpha: 0.9),
                                      ),
                                    ),
                                    ResponsiveUtils.horizontalSpace(context, 16),
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: ResponsiveUtils.w(context, 10),
                                        vertical: ResponsiveUtils.h(context, 4),
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(
                                          ResponsiveUtils.r(context, 6),
                                        ),
                                      ),
                                      child: Text(
                                        vehicle?.numberPlate ?? '',
                                        style: AppTextStyles.caption(context).copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Content Area
            Padding(
              padding: EdgeInsets.all(ResponsiveUtils.w(context, 16)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Customer Card
                  _buildSectionCard(
                    icon: Icons.person_rounded,
                    iconColor: AppColors.primaryTeal,
                    title: 'Customer',
                    child: Row(
                      children: [
                        Container(
                          width: ResponsiveUtils.w(context, 56),
                          height: ResponsiveUtils.h(context, 56),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.primaryTeal.withValues(alpha: 0.2),
                                AppColors.primaryTeal.withValues(alpha: 0.1),
                              ],
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: customer?.idProofImageUrl != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(
                                    ResponsiveUtils.r(context, 28),
                                  ),
                                  child: Image.network(
                                    customer!.idProofImageUrl!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) =>
                                        Icon(
                                      Icons.person_rounded,
                                      color: AppColors.primaryTeal,
                                      size: ResponsiveUtils.r(context, 28),
                                    ),
                                  ),
                                )
                              : Icon(
                                  Icons.person_rounded,
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
                                customer?.name ?? 'Unknown Customer',
                                style: AppTextStyles.title(context).copyWith(
                                  color: AppColors.darkNavy,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              ResponsiveUtils.verticalSpace(context, 4),
                              Row(
                                children: [
                                  Icon(
                                    Icons.phone_rounded,
                                    size: ResponsiveUtils.r(context, 16),
                                    color: AppColors.lightGray,
                                  ),
                                  ResponsiveUtils.horizontalSpace(context, 6),
                                  Text(
                                    customer?.phone ?? 'No phone',
                                    style: AppTextStyles.body(context).copyWith(
                                      color: AppColors.textGray,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  ResponsiveUtils.verticalSpace(context, 16),

                  // Location Card
                  if (booking?.fullAddress != null &&
                      booking!.fullAddress.isNotEmpty &&
                      !booking.fullAddress.toLowerCase().contains('unknown'))
                    Column(
                      children: [
                        _buildSectionCard(
                          icon: Icons.location_on_rounded,
                          iconColor: Colors.redAccent,
                          title: 'Location',
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                booking.locationName,
                                style: AppTextStyles.title(context).copyWith(
                                  color: AppColors.darkNavy,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              ResponsiveUtils.verticalSpace(context, 8),
                              Container(
                                padding: EdgeInsets.all(
                                  ResponsiveUtils.w(context, 12),
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(
                                    ResponsiveUtils.r(context, 10),
                                  ),
                                  border: Border.all(
                                    color: Colors.grey.shade200,
                                  ),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(
                                      Icons.map_rounded,
                                      size: ResponsiveUtils.r(context, 18),
                                      color: AppColors.lightGray,
                                    ),
                                    ResponsiveUtils.horizontalSpace(context, 10),
                                    Expanded(
                                      child: Text(
                                        booking.fullAddress,
                                        style: AppTextStyles.body(context).copyWith(
                                          color: AppColors.textGray,
                                          height: 1.4,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (property?.zone != null) ...[
                                ResponsiveUtils.verticalSpace(context, 8),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.grid_view_rounded,
                                      size: ResponsiveUtils.r(context, 16),
                                      color: AppColors.lightGray,
                                    ),
                                    ResponsiveUtils.horizontalSpace(context, 8),
                                    Text(
                                      'Zone: ${property!.zone}',
                                      style: AppTextStyles.caption(context).copyWith(
                                        color: AppColors.textGray,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                        ResponsiveUtils.verticalSpace(context, 16),
                      ],
                    ),

                  // Services Card
                  _buildSectionCard(
                    icon: Icons.local_car_wash_rounded,
                    iconColor: AppColors.gold,
                    title: 'Services',
                    trailing: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: ResponsiveUtils.w(context, 12),
                        vertical: ResponsiveUtils.h(context, 6),
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.gold,
                            AppColors.gold.withValues(alpha: 0.85),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(
                          ResponsiveUtils.r(context, 16),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.gold.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.star_rounded,
                            color: Colors.white,
                            size: ResponsiveUtils.r(context, 14),
                          ),
                          SizedBox(width: ResponsiveUtils.w(context, 4)),
                          Text(
                            serviceName,
                            style: AppTextStyles.caption(context).copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    child: Column(
                      children: [
                        // Services List
                        if (services.isNotEmpty)
                          ...services.map(
                            (service) => _buildServiceItem(
                              service.name,
                              Icons.check_circle_rounded,
                              price: '\$${service.price}',
                            ),
                          )
                        else
                          _buildServiceItem(
                            'Car Wash Service',
                            Icons.check_circle_rounded,
                          ),

                        ResponsiveUtils.verticalSpace(context, 16),

                        // Total Earnings
                        Container(
                          padding: EdgeInsets.all(ResponsiveUtils.w(context, 16)),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.gold.withValues(alpha: 0.15),
                                AppColors.gold.withValues(alpha: 0.08),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(
                              ResponsiveUtils.r(context, 14),
                            ),
                            border: Border.all(
                              color: AppColors.gold.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(
                                      ResponsiveUtils.w(context, 8),
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.gold.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(
                                        ResponsiveUtils.r(context, 8),
                                      ),
                                    ),
                                    child: Icon(
                                      Icons.attach_money_rounded,
                                      color: AppColors.gold,
                                      size: ResponsiveUtils.r(context, 20),
                                    ),
                                  ),
                                  ResponsiveUtils.horizontalSpace(context, 12),
                                  Text(
                                    'Total Earnings',
                                    style: AppTextStyles.body(context).copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.darkNavy,
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                '\$${earnedAmount.toStringAsFixed(2)}',
                                style: AppTextStyles.headline(context).copyWith(
                                  color: AppColors.gold,
                                  fontWeight: FontWeight.bold,
                                  fontSize: ResponsiveUtils.sp(context, 24),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  ResponsiveUtils.verticalSpace(context, 24),

                  // Navigate Button
                  Container(
                    width: double.infinity,
                    height: ResponsiveUtils.h(context, 60),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primaryTeal,
                          AppColors.primaryTeal.withValues(alpha: 0.9),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(
                        ResponsiveUtils.r(context, 16),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryTeal.withValues(alpha: 0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: _isNavigating ? null : _handleNavigateToJob,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            ResponsiveUtils.r(context, 16),
                          ),
                        ),
                      ),
                      child: _isNavigating
                          ? SizedBox(
                              width: ResponsiveUtils.w(context, 24),
                              height: ResponsiveUtils.h(context, 24),
                              child: CircularProgressIndicator(
                                color: AppColors.white,
                                strokeWidth: ResponsiveUtils.w(context, 2.5),
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.navigation_rounded,
                                  color: Colors.white,
                                  size: ResponsiveUtils.r(context, 24),
                                ),
                                ResponsiveUtils.horizontalSpace(context, 10),
                                Text(
                                  'Navigate to Job',
                                  style: AppTextStyles.button(context).copyWith(
                                    color: Colors.white,
                                    fontSize: ResponsiveUtils.sp(context, 17),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                  ResponsiveUtils.verticalSpace(context, 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds a styled section card with icon header
  Widget _buildSectionCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required Widget child,
    Widget? trailing,
  }) {
    return Container(
      padding: EdgeInsets.all(ResponsiveUtils.w(context, 18)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(ResponsiveUtils.r(context, 18)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(ResponsiveUtils.w(context, 10)),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(
                    ResponsiveUtils.r(context, 12),
                  ),
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: ResponsiveUtils.r(context, 22),
                ),
              ),
              ResponsiveUtils.horizontalSpace(context, 12),
              Text(
                title,
                style: AppTextStyles.caption(context).copyWith(
                  color: AppColors.lightGray,
                  fontWeight: FontWeight.w600,
                  fontSize: ResponsiveUtils.sp(context, 13),
                  letterSpacing: 0.5,
                ),
              ),
              const Spacer(),
              if (trailing != null) trailing,
            ],
          ),
          ResponsiveUtils.verticalSpace(context, 16),
          child,
        ],
      ),
    );
  }

  /// Builds a styled service item row
  Widget _buildServiceItem(String name, IconData icon, {String? price}) {
    return Padding(
      padding: EdgeInsets.only(bottom: ResponsiveUtils.h(context, 10)),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: ResponsiveUtils.w(context, 14),
          vertical: ResponsiveUtils.h(context, 14),
        ),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(ResponsiveUtils.r(context, 12)),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: AppColors.success,
              size: ResponsiveUtils.r(context, 22),
            ),
            ResponsiveUtils.horizontalSpace(context, 14),
            Expanded(
              child: Text(
                name,
                style: AppTextStyles.body(context).copyWith(
                  fontWeight: FontWeight.w500,
                  color: AppColors.darkNavy,
                ),
              ),
            ),
            if (price != null)
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: ResponsiveUtils.w(context, 12),
                  vertical: ResponsiveUtils.h(context, 6),
                ),
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(
                    ResponsiveUtils.r(context, 8),
                  ),
                ),
                child: Text(
                  price,
                  style: AppTextStyles.body(context).copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.gold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _getColorFromName(String colorName) {
    switch (colorName.toLowerCase()) {
      case 'blue':
        return Colors.blue;
      case 'red':
        return Colors.red;
      case 'white':
        return Colors.white;
      case 'black':
        return Colors.black;
      case 'silver':
        return Colors.grey.shade400;
      case 'grey':
      case 'gray':
        return Colors.grey;
      case 'green':
        return Colors.green;
      case 'yellow':
        return Colors.yellow;
      case 'orange':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'assigned':
        return Colors.blue;
      case 'in_progress':
        return Colors.orange;
      case 'completed':
        return AppColors.success;
      case 'cancelled':
        return AppColors.error;
      default:
        return AppColors.textGray;
    }
  }
}
