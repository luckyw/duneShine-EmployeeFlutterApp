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
    final employeeName = AuthService().employeeName;

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
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: EdgeInsets.all(ResponsiveUtils.w(context, 16)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Card 1: Car Information & Address
              Container(
                padding: EdgeInsets.all(ResponsiveUtils.w(context, 16)),
                decoration: BoxDecoration(
                  color: AppColors.veryLightGray,
                  borderRadius: BorderRadius.circular(
                    ResponsiveUtils.r(context, 16),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: ResponsiveUtils.r(context, 8),
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(
                            ResponsiveUtils.w(context, 10),
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.gold.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(
                              ResponsiveUtils.r(context, 12),
                            ),
                          ),
                          child: Icon(
                            Icons.directions_car,
                            color: AppColors.gold,
                            size: ResponsiveUtils.r(context, 28),
                          ),
                        ),
                        ResponsiveUtils.horizontalSpace(context, 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                carModel,
                                style: AppTextStyles.title(context).copyWith(
                                  fontSize: ResponsiveUtils.sp(context, 18),
                                  color: AppColors.darkNavy,
                                ),
                              ),
                              ResponsiveUtils.verticalSpace(context, 4),
                              Row(
                                children: [
                                  Container(
                                    width: ResponsiveUtils.w(context, 14),
                                    height: ResponsiveUtils.h(context, 14),
                                    decoration: BoxDecoration(
                                      color: _getColorFromName(carColor),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.grey.shade300,
                                        width: ResponsiveUtils.w(context, 1),
                                      ),
                                    ),
                                  ),
                                  ResponsiveUtils.horizontalSpace(context, 6),
                                  Text(
                                    carColor,
                                    style: AppTextStyles.body(
                                      context,
                                    ).copyWith(color: AppColors.lightGray),
                                  ),
                                  ResponsiveUtils.horizontalSpace(context, 12),
                                  Flexible(
                                    child: Text(
                                      '• ${vehicle?.numberPlate ?? ''}',
                                      style: AppTextStyles.body(context)
                                          .copyWith(
                                            color: AppColors.textGray,
                                            fontWeight: FontWeight.w500,
                                          ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: ResponsiveUtils.w(context, 10),
                            vertical: ResponsiveUtils.h(context, 6),
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryTeal.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(
                              ResponsiveUtils.r(context, 8),
                            ),
                          ),
                          child: Text(
                            jobId,
                            style: AppTextStyles.caption(context).copyWith(
                              color: AppColors.primaryTeal,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    ResponsiveUtils.verticalSpace(context, 16),
                    Divider(height: ResponsiveUtils.h(context, 40)),
                    if (booking?.fullAddress != null &&
                        booking!.fullAddress.isNotEmpty &&
                        !booking.fullAddress.toLowerCase().contains(
                          'unknown',
                        )) ...[
                      ResponsiveUtils.verticalSpace(context, 16),
                      // Address Section
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: EdgeInsets.all(
                              ResponsiveUtils.w(context, 8),
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(
                                ResponsiveUtils.r(context, 8),
                              ),
                            ),
                            child: Icon(
                              Icons.location_on,
                              color: Colors.redAccent,
                              size: ResponsiveUtils.r(context, 20),
                            ),
                          ),
                          ResponsiveUtils.horizontalSpace(context, 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Property Details',
                                  style: AppTextStyles.caption(context)
                                      .copyWith(
                                        color: AppColors.lightGray,
                                        fontWeight: FontWeight.w500,
                                      ),
                                ),
                                ResponsiveUtils.verticalSpace(context, 4),
                                Text(
                                  booking.locationName,
                                  style: AppTextStyles.body(context).copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.darkNavy,
                                  ),
                                ),
                                ResponsiveUtils.verticalSpace(context, 2),
                                Text(
                                  booking.fullAddress,
                                  style: AppTextStyles.caption(context)
                                      .copyWith(
                                        color: AppColors.lightGray,
                                        fontSize: ResponsiveUtils.sp(
                                          context,
                                          13,
                                        ),
                                      ),
                                ),
                                if (property?.zone != null) ...[
                                  ResponsiveUtils.verticalSpace(context, 2),
                                  Text(
                                    property!.zone!,
                                    style: AppTextStyles.caption(context)
                                        .copyWith(
                                          color: AppColors.lightGray,
                                          fontSize: ResponsiveUtils.sp(
                                            context,
                                            13,
                                          ),
                                        ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                      ResponsiveUtils.verticalSpace(context, 16),
                      Divider(height: ResponsiveUtils.h(context, 1)),
                    ],
                    // Customer Info Section
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: ResponsiveUtils.w(context, 44),
                          height: ResponsiveUtils.h(context, 44),
                          decoration: BoxDecoration(
                            color: AppColors.primaryTeal.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: customer?.idProofImageUrl != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(
                                    ResponsiveUtils.r(context, 22),
                                  ),
                                  child: Image.network(
                                    customer!.idProofImageUrl!,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) => Icon(
                                          Icons.person,
                                          color: AppColors.primaryTeal,
                                          size: ResponsiveUtils.r(context, 20),
                                        ),
                                  ),
                                )
                              : Icon(
                                  Icons.person,
                                  color: AppColors.primaryTeal,
                                  size: ResponsiveUtils.r(context, 20),
                                ),
                        ),
                        ResponsiveUtils.horizontalSpace(context, 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Customer',
                                style: AppTextStyles.caption(context).copyWith(
                                  color: AppColors.lightGray,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              ResponsiveUtils.verticalSpace(context, 4),
                              Text(
                                customer?.name ?? 'Unknown Customer',
                                style: AppTextStyles.body(context).copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.darkNavy,
                                ),
                              ),
                              ResponsiveUtils.verticalSpace(context, 2),
                              Text(
                                customer?.phone ?? '',
                                style: AppTextStyles.caption(context).copyWith(
                                  color: AppColors.lightGray,
                                  fontSize: ResponsiveUtils.sp(context, 13),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              ResponsiveUtils.verticalSpace(context, 16),

              // Card 2: Today's Task
              Container(
                padding: EdgeInsets.all(ResponsiveUtils.w(context, 16)),
                decoration: BoxDecoration(
                  color: AppColors.veryLightGray,
                  borderRadius: BorderRadius.circular(
                    ResponsiveUtils.r(context, 16),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: ResponsiveUtils.r(context, 8),
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header with Service Type and Status
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: ResponsiveUtils.w(context, 8),
                      runSpacing: ResponsiveUtils.h(context, 8),
                      children: [
                        Text(
                          'Today\'s Task',
                          style: AppTextStyles.title(context).copyWith(
                            fontSize: ResponsiveUtils.sp(context, 18),
                            color: AppColors.darkNavy,
                          ),
                        ),
                        Wrap(
                          spacing: ResponsiveUtils.w(context, 8),
                          runSpacing: ResponsiveUtils.h(context, 8),
                          children: [
                            // Status Badge
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: ResponsiveUtils.w(context, 10),
                                vertical: ResponsiveUtils.h(context, 6),
                              ),
                              decoration: BoxDecoration(
                                color: _getStatusColor(
                                  _job!.status,
                                ).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(
                                  ResponsiveUtils.r(context, 8),
                                ),
                              ),
                              child: Text(
                                _job!.displayStatus,
                                style: AppTextStyles.caption(context).copyWith(
                                  color: _getStatusColor(_job!.status),
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            // Service Type Badge
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: ResponsiveUtils.w(context, 14),
                                vertical: ResponsiveUtils.h(context, 8),
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    AppColors.gold,
                                    AppColors.gold.withValues(alpha: 0.8),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(
                                  ResponsiveUtils.r(context, 20),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.gold.withValues(
                                      alpha: 0.3,
                                    ),
                                    blurRadius: ResponsiveUtils.r(context, 8),
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.star,
                                    color: Colors.white,
                                    size: ResponsiveUtils.r(context, 16),
                                  ),
                                  SizedBox(
                                    width: ResponsiveUtils.w(context, 6),
                                  ),
                                  Text(
                                    serviceName,
                                    style: AppTextStyles.caption(context)
                                        .copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    ResponsiveUtils.verticalSpace(context, 20),
                    // Services List
                    if (services.isNotEmpty)
                      ...services.map(
                        (service) => _buildTaskItem(
                          service.name,
                          Icons.local_car_wash,
                          price: '\$${service.price}',
                        ),
                      )
                    else
                      _buildTaskItem('Car Wash Service', Icons.local_car_wash),

                    // Price Summary
                    ResponsiveUtils.verticalSpace(context, 12),
                    Container(
                      padding: EdgeInsets.all(ResponsiveUtils.w(context, 12)),
                      decoration: BoxDecoration(
                        color: AppColors.gold.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(
                          ResponsiveUtils.r(context, 10),
                        ),
                      ),
                      child: Row(
                        children: [
                          Flexible(
                            child: Text(
                              'Total Earnings',
                              style: AppTextStyles.body(context).copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppColors.darkNavy,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          SizedBox(width: ResponsiveUtils.w(context, 8)),
                          Text(
                            '\$${earnedAmount.toStringAsFixed(2)}',
                            style: AppTextStyles.title(context).copyWith(
                              color: AppColors.gold,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              ResponsiveUtils.verticalSpace(context, 24),
              SizedBox(
                width: double.infinity,
                height: ResponsiveUtils.h(context, 56),
                child: ElevatedButton(
                  onPressed: _isNavigating ? null : _handleNavigateToJob,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryTeal,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        ResponsiveUtils.r(context, 12),
                      ),
                    ),
                  ),
                  child: _isNavigating
                      ? SizedBox(
                          width: ResponsiveUtils.w(context, 24),
                          height: ResponsiveUtils.h(context, 24),
                          child: CircularProgressIndicator(
                            color: AppColors.white,
                            strokeWidth: ResponsiveUtils.w(context, 2),
                          ),
                        )
                      : Text(
                          'Navigate to Job',
                          style: AppTextStyles.button(
                            context,
                          ).copyWith(color: AppColors.white),
                        ),
                ),
              ),
            ],
          ),
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

  Widget _buildTaskItem(String task, IconData icon, {String? price}) {
    return Padding(
      padding: EdgeInsets.only(bottom: ResponsiveUtils.h(context, 12)),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: ResponsiveUtils.w(context, 12),
          vertical: ResponsiveUtils.h(context, 12),
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(ResponsiveUtils.r(context, 10)),
          border: Border.all(
            color: Colors.grey.shade200,
            width: ResponsiveUtils.w(context, 1),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(ResponsiveUtils.w(context, 8)),
              decoration: BoxDecoration(
                color: AppColors.primaryTeal.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(
                  ResponsiveUtils.r(context, 8),
                ),
              ),
              child: Icon(
                icon,
                color: AppColors.primaryTeal,
                size: ResponsiveUtils.r(context, 20),
              ),
            ),
            ResponsiveUtils.horizontalSpace(context, 12),
            Expanded(
              child: Text(
                task,
                style: AppTextStyles.body(context).copyWith(
                  fontWeight: FontWeight.w500,
                  color: AppColors.darkNavy,
                ),
              ),
            ),
            if (price != null)
              Text(
                price,
                style: AppTextStyles.body(
                  context,
                ).copyWith(fontWeight: FontWeight.w600, color: AppColors.gold),
              )
            else
              Icon(
                Icons.check_circle,
                color: AppColors.primaryTeal.withValues(alpha: 0.3),
                size: ResponsiveUtils.r(context, 22),
              ),
          ],
        ),
      ),
    );
  }
}
