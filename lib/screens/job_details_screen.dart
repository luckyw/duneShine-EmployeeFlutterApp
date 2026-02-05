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
      backgroundColor: const Color(0xFFF8F9FA), // Light grey background for premium feel
      extendBodyBehindAppBar: true, // Allow body to go behind app bar for gradient effect
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Container(
          margin: EdgeInsets.all(ResponsiveUtils.w(context, 8)),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: Text(
          'Job Details',
          style: AppTextStyles.headline(context).copyWith(
            color: Colors.white,
            fontSize: ResponsiveUtils.sp(context, 20),
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: _buildBody(),
      bottomNavigationBar: _job != null ? _buildBottomActionBar() : null,
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primaryTeal));
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded, size: 48, color: Colors.redAccent),
            SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: AppTextStyles.body(context),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _errorMessage = null;
                });
                _fetchJobDetails();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
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
    final jobId = 'JOB-${_job!.id}';
    final statusColor = _getStatusColor(_job!.status);

    // Calculate details
    final carModel = vehicle != null
        ? '${vehicle.brandName} ${vehicle.model}'
        : 'Unknown Vehicle';
    final carColor = vehicle?.color ?? 'Unknown Color';
    
    // Calculate total price
    double earnedAmount = 0;
    if (booking != null) {
      for (var service in booking.servicesPayload) {
        earnedAmount += double.tryParse(service.price) ?? 0;
      }
    }

    // Get services list
    final services = booking?.servicesPayload ?? [];

    return RefreshIndicator(
      onRefresh: _refreshJobDetails,
      color: AppColors.primaryTeal,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            // PREMIUM HEADER SECTION
            Stack(
              clipBehavior: Clip.none,
              children: [
                // 1. Main Gradient Background
                Container(
                  height: ResponsiveUtils.h(context, 280),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.primaryTeal,
                        AppColors.primaryTeal.withValues(alpha: 0.8),
                        Color(0xFF004D40), // Darker teal for depth
                      ],
                    ),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(ResponsiveUtils.r(context, 32)),
                      bottomRight: Radius.circular(ResponsiveUtils.r(context, 32)),
                    ),
                  ),
                ),
                
                // 2. Decorative Circles
                Positioned(
                  top: -50,
                  right: -50,
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.05),
                    ),
                  ),
                ),
                
                // 3. Content Content
                SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      ResponsiveUtils.w(context, 20),
                      ResponsiveUtils.h(context, 60), // Space for AppBar
                      ResponsiveUtils.w(context, 20),
                      ResponsiveUtils.h(context, 20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Status Badge & Job ID
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: ResponsiveUtils.w(context, 12),
                                vertical: ResponsiveUtils.h(context, 6),
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.1),
                                ),
                              ),
                              child: Text(
                                jobId,
                                style: AppTextStyles.caption(context).copyWith(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: ResponsiveUtils.w(context, 12),
                                vertical: ResponsiveUtils.h(context, 6),
                              ),
                              decoration: BoxDecoration(
                                color: statusColor,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: statusColor.withValues(alpha: 0.4),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Text(
                                _job!.displayStatus,
                                style: AppTextStyles.caption(context).copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        
                        ResponsiveUtils.verticalSpace(context, 24),
                        
                        // Vehicle Main Info centered
                        Center(
                          child: Column(
                            children: [
                              Container(
                                width: ResponsiveUtils.w(context, 100),
                                height: ResponsiveUtils.h(context, 100),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.15),
                                      blurRadius: 20,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    width: 4,
                                  ),
                                ),
                                child: ClipOval(
                                  child: vehicle?.imageUrl != null && vehicle!.imageUrl!.isNotEmpty
                                      ? Image.network(
                                          vehicle.imageUrl!,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => Icon(
                                            Icons.directions_car_rounded,
                                            size: 40,
                                            color: AppColors.primaryTeal,
                                          ),
                                        )
                                      : Icon(
                                          Icons.directions_car_rounded,
                                          size: 40,
                                          color: AppColors.primaryTeal,
                                        ),
                                ),
                              ),
                              ResponsiveUtils.verticalSpace(context, 16),
                              Text(
                                carModel,
                                style: AppTextStyles.headline(context).copyWith(
                                  color: AppColors.primaryTeal,
                                  fontSize: ResponsiveUtils.sp(context, 24),
                                  fontWeight: FontWeight.bold,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black.withValues(alpha: 0.1),
                                      offset: const Offset(0, 2),
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                                textAlign: TextAlign.center,
                              ),
                              ResponsiveUtils.verticalSpace(context, 8),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: ResponsiveUtils.w(context, 12),
                                  vertical: ResponsiveUtils.h(context, 4),
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '$carColor • ${vehicle?.numberPlate ?? 'No Plate'}',
                                  style: AppTextStyles.body(context).copyWith(
                                    color: AppColors.primaryTeal,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // MAIN CONTENT
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: ResponsiveUtils.w(context, 16),
              ),
              child: Column(
                children: [
                  // Overlapping Card Effect
                  Transform.translate(
                    offset: Offset(0, -20),
                    child: Column(
                      children: [
                        // 1. Customer Card
                        _buildPremiumCard(
                          context,
                          title: 'Customer Details',
                          icon: Icons.person_outline_rounded,
                          iconColor: AppColors.primaryTeal,
                          child: Row(
                            children: [
                              Container(
                                width: ResponsiveUtils.w(context, 50),
                                height: ResponsiveUtils.h(context, 50),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryTeal.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: customer?.idProofImageUrl != null
                                    ? ClipOval(
                                        child: Image.network(
                                          customer!.idProofImageUrl!,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => Icon(
                                            Icons.person,
                                            color: AppColors.primaryTeal,
                                          ),
                                        ),
                                      )
                                    : Icon(Icons.person, color: AppColors.primaryTeal),
                              ),
                              ResponsiveUtils.horizontalSpace(context, 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      customer?.name ?? 'Unknown Customer',
                                      style: AppTextStyles.title(context).copyWith(
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.darkNavy,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      customer?.phone ?? 'No phone number',
                                      style: AppTextStyles.body(context).copyWith(
                                        color: AppColors.textGray,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Call Button Container
                               Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: Colors.green.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.phone_rounded,
                                  color: Colors.green,
                                  size: 20,
                                ),
                              ),
                            ],
                          ),
                        ),

                        ResponsiveUtils.verticalSpace(context, 16),

                        // 2. Location Card
                        if (booking?.fullAddress != null)
                          _buildPremiumCard(
                            context,
                            title: 'Service Location',
                            icon: Icons.location_on_outlined,
                            iconColor: Colors.redAccent,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  booking?.locationName ?? 'Location',
                                  style: AppTextStyles.title(context).copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(
                                      Icons.format_quote_rounded, // Subtle icon for address
                                      size: 16,
                                      color: AppColors.lightGray,
                                    ),
                                    SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        booking!.fullAddress,
                                        style: AppTextStyles.body(context).copyWith(
                                          color: AppColors.textGray,
                                          height: 1.5,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                if (vehicle?.parkingNotes != null && vehicle!.parkingNotes!.isNotEmpty) ...[
                                  ResponsiveUtils.verticalSpace(context, 16),
                                  Divider(color: Colors.grey.shade100, height: 1),
                                  ResponsiveUtils.verticalSpace(context, 16),
                                  Row(
                                    children: [
                                      Container(
                                        padding: EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: Colors.amber.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Icon(Icons.info_outline_rounded, color: Colors.amber, size: 16),
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        'Parking Notes',
                                        style: AppTextStyles.body(context).copyWith(
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.darkNavy,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 8),
                                  Container(
                                    width: double.infinity,
                                    padding: EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.amber.withValues(alpha: 0.05),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.amber.withValues(alpha: 0.1)),
                                    ),
                                    child: Text(
                                      vehicle!.parkingNotes!,
                                      style: AppTextStyles.body(context).copyWith(
                                        color: Colors.amber.shade900,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ),
                                ],
                                if (property?.zone != null) ...[
                                  SizedBox(height: 12),
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.withValues(alpha: 0.05),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: Colors.blue.withValues(alpha: 0.1),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.map_outlined, size: 14, color: Colors.blue),
                                        SizedBox(width: 6),
                                        Text(
                                          'Zone: ${property!.zone}',
                                          style: AppTextStyles.caption(context).copyWith(
                                            color: Colors.blue.shade700,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),

                        ResponsiveUtils.verticalSpace(context, 16),

                        // 3. Services & Payment
                        _buildPremiumCard(
                          context,
                          title: 'Services',
                          icon: Icons.receipt_long_rounded,
                          iconColor: AppColors.gold,
                          child: Column(
                            children: [
                              ...services.map((s) => Padding(
                                    padding: const EdgeInsets.only(bottom: 12.0),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.check_circle,
                                          color: AppColors.primaryTeal,
                                          size: 20,
                                        ),
                                        SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            s.name,
                                            style: AppTextStyles.body(context).copyWith(
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  )),
                             ],
                          ),
                        ),
                        
                        // Bottom padding for scroll
                         SizedBox(height: ResponsiveUtils.h(context, 100)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color iconColor,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(ResponsiveUtils.r(context, 20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      padding: EdgeInsets.all(ResponsiveUtils.w(context, 20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              SizedBox(width: 12),
              Text(
                title,
                style: AppTextStyles.title(context).copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: ResponsiveUtils.sp(context, 16),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildBottomActionBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveUtils.w(context, 20),
        vertical: ResponsiveUtils.h(context, 16),
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: ResponsiveUtils.h(context, 56),
          child: ElevatedButton(
            onPressed: _isNavigating ? null : _handleNavigateToJob,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryTeal,
              elevation: 4,
              shadowColor: AppColors.primaryTeal.withValues(alpha: 0.4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              padding: EdgeInsets.zero,
            ),
            child: _isNavigating
                ? SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.near_me_rounded, color: Colors.white),
                      SizedBox(width: 10),
                      Text(
                        'Start Navigation',
                        style: AppTextStyles.title(context).copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String? status) {
    if (status == null) return Colors.grey;
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'in_progress':
      case 'started':
        return Colors.blue;
      case 'pending':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      default:
        return AppColors.primaryTeal;
    }
  }
}
