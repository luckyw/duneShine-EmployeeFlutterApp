import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../constants/text_styles.dart';
import '../models/job_model.dart';
import '../models/employee_profile_model.dart';
import '../models/notification_model.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import 'availability_widget.dart';
import 'account_widget.dart';
import '../utils/responsive_utils.dart';
import '../utils/toast_utils.dart';
import '../services/background_location_service.dart';
import '../services/location_tracking_service.dart';


class EmployeeHomeScreen extends StatefulWidget {
  const EmployeeHomeScreen({Key? key}) : super(key: key);

  @override
  State<EmployeeHomeScreen> createState() => _EmployeeHomeScreenState();
}

class _EmployeeHomeScreenState extends State<EmployeeHomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _currentIndex = 0;

  // API state
  bool _isLoading = true;
  String? _errorMessage;
  List<Job> _allJobs = [];
  
  // Shift state
  late bool _isShiftStarted;
  bool _isAttendanceLoading = false;
  
  // Filter out cancelled jobs and sort by time (closest first)
  List<Job> get _upcomingJobs {
    return _allJobs
        .where((job) => !job.isCompleted && job.status != 'cancelled')
        .toList()
      ..sort((a, b) {
        // startTime is in HH:MM:SS format, which sorts lexicographically correctly
        final aTime = a.timeSlot?.startTime ?? '99:99:99';
        final bTime = b.timeSlot?.startTime ?? '99:99:99';
        return aTime.compareTo(bTime);
      });
  }
  
  List<Job> get _completedJobs => _allJobs.where((job) => job.isCompleted).toList();

  // Profile state
  EmployeeProfileModel? _profile;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _isShiftStarted = AuthService().isShiftStarted;
    _fetchTodaysJobs();
    _fetchProfile();
    
    // Ensure tracking is active if shift is already started
    if (_isShiftStarted) {
      final employeeId = AuthService().employeeId;
      if (employeeId != null) {
        BackgroundLocationService.start(employeeId);
      }
    }
  }

  Future<void> _fetchProfile() async {
    final token = AuthService().token;
    if (token == null) return;

    final result = await ApiService().getProfile(token: token);
    if (result['success'] == true && mounted) {
      final data = result['data'] as Map<String, dynamic>;
      final userData = data['user'] as Map<String, dynamic>;
      
      // Update shift status from profile response if available
      if (data['session_status'] != null) {
        final apiShiftStarted = data['session_status'] == 1 || data['session_status'] == true || data['session_status'] == '1';
        if (_isShiftStarted != apiShiftStarted) {
          setState(() {
            _isShiftStarted = apiShiftStarted;
          });
          AuthService().setShiftStatus(apiShiftStarted);
        }
      }

      setState(() {
        _profile = EmployeeProfileModel.fromJson(userData);
      });
    }
  }

  Future<void> _fetchTodaysJobs() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final token = AuthService().token;
    if (token == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Not authenticated. Please login again.';
      });
      return;
    }

    final response = await ApiService().getTodaysJobs(token: token);

    if (response['success'] == true) {
      final data = response['data'] as Map<String, dynamic>;
      final jobsList = data['jobs'] as List<dynamic>? ?? [];

      // Update shift status from API response if available
      // The session_status is usually 1 for started and 0 for not started
      if (data['session_status'] != null) {
        final apiShiftStarted = data['session_status'] == 1 || data['session_status'] == true || data['session_status'] == '1';
        if (_isShiftStarted != apiShiftStarted) {
          setState(() {
            _isShiftStarted = apiShiftStarted;
          });
          AuthService().setShiftStatus(apiShiftStarted);
        }
      }

      setState(() {
        _allJobs = jobsList
            .map((json) => Job.fromJson(json as Map<String, dynamic>))
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
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _handleCheckIn() async {
    final token = AuthService().token;
    if (token == null) return;

    setState(() {
      _isAttendanceLoading = true;
    });

    // Request permissions before starting shift
    bool hasPermission = await LocationTrackingService().requestLocationPermission();
    if (!hasPermission) {
      if (mounted) {
        ToastUtils.showErrorToast(context, 'Location permission is required to start shift');
      }
      setState(() => _isAttendanceLoading = false);
      return;
    }

    final result = await ApiService().checkIn(token: token);

    if (mounted) {
      if (result['success'] == true) {
        AuthService().setShiftStatus(true);
        setState(() {
          _isShiftStarted = true;
          _isAttendanceLoading = false;
        });
        _fetchTodaysJobs();
        
        // Start background tracking service
        final employeeId = AuthService().employeeId;
        if (employeeId != null) {
          BackgroundLocationService.start(employeeId);
        }
        
        ToastUtils.showSuccessToast(context, 'Shift started! Good luck today!');

      } else {
        setState(() {
          _isAttendanceLoading = false;
        });
        ToastUtils.showErrorToast(context, result['message'] ?? 'Failed to start shift');

      }
    }
  }


  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good Morning';
    } else if (hour < 17) {
      return 'Good Afternoon';
    } else {
      return 'Good Evening';
    }
  }

  // Dummy notifications for testing
  final List<NotificationModel> _dummyNotifications = [
    const NotificationModel(
      id: 1,
      title: 'New Job Assigned',
      message: 'You have been assigned a new job at Downtown Mall. Please confirm your availability.',
      time: '10:30 AM',
      isRead: false,
    ),
    const NotificationModel(
      id: 2,
      title: 'Job Reminder',
      message: 'Your shift at City Center starts in 30 minutes. Please ensure you are on time.',
      time: '09:45 AM',
      isRead: false,
    ),
    const NotificationModel(
      id: 3,
      title: 'Job Completed',
      message: 'Great job! Your job at Riverside Apartments has been marked as completed.',
      time: 'Yesterday',
      isRead: true,
    ),
    const NotificationModel(
      id: 4,
      title: 'Schedule Update',
      message: 'Your schedule for next week has been updated. Please review your upcoming shifts.',
      time: '2 days ago',
      isRead: true,
    ),
    const NotificationModel(
      id: 5,
      title: 'Payment Received',
      message: 'Your payment of \$125.50 for this week has been processed and will be deposited soon.',
      time: '3 days ago',
      isRead: true,
    ),
  ];

  void _showNotificationSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.lightGray,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              // Title
              Text(
                'Notifications',
                style: AppTextStyles.headline(context).copyWith(
                  fontSize: 20,
                  color: AppColors.darkNavy,
                ),
              ),
              const SizedBox(height: 16),
              // Notification list
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _dummyNotifications.length,
                  itemBuilder: (BuildContext context, int index) {
                    final notification = _dummyNotifications[index];
                    return _buildNotificationItem(notification);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNotificationItem(NotificationModel notification) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: notification.isRead
            ? AppColors.veryLightGray
            : AppColors.creamBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: notification.isRead
              ? AppColors.lightGray
              : AppColors.gold,
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Notification icon
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: notification.isRead
                  ? AppColors.lightGray.withOpacity(0.2)
                  : AppColors.gold.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              notification.isRead
                  ? Icons.notifications_none
                  : Icons.notifications_active,
              color: notification.isRead
                  ? AppColors.textGray
                  : AppColors.gold,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notification.title,
                  style: AppTextStyles.title(context).copyWith(
                    fontSize: 14,
                    fontWeight: notification.isRead
                        ? FontWeight.normal
                        : FontWeight.bold,
                    color: AppColors.darkNavy,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  notification.message,
                  style: AppTextStyles.body(context).copyWith(
                    fontSize: 12,
                    color: AppColors.textGray,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  notification.time,
                  style: AppTextStyles.body(context).copyWith(
                    fontSize: 10,
                    color: AppColors.lightGray,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: _getAppBar(),
      body: _getBody(),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  AppBar? _getAppBar() {
    switch (_currentIndex) {
      case 0:
        return AppBar(
          backgroundColor: AppColors.white,
          elevation: 0,
          leading: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Image.asset(
              'assets/images/app_logo.png',
              fit: BoxFit.contain,
            ),
          ),
          centerTitle: true,
          title: _isShiftStarted
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      '${_getGreeting()}, ${_profile?.name ?? AuthService().employeeName}',
                      style: AppTextStyles.headline(context).copyWith(
                        color: AppColors.darkNavy,
                        fontSize: ResponsiveUtils.sp(context, 18),
                      ),
                    ),
                  ],
                )
              : RichText(
                  text: TextSpan(
                    style: AppTextStyles.headline(context).copyWith(
                      color: AppColors.darkNavy,
                      fontSize: ResponsiveUtils.sp(context, 26),
                    ),
                    children: const [
                      TextSpan(
                        text: 'Dune',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextSpan(
                        text: 'Shine',
                        style: TextStyle(
                          color: AppColors.gold,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
          actions: [
            IconButton(
              onPressed: () => _showNotificationSheet(context),
              icon: Icon(
                Icons.notifications_outlined,
                color: AppColors.darkNavy,
              ),
            ),
          ],
        );
      case 1:
        return AppBar(
          title: Text(
            'Mark Availability',
            style: AppTextStyles.headline(context).copyWith(fontSize: 20),
          ),
          centerTitle: true,
          backgroundColor: AppColors.white,
          elevation: 0,
        );
      case 2:
        return AppBar(
          title: Text(
            'My Account',
            style: AppTextStyles.headline(context).copyWith(fontSize: 20),
          ),
          centerTitle: true,
          backgroundColor: AppColors.white,
          elevation: 0,
        );
      default:
        return null;
    }
  }

  Widget _getBody() {
    switch (_currentIndex) {
      case 0:
        // If shift not started, show Start Shift button
        if (!_isShiftStarted) {
          return _buildStartShiftView();
        }
        // Shift started, show jobs with End Shift button
        return RefreshIndicator(
          onRefresh: _fetchTodaysJobs,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    // End Shift Button

                    Container(
                      margin: EdgeInsets.symmetric(horizontal: ResponsiveUtils.w(context, 16)),
                      padding: EdgeInsets.all(ResponsiveUtils.w(context, 16)),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.gold, width: 2),
                        borderRadius: BorderRadius.circular(ResponsiveUtils.r(context, 12)),
                        color: AppColors.creamBg,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              "Today's Jobs: ${_upcomingJobs.length + _completedJobs.length}",
                              style: AppTextStyles.title(context).copyWith(
                                fontSize: 18,
                                color: AppColors.darkNavy,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: RichText(
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text: 'Upcoming: ${_upcomingJobs.length} ',
                                    style: AppTextStyles.body(context).copyWith(
                                      color: AppColors.darkNavy,
                                    ),
                                  ),
                                  TextSpan(
                                    text: '| ${_completedJobs.length} Done',
                                    style: AppTextStyles.body(context).copyWith(
                                      color: AppColors.primaryTeal,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      margin: EdgeInsets.all(ResponsiveUtils.w(context, 16)),
                      decoration: BoxDecoration(
                        color: AppColors.veryLightGray,
                        borderRadius: BorderRadius.circular(ResponsiveUtils.r(context, 12)),
                      ),
                      child: TabBar(
                        controller: _tabController,
                        indicator: BoxDecoration(
                          color: AppColors.primaryTeal,
                          borderRadius: BorderRadius.circular(ResponsiveUtils.r(context, 12)),
                        ),
                        indicatorSize: TabBarIndicatorSize.tab,
                        labelColor: AppColors.white,
                        unselectedLabelColor: AppColors.darkNavy,
                        tabs: const [
                          Tab(text: 'Upcoming'),
                          Tab(text: 'Completed'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SliverFillRemaining(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Upcoming Jobs Tab
                    _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : _errorMessage != null
                            ? Center(
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
                                      onPressed: _fetchTodaysJobs,
                                      child: const Text('Retry'),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : _upcomingJobs.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.check_circle_outline,
                                        color: AppColors.primaryTeal,
                                        size: 64,
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'No upcoming jobs',
                                        style: AppTextStyles.title(context).copyWith(
                                          color: AppColors.textGray,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : SingleChildScrollView(
                                  physics: const AlwaysScrollableScrollPhysics(),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                    child: Column(
                                      children: [
                                        for (int i = 0; i < _upcomingJobs.length; i++) ...[
                                          _buildJobCardFromApi(
                                            job: _upcomingJobs[i],
                                            isNextJob: i == 0,
                                          ),
                                          if (i < _upcomingJobs.length - 1)
                                            const SizedBox(height: 12),
                                        ],
                                      ],
                                    ),
                                  ),
                                ),
                    // Completed Jobs Tab
                    _completedJobs.isEmpty
                        ? Center(
                            child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.inbox_outlined,
                                color: AppColors.lightGray,
                                size: 64,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No completed jobs yet',
                                style: AppTextStyles.title(context).copyWith(
                                  color: AppColors.textGray,
                                ),
                              ),
                            ],
                          ),
                        )
                      : SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Column(
                              children: [
                                for (int i = 0; i < _completedJobs.length; i++) ...[
                                  _buildCompletedJobCardFromApi(
                                    job: _completedJobs[i],
                                  ),
                                  if (i < _completedJobs.length - 1)
                                    const SizedBox(height: 12),
                                ],
                              ],
                            ),
                          ),
                        ),
                ],
              ),
            ),
          ],
        ),
      );
      case 1:
        return const AvailabilityWidget();
      case 2:
        return AccountWidget(
          isShiftStarted: _isShiftStarted,
          onShiftEnded: () {
            // Update local state when shift is ending from Account screen
            setState(() {
              _isShiftStarted = false;
              AuthService().setShiftStatus(false);
              _tabController.index = 0; // Go back to upcoming
            });
            // Force refresh of jobs to show empty/start shift state
            _fetchTodaysJobs();
          },
        );
      default:
        return Container();
    }
  }

  Widget _buildStartShiftView() {
    return RefreshIndicator(
      onRefresh: _fetchTodaysJobs,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: EdgeInsets.all(ResponsiveUtils.w(context, 24)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ResponsiveUtils.verticalSpace(context, 20),
              Container(
                padding: EdgeInsets.all(ResponsiveUtils.w(context, 24)),
                decoration: BoxDecoration(
                  color: AppColors.primaryTeal.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.work_outline,
                  size: ResponsiveUtils.r(context, 60),
                  color: AppColors.primaryTeal,
                ),
              ),
              ResponsiveUtils.verticalSpace(context, 20),
              Text(
                'Ready to start your day?',
                style: AppTextStyles.headline(context).copyWith(
                  color: AppColors.darkNavy,
                  fontSize: ResponsiveUtils.sp(context, 22),
                ),
                textAlign: TextAlign.center,
              ),
              ResponsiveUtils.verticalSpace(context, 8),
              Text(
                'Start your shift to begin working',
                style: AppTextStyles.body(context).copyWith(
                  color: AppColors.textGray,
                  fontSize: ResponsiveUtils.sp(context, 14),
                ),
                textAlign: TextAlign.center,
              ),
              ResponsiveUtils.verticalSpace(context, 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isAttendanceLoading ? null : _handleCheckIn,
                  icon: _isAttendanceLoading
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryTeal),
                        )
                      : Icon(Icons.play_circle_filled,
                          size: ResponsiveUtils.r(context, 30),
                          color: AppColors.primaryTeal),
                  label: Text(
                    'Start Shift',
                    style: TextStyle(
                      fontSize: ResponsiveUtils.sp(context, 18),
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryTeal,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.white,
                    foregroundColor: AppColors.primaryTeal,
                    padding: EdgeInsets.symmetric(
                        vertical: ResponsiveUtils.h(context, 18)),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(ResponsiveUtils.r(context, 16)),
                      side: const BorderSide(
                          color: AppColors.primaryTeal, width: 2),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Today's Jobs Preview
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(),
                )
              else if (_upcomingJobs.isNotEmpty) ...[
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(ResponsiveUtils.w(context, 16)),
                  decoration: BoxDecoration(
                    color: AppColors.creamBg,
                    borderRadius: BorderRadius.circular(ResponsiveUtils.r(context, 12)),
                    border: Border.all(color: AppColors.gold, width: 2),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.calendar_today, color: AppColors.gold, size: ResponsiveUtils.r(context, 20)),
                          ResponsiveUtils.horizontalSpace(context, 8),
                          Text(
                            "Today's Jobs (${_upcomingJobs.length})",
                            style: AppTextStyles.title(context).copyWith(
                              fontSize: ResponsiveUtils.sp(context, 16),
                              color: AppColors.darkNavy,
                            ),
                          ),
                        ],
                      ),
                      ResponsiveUtils.verticalSpace(context, 12),
                      // Job list preview
                      ...List.generate(
                        _upcomingJobs.length,
                        (index) => _buildJobPreviewItem(_upcomingJobs[index], index),
                      ),
                    ],
                  ),
                ),
              ] else
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(ResponsiveUtils.w(context, 20)),
                  decoration: BoxDecoration(
                    color: AppColors.veryLightGray,
                    borderRadius: BorderRadius.circular(ResponsiveUtils.r(context, 12)),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.inbox_outlined, color: AppColors.lightGray, size: ResponsiveUtils.r(context, 40)),
                      ResponsiveUtils.verticalSpace(context, 8),
                      Text(
                        'No jobs scheduled for today',
                        style: AppTextStyles.body(context).copyWith(
                          color: AppColors.textGray,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Job preview item for the pre-shift view
  Widget _buildJobPreviewItem(Job job, int index) {
    final vehicle = job.booking?.vehicle;
    final timeSlot = job.timeSlot;
    
    return Container(
      margin: EdgeInsets.only(top: index > 0 ? ResponsiveUtils.h(context, 10) : 0),
      padding: EdgeInsets.all(ResponsiveUtils.w(context, 12)),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(ResponsiveUtils.r(context, 10)),
        border: Border.all(color: AppColors.lightGray.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(ResponsiveUtils.w(context, 8)),
            decoration: BoxDecoration(
              color: AppColors.primaryTeal.withOpacity(0.1),
              borderRadius: BorderRadius.circular(ResponsiveUtils.r(context, 8)),
            ),
            child: Icon(Icons.directions_car, color: AppColors.primaryTeal, size: ResponsiveUtils.r(context, 20)),
          ),
          ResponsiveUtils.horizontalSpace(context, 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                 Text(
                   vehicle?.displayName ?? 'Vehicle',
                   style: AppTextStyles.body(context).copyWith(
                     fontWeight: FontWeight.w600,
                     color: AppColors.darkNavy,
                   ),
                 ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: ResponsiveUtils.w(context, 10), vertical: ResponsiveUtils.h(context, 6)),
            decoration: BoxDecoration(
              color: AppColors.primaryTeal.withOpacity(0.1),
              borderRadius: BorderRadius.circular(ResponsiveUtils.r(context, 8)),
            ),
            child: Text(
              timeSlot?.formattedStartTime ?? '',
              style: AppTextStyles.caption(context).copyWith(
                color: AppColors.primaryTeal,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJobCard({
    required String time,
    required String car,
    required String location,
    required String status,
    String buttonText = 'Navigate',
    Color bgColor = AppColors.primaryTeal,
    Color statusColor = Colors.transparent,
    Color textColor = AppColors.white,
    Color borderColor = Colors.transparent,
    Color iconColor = AppColors.white,
    VoidCallback? onNavigate,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(ResponsiveUtils.r(context, 12)),
        border: borderColor != Colors.transparent
            ? Border.all(color: borderColor, width: 1.5)
            : null,
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(ResponsiveUtils.w(context, 16)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  time,
                  style: AppTextStyles.body(context).copyWith(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                ResponsiveUtils.verticalSpace(context, 12),
                Row(
                  children: [
                    Icon(Icons.directions_car, color: iconColor, size: ResponsiveUtils.r(context, 20)),
                    ResponsiveUtils.horizontalSpace(context, 8),
                    Expanded(
                      child: Text(
                        car,
                        style: AppTextStyles.body(context).copyWith(
                          color: textColor,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (status.isNotEmpty)
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: ResponsiveUtils.w(context, 8), vertical: ResponsiveUtils.h(context, 4)),
                        decoration: BoxDecoration(
                          color: statusColor == AppColors.white
                              ? AppColors.darkNavy.withValues(alpha: 0.8)
                              : statusColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(ResponsiveUtils.r(context, 4)),
                        ),
                        child: Text(
                          status,
                          style: AppTextStyles.caption(context).copyWith(
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                        ),
                      ),
                  ],
                ),
                if (location.isNotEmpty && !location.toLowerCase().contains('unknown')) ...[
                  ResponsiveUtils.verticalSpace(context, 8),
                  Row(
                    children: [
                      Icon(Icons.location_on, color: iconColor, size: ResponsiveUtils.r(context, 20)),
                      ResponsiveUtils.horizontalSpace(context, 8),
                      Expanded(
                        child: Text(
                          location,
                          style: AppTextStyles.caption(context).copyWith(
                            color: textColor,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          if (onNavigate != null)
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(ResponsiveUtils.w(context, 16)),
              child: ElevatedButton(
                onPressed: onNavigate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.amber,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(ResponsiveUtils.r(context, 12)),
                  ),
                ),
                child: Text(
                  buttonText,
                  style: AppTextStyles.button(context).copyWith(
                    color: AppColors.darkNavy,
                  ),
                ),
              ),
            ),
        ],
      ),
      ),
    );
  }

  Widget _buildCompletedJobCard({
    required String time,
    required String car,
    required String location,
    required String completedTime,
    required String earnings,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(ResponsiveUtils.r(context, 12)),
        border: Border.all(color: AppColors.lightGray, width: 1.5),
      ),
      padding: EdgeInsets.all(ResponsiveUtils.w(context, 16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                time,
                style: AppTextStyles.body(context).copyWith(
                  color: AppColors.textGray,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '✓ Done',
                  style: AppTextStyles.caption(context).copyWith(
                    color: AppColors.success,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.directions_car,
                  color: AppColors.textGray, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  car,
                  style: AppTextStyles.body(context).copyWith(
                    color: AppColors.textGray,
                  ),
                ),
              ),
            ],
          ),
          if (location.isNotEmpty && !location.toLowerCase().contains('unknown')) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.location_on,
                    color: AppColors.textGray, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    location,
                    style: AppTextStyles.caption(context).copyWith(
                      color: AppColors.textGray,
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.veryLightGray,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.check_circle,
                        color: AppColors.success, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      completedTime,
                      style: AppTextStyles.caption(context).copyWith(
                        color: AppColors.textGray,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    const Icon(Icons.attach_money,
                        color: AppColors.gold, size: 16),
                    Text(
                      earnings,
                      style: AppTextStyles.body(context).copyWith(
                        color: AppColors.gold,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build a job card from API Job model
  /// Dynamically changes button text and navigation based on job status
  Widget _buildJobCardFromApi({
    required Job job,
    required bool isNextJob,
  }) {
    final vehicle = job.booking?.vehicle;
    final timeSlot = job.timeSlot;
    final booking = job.booking;

    final carName = vehicle?.displayName ?? 'Unknown Vehicle';
    final timeLabel = isNextJob
        ? 'NEXT JOB - ${timeSlot?.formattedStartTime ?? ''}'
        : 'UPCOMING - ${timeSlot?.formattedStartTime ?? ''}';

    // Calculate total price from services
    double totalPrice = 0;
    if (booking != null) {
      for (var service in booking.servicesPayload) {
        totalPrice += double.tryParse(service.price) ?? 0;
      }
    }

    // Common arguments for all navigations
    final commonArgs = {
      'jobId': 'JOB-${job.id}',
      'carModel': vehicle != null ? '${vehicle.brandName} ${vehicle.model}' : 'Unknown Vehicle',
      'carColor': vehicle?.color ?? 'Unknown',
      'employeeName': AuthService().employeeName,
      'earnedAmount': totalPrice,
      'job': job,
    };

    // Determine button text and navigation route based on job status
    String buttonText;
    String navigationRoute;
    
    switch (job.status) {
      case 'assigned':
        buttonText = 'Navigate';
        navigationRoute = '/job-details';
        break;
      case 'en_route':
        buttonText = 'View Map';
        navigationRoute = '/navigate-to-job';
        break;
      case 'arrived':
        buttonText = 'Enter Start OTP';
        navigationRoute = '/job-verification';
        break;
      case 'in_progress':
        buttonText = 'View Progress';
        navigationRoute = '/wash-progress';
        break;
      case 'washed':
        buttonText = 'Complete Job';
        navigationRoute = '/job-completion-otp';
        break;
      default:
        buttonText = 'View Details';
        navigationRoute = '/job-details';
    }
    
    return _buildJobCard(
      time: timeLabel,
      car: carName,
      location: booking?.fullAddress ?? '',
      status: isNextJob ? job.displayStatus : job.displayStatus,
      buttonText: buttonText,
      bgColor: isNextJob ? AppColors.primaryTeal : AppColors.white,
      statusColor: isNextJob ? AppColors.white : AppColors.white,
      textColor: isNextJob ? AppColors.white : AppColors.textDark,
      borderColor: isNextJob ? Colors.transparent : AppColors.primaryTeal,
      iconColor: isNextJob ? AppColors.white : AppColors.primaryTeal,
      onNavigate: isNextJob ? () {
        Navigator.pushNamed(
          context,
          navigationRoute,
          arguments: commonArgs,
        );
      } : null,
      onTap: !isNextJob ? () {
        Navigator.pushNamed(
          context,
          navigationRoute,
          arguments: commonArgs,
        );
      } : null,
    );
  }

  /// Build a completed job card from API Job model
  Widget _buildCompletedJobCardFromApi({
    required Job job,
  }) {
    final vehicle = job.booking?.vehicle;
    final timeSlot = job.timeSlot;
    final booking = job.booking;
    
    final carName = vehicle?.displayName ?? 'Unknown Vehicle';
    final location = booking?.fullAddress ?? '';
    
    // Calculate total price from services
    double totalPrice = 0;
    if (booking != null) {
      for (var service in booking.servicesPayload) {
        totalPrice += double.tryParse(service.price) ?? 0;
      }
    }
    
    return _buildCompletedJobCard(
      time: 'COMPLETED - ${timeSlot?.formattedStartTime ?? ''}',
      car: carName,
      location: location,
      completedTime: 'Completed',
      earnings: '\$${totalPrice.toStringAsFixed(2)}',
    );
  }


  Widget _buildBottomNav() {
    return BottomNavigationBar(
      currentIndex: _currentIndex,
      onTap: (index) {
        debugPrint('Bottom nav tapped: $index');
        setState(() => _currentIndex = index);
      },
      selectedLabelStyle: const TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 12,
      ),
      unselectedLabelStyle: const TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 12,
      ),
      items: [
        BottomNavigationBarItem(
          icon: Icon(Icons.home,
              color: _currentIndex == 0
                  ? AppColors.primaryTeal
                  : AppColors.lightGray),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.calendar_today,
              color: _currentIndex == 1
                  ? AppColors.primaryTeal
                  : AppColors.lightGray),
          label: 'Availability',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person,
              color: _currentIndex == 2
                  ? AppColors.primaryTeal
                  : AppColors.lightGray),
          label: 'Account',
        ),
      ],
    );
  }
}
