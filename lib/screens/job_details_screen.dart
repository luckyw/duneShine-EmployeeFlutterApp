import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../constants/text_styles.dart';
import '../models/job_model.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

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
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ?? {};
    
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

    final response = await ApiService().getJobDetails(jobId: jobId, token: token);
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Not authenticated. Please login again.')),
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
        updatedJob = Job.fromJson(jobJson);
        setState(() {
          _job = updatedJob;
        });
      }

      // Navigate to map screen
      if (mounted) {
        final vehicle = updatedJob.booking?.vehicle;
        final carModel = vehicle != null ? '${vehicle.brandName} ${vehicle.model}' : 'Unknown Vehicle';
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Failed to start navigation'),
            backgroundColor: AppColors.error,
          ),
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

    final response = await ApiService().getJobDetails(jobId: jobId, token: token);
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
            fontSize: 20,
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
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                color: AppColors.error,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: AppTextStyles.body(context).copyWith(
                  color: AppColors.textGray,
                ),
              ),
              const SizedBox(height: 16),
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
        ),
      );
    }

    if (_job == null) {
      return const Center(child: Text('No job data available'));
    }

    return _buildJobContent();
  }

  Widget _buildJobContent() {
    final job = _job!;
    final vehicle = job.booking?.vehicle;
    final apartment = job.booking?.apartment;
    final booking = job.booking;
    final customer = booking?.customer;
    
    final carModel = vehicle != null ? '${vehicle.brandName} ${vehicle.model}' : 'Unknown Vehicle';
    final carColor = vehicle?.color ?? 'Unknown';
    final jobId = 'JOB-${job.id}';
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
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card 1: Car Information & Address
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.veryLightGray,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 8,
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
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.gold.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.directions_car,
                            color: AppColors.gold, size: 28),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              carModel,
                              style: AppTextStyles.title(context).copyWith(
                                fontSize: 18,
                                color: AppColors.darkNavy,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Container(
                                  width: 14,
                                  height: 14,
                                  decoration: BoxDecoration(
                                    color: _getColorFromName(carColor),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.grey.shade300,
                                      width: 1,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  carColor,
                                  style: AppTextStyles.body(context).copyWith(
                                    color: AppColors.lightGray,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  '• ${vehicle?.numberPlate ?? ''}',
                                  style: AppTextStyles.body(context).copyWith(
                                    color: AppColors.textGray,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.primaryTeal.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
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
                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  const SizedBox(height: 16),
                  // Address Section
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.location_on,
                          color: Colors.redAccent,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Service Location',
                              style: AppTextStyles.caption(context).copyWith(
                                color: AppColors.lightGray,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              apartment?.name ?? 'Unknown Location',
                              style: AppTextStyles.body(context).copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppColors.darkNavy,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              apartment?.address ?? '',
                              style: AppTextStyles.caption(context).copyWith(
                                color: AppColors.lightGray,
                                fontSize: 13,
                              ),
                            ),
                            if (apartment?.zone != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                apartment!.zone,
                                style: AppTextStyles.caption(context).copyWith(
                                  color: AppColors.lightGray,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  const SizedBox(height: 16),
                  // Customer Info Section
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primaryTeal.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.person,
                          color: AppColors.primaryTeal,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
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
                            const SizedBox(height: 4),
                            Text(
                              customer?.name ?? 'Unknown Customer',
                              style: AppTextStyles.body(context).copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppColors.darkNavy,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              customer?.phone ?? '',
                              style: AppTextStyles.caption(context).copyWith(
                                color: AppColors.lightGray,
                                fontSize: 13,
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
            const SizedBox(height: 16),
            
            // Card 2: Today's Task
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.veryLightGray,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with Service Type and Status
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Today\'s Task',
                        style: AppTextStyles.title(context).copyWith(
                          fontSize: 18,
                          color: AppColors.darkNavy,
                        ),
                      ),
                      Row(
                        children: [
                          // Status Badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: _getStatusColor(job.status).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              job.displayStatus,
                              style: AppTextStyles.caption(context).copyWith(
                                color: _getStatusColor(job.status),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Service Type Badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.gold,
                                  AppColors.gold.withValues(alpha: 0.8),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(20),
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
                                  Icons.star,
                                  color: Colors.white,
                                  size: 16,
                                ),
                                SizedBox(width: 6),
                                Text(
                                  serviceName,
                                  style: AppTextStyles.caption(context).copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Services List
                  if (services.isNotEmpty)
                    ...services.map((service) => _buildTaskItem(
                          service.name,
                          Icons.local_car_wash,
                          price: '\$${service.price}',
                        ))
                  else
                    _buildTaskItem('Car Wash Service', Icons.local_car_wash),
                  
                  // Price Summary
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.gold.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total Earnings',
                          style: AppTextStyles.body(context).copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.darkNavy,
                          ),
                        ),
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
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isNavigating ? null : _handleNavigateToJob,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryTeal,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isNavigating
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: AppColors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        'Navigate to Job',
                        style: AppTextStyles.button(context).copyWith(
                          color: AppColors.white,
                        ),
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
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: Colors.grey.shade200,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primaryTeal.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: AppColors.primaryTeal, size: 20),
            ),
            const SizedBox(width: 12),
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
                style: AppTextStyles.body(context).copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.gold,
                ),
              )
            else
              Icon(
                Icons.check_circle,
                color: AppColors.primaryTeal.withValues(alpha: 0.3),
                size: 22,
              ),
          ],
        ),
      ),
    );
  }
}
