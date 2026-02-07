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
import 'package:url_launcher/url_launcher.dart';

class EmployeeHomeScreen extends StatefulWidget {
  const EmployeeHomeScreen({Key? key}) : super(key: key);

  @override
  State<EmployeeHomeScreen> createState() => _EmployeeHomeScreenState();
}

class _EmployeeHomeScreenState extends State<EmployeeHomeScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
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
        // Prioritize job's startTime, fallback to timeSlot.startTime
        final aTime = a.startTime ?? a.timeSlot?.startTime ?? '99:99:99';
        final bTime = b.startTime ?? b.timeSlot?.startTime ?? '99:99:99';
        return aTime.compareTo(bTime);
      });
  }

  List<Job> get _completedJobs =>
      _allJobs.where((job) => job.isCompleted).toList();

  // Profile state
  EmployeeProfileModel? _profile;

  // Notification state
  bool _hasViewedNotifications = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Setup Pulse Animation for Start Shift Button
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _isShiftStarted = AuthService().isShiftStarted;
    _fetchTodaysJobs();
    _fetchProfile();

    // Ensure tracking is active if shift is already started
    if (_isShiftStarted) {
      final employeeId = AuthService().employeeId;
      final token = AuthService().token;
      if (employeeId != null) {
        BackgroundLocationService.start(employeeId, token: token);
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
        final apiShiftStarted =
            data['session_status'] == 1 ||
            data['session_status'] == true ||
            data['session_status'] == '1';
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
        final apiShiftStarted =
            data['session_status'] == 1 ||
            data['session_status'] == true ||
            data['session_status'] == '1';
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
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _handleCheckIn() async {
    final token = AuthService().token;
    if (token == null) return;

    setState(() {
      _isAttendanceLoading = true;
    });

    // Request permissions before starting shift
    bool hasPermission = await LocationTrackingService()
        .requestLocationPermission();
    if (!hasPermission) {
      if (mounted) {
        ToastUtils.showErrorToast(
          context,
          'Location permission is required to start shift',
        );
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
          BackgroundLocationService.start(employeeId, token: token);
        }

        ToastUtils.showSuccessToast(context, 'Shift started! Good luck today!');
      } else {
        setState(() {
          _isAttendanceLoading = false;
        });

        // Check if already checked in - offer to check out
        final message = result['message']?.toString().toLowerCase() ?? '';
        if (message.contains('you are already checked in') ||
            message.contains('already checked in') ||
            message.contains('already check in') ||
            message.contains('already started')) {
          _showCheckOutDialog();
        } else {
          ToastUtils.showErrorToast(
            context,
            result['message'] ?? 'Failed to start shift',
          );
        }
      }
    }
  }

  /// Show dialog asking if user wants to check out
  void _showCheckOutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ResponsiveUtils.r(context, 16)),
        ),
        title: Row(
          children: [
            Icon(
              Icons.info_outline,
              color: AppColors.primaryTeal,
              size: ResponsiveUtils.r(context, 24),
            ),
            ResponsiveUtils.horizontalSpace(context, 8),
            Expanded(
              child: Text(
                'Already Checked In',
                style: TextStyle(
                  fontSize: ResponsiveUtils.sp(context, 18),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          'You are already checked in. Would you like to check out and end your shift?',
          style: TextStyle(
            fontSize: ResponsiveUtils.sp(context, 14),
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: AppColors.textGray,
                fontSize: ResponsiveUtils.sp(context, 14),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _handleCheckOut();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryTeal,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  ResponsiveUtils.r(context, 8),
                ),
              ),
              padding: EdgeInsets.symmetric(
                horizontal: ResponsiveUtils.w(context, 16),
                vertical: ResponsiveUtils.h(context, 8),
              ),
            ),
            child: Text(
              'Check Out',
              style: TextStyle(
                fontSize: ResponsiveUtils.sp(context, 14),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Handle check-out API call
  Future<void> _handleCheckOut() async {
    final token = AuthService().token;
    if (token == null) return;

    setState(() {
      _isAttendanceLoading = true;
    });

    final result = await ApiService().checkOut(token: token);

    if (mounted) {
      setState(() {
        _isAttendanceLoading = false;
      });

      if (result['success'] == true) {
        AuthService().setShiftStatus(false);
        setState(() {
          _isShiftStarted = false;
        });

        // Stop background tracking service
        BackgroundLocationService.stop();

        ToastUtils.showSuccessToast(
          context,
          'Checked out successfully. Great work today!',
        );
      } else {
        ToastUtils.showErrorToast(
          context,
          result['message'] ?? 'Failed to check out',
        );
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
      message:
          'You have been assigned a new job at Downtown Mall. Please confirm your availability.',
      time: '10:30 AM',
      isRead: false,
    ),
    const NotificationModel(
      id: 2,
      title: 'Job Reminder',
      message:
          'Your shift at City Center starts in 30 minutes. Please ensure you are on time.',
      time: '09:45 AM',
      isRead: false,
    ),
    const NotificationModel(
      id: 3,
      title: 'Job Completed',
      message:
          'Great job! Your job at Riverside Apartments has been marked as completed.',
      time: 'Yesterday',
      isRead: true,
    ),
    const NotificationModel(
      id: 4,
      title: 'Schedule Update',
      message:
          'Your schedule for next week has been updated. Please review your upcoming shifts.',
      time: '2 days ago',
      isRead: true,
    ),
    const NotificationModel(
      id: 5,
      title: 'Payment Received',
      message:
          'Your payment of \$125.50 for this week has been processed and will be deposited soon.',
      time: '3 days ago',
      isRead: true,
    ),
  ];

  void _showNotificationSheet(BuildContext context) {
    // Mark notifications as viewed when opening the sheet
    if (!_hasViewedNotifications) {
      setState(() {
        _hasViewedNotifications = true;
      });
    }

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
                style: AppTextStyles.headline(
                  context,
                ).copyWith(fontSize: 20, color: AppColors.darkNavy),
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
    // If user has viewed notifications, treat all as read
    final bool isRead = _hasViewedNotifications || notification.isRead;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isRead ? AppColors.veryLightGray : AppColors.creamBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isRead ? AppColors.lightGray : AppColors.gold,
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
              color: isRead
                  ? AppColors.lightGray.withOpacity(0.2)
                  : AppColors.gold.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isRead ? Icons.notifications_none : Icons.notifications_active,
              color: isRead ? AppColors.textGray : AppColors.gold,
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
                    fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                    color: AppColors.darkNavy,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  notification.message,
                  style: AppTextStyles.body(
                    context,
                  ).copyWith(fontSize: 12, color: AppColors.textGray),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  notification.time,
                  style: AppTextStyles.body(
                    context,
                  ).copyWith(fontSize: 10, color: AppColors.lightGray),
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
    // If we are on the home tab (0), we want the SliverAppBar to be part of the body
    // So we don't pass an appBar to the Scaffold in that case.
    final bool isHomeTab = _currentIndex == 0;

    return Scaffold(
      backgroundColor: AppColors.veryLightGray,
      appBar: isHomeTab ? null : _getAppBar(),
      body: _getBody(),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  AppBar? _getAppBar() {
    switch (_currentIndex) {
      case 1:
        return AppBar(
          title: Text(
            'Mark Availability',
            style: AppTextStyles.headline(context).copyWith(
              fontSize: ResponsiveUtils.sp(context, 20),
              color: AppColors.darkNavy,
            ),
          ),
          centerTitle: true,
          backgroundColor: AppColors.white,
          elevation: 0,
        );
      case 2:
        return AppBar(
          title: Text(
            'My Account',
            style: AppTextStyles.headline(context).copyWith(
              fontSize: ResponsiveUtils.sp(context, 20),
              color: Colors.white,
            ),
          ),
          centerTitle: true,
          backgroundColor: AppColors.primaryTeal,
          elevation: 0,
        );
      default:
        // For index 0, we return null here as it's handled in the body
        return null;
    }
  }

  Widget _getBody() {
    switch (_currentIndex) {
      case 0:
        // Main Home Tab
        return RefreshIndicator(
          onRefresh: _fetchTodaysJobs,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // 1. Premium Sliver App Bar
              SliverAppBar(
                expandedHeight: _isShiftStarted
                    ? ResponsiveUtils.h(context, 160)
                    : ResponsiveUtils.h(context, 120),
                floating: false,
                pinned: true,
                backgroundColor: AppColors.veryLightGray,
                elevation: 0,
                flexibleSpace: FlexibleSpaceBar(
                  centerTitle: false,
                  titlePadding: EdgeInsets.only(
                    left: ResponsiveUtils.w(context, 20),
                    bottom: ResponsiveUtils.h(context, 16),
                  ),
                  title: _isShiftStarted
                      ? null // Custom content in background for shift started
                      : RichText(
                          text: TextSpan(
                            style: AppTextStyles.headline(context).copyWith(
                              color: AppColors.darkNavy,
                              fontSize: ResponsiveUtils.sp(context, 24),
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
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [AppColors.white, AppColors.veryLightGray],
                      ),
                    ),
                    child: Stack(
                      children: [
                        // Decorative Elements
                        Positioned(
                          right: -50,
                          top: -50,
                          child: Container(
                            width: 200,
                            height: 200,
                            decoration: BoxDecoration(
                              color: AppColors.primaryTeal.withOpacity(0.05),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),

                        // Content for Shift Started
                        if (_isShiftStarted)
                          Positioned(
                            left: ResponsiveUtils.w(context, 20),
                            right: ResponsiveUtils.w(context, 20),
                            bottom: ResponsiveUtils.h(context, 60),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _getGreeting(),
                                  style: AppTextStyles.body(context).copyWith(
                                    color: AppColors.textGray,
                                    fontSize: ResponsiveUtils.sp(context, 14),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _profile?.name ?? AuthService().employeeName,
                                  style: AppTextStyles.headline(context)
                                      .copyWith(
                                        color: AppColors.darkNavy,
                                        fontSize: ResponsiveUtils.sp(
                                          context,
                                          24,
                                        ),
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ), // background Container
                ), // FlexibleSpaceBar
                actions: [
                  Container(
                    margin: EdgeInsets.only(
                      right: ResponsiveUtils.w(context, 16),
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: IconButton(
                      onPressed: () => _showNotificationSheet(context),
                      icon: Icon(
                        Icons.notifications_outlined,
                        color: AppColors.darkNavy,
                        size: ResponsiveUtils.sp(context, 24),
                      ),
                    ),
                  ),
                  if (_isShiftStarted)
                    Container(
                      margin: EdgeInsets.only(
                        right: ResponsiveUtils.w(context, 12),
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade700,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.orange.withOpacity(0.3),
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: IconButton(
                        onPressed: _isAttendanceLoading
                            ? null
                            : _handleCheckOut,
                        icon: _isAttendanceLoading
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.white,
                                ),
                              )
                            : Icon(
                                Icons.stop_circle_outlined,
                                color: AppColors.white,
                                size: ResponsiveUtils.sp(context, 24),
                              ),
                        tooltip: 'End Shift',
                      ),
                    ),
                ],
              ), // SliverAppBar
              // 2. Main Content
              if (!_isShiftStarted)
                SliverToBoxAdapter(child: _buildStartShiftView())
              else ...[
                // Stats Row
                SliverToBoxAdapter(
                  child: Container(
                    margin: EdgeInsets.fromLTRB(
                      ResponsiveUtils.w(context, 20),
                      0,
                      ResponsiveUtils.w(context, 20),
                      ResponsiveUtils.h(context, 20),
                    ),
                    padding: EdgeInsets.all(ResponsiveUtils.w(context, 16)),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(
                        ResponsiveUtils.r(context, 16),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.darkNavy.withOpacity(0.08),
                          blurRadius: 15,
                          offset: Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Today's Schedule",
                                style: AppTextStyles.title(context).copyWith(
                                  color: AppColors.textGray,
                                  fontSize: ResponsiveUtils.sp(context, 14),
                                ),
                              ),
                              SizedBox(height: 4),
                              RichText(
                                text: TextSpan(
                                  children: [
                                    TextSpan(
                                      text: '${_upcomingJobs.length}',
                                      style: AppTextStyles.headline(context)
                                          .copyWith(
                                            color: AppColors.darkNavy,
                                            fontSize: ResponsiveUtils.sp(
                                              context,
                                              24,
                                            ),
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                    TextSpan(
                                      text: ' Upcoming',
                                      style: AppTextStyles.body(context)
                                          .copyWith(
                                            color: AppColors.darkNavy,
                                            fontSize: ResponsiveUtils.sp(
                                              context,
                                              14,
                                            ),
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          height: 40,
                          width: 1,
                          color: AppColors.lightGray.withOpacity(0.5),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                "Completed",
                                style: AppTextStyles.title(context).copyWith(
                                  color: AppColors.textGray,
                                  fontSize: ResponsiveUtils.sp(context, 14),
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                '${_completedJobs.length}',
                                style: AppTextStyles.headline(context).copyWith(
                                  color: AppColors.primaryTeal,
                                  fontSize: ResponsiveUtils.sp(context, 24),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Tabs
                SliverPersistentHeader(
                  delegate: _SliverAppBarDelegate(
                    TabBar(
                      controller: _tabController,
                      padding: EdgeInsets.symmetric(
                        horizontal: ResponsiveUtils.w(context, 20),
                      ),
                      indicator: BoxDecoration(
                        color: AppColors.darkNavy,
                        borderRadius: BorderRadius.circular(
                          ResponsiveUtils.r(context, 30),
                        ),
                      ),
                      indicatorSize: TabBarIndicatorSize.tab,
                      labelColor: AppColors.white,
                      unselectedLabelColor: AppColors.textGray,
                      labelStyle: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: ResponsiveUtils.sp(context, 14),
                        fontFamily: 'Manrope',
                      ),
                      unselectedLabelStyle: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: ResponsiveUtils.sp(context, 14),
                        fontFamily: 'Manrope',
                      ),
                      tabs: const [
                        Tab(text: 'Upcoming Jobs'),
                        Tab(text: 'History'),
                      ],
                    ),
                  ),
                  pinned: true,
                ),

                SliverFillRemaining(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // Upcoming Jobs Tab
                      _buildUpcomingJobsTab(),

                      // Completed Jobs Tab
                      _buildCompletedJobsTab(),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      case 1:
        return const AvailabilityWidget();
      case 2:
        return AccountWidget(
          isShiftStarted: _isShiftStarted,
          onShiftEnded: () {
            setState(() {
              _isShiftStarted = false;
              AuthService().setShiftStatus(false);
              _tabController.index = 0;
            });
            _fetchTodaysJobs();
          },
        );
      default:
        return Container();
    }
  }

  /// Build the "Start Shift" view when user is not checked in
  Widget _buildStartShiftView() {
    return Container(
      margin: EdgeInsets.all(ResponsiveUtils.w(context, 20)),
      padding: EdgeInsets.all(ResponsiveUtils.w(context, 24)),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(ResponsiveUtils.r(context, 20)),
        boxShadow: [
          BoxShadow(
            color: AppColors.darkNavy.withOpacity(0.1),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.access_time_rounded,
            size: ResponsiveUtils.r(context, 64),
            color: AppColors.primaryTeal,
          ),
          ResponsiveUtils.verticalSpace(context, 16),
          Text(
            'Ready to start your shift?',
            style: AppTextStyles.headline(context).copyWith(
              color: AppColors.darkNavy,
              fontSize: ResponsiveUtils.sp(context, 20),
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          ResponsiveUtils.verticalSpace(context, 8),
          Text(
            'Check in to view your assigned jobs for today',
            style: AppTextStyles.body(context).copyWith(
              color: AppColors.textGray,
              fontSize: ResponsiveUtils.sp(context, 14),
            ),
            textAlign: TextAlign.center,
          ),
          ResponsiveUtils.verticalSpace(context, 24),
          SizedBox(
            width: double.infinity,
            height: ResponsiveUtils.h(context, 56),
            child: ElevatedButton(
              onPressed: _isAttendanceLoading ? null : _handleCheckIn,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryTeal,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    ResponsiveUtils.r(context, 12),
                  ),
                ),
                elevation: 0,
              ),
              child: _isAttendanceLoading
                  ? SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.white,
                      ),
                    )
                  : Text(
                      'Start Shift',
                      style: AppTextStyles.button(context).copyWith(
                        color: AppColors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build the Upcoming Jobs tab content
  Widget _buildUpcomingJobsTab() {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(color: AppColors.primaryTeal),
      );
    }

    if (_upcomingJobs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_available, size: 64, color: AppColors.lightGray),
            ResponsiveUtils.verticalSpace(context, 16),
            Text(
              'No upcoming jobs',
              style: AppTextStyles.body(context).copyWith(
                color: AppColors.textGray,
                fontWeight: FontWeight.bold,
              ),
            ),
            ResponsiveUtils.verticalSpace(context, 8),
            Text(
              'You have no scheduled jobs for today',
              style: AppTextStyles.caption(
                context,
              ).copyWith(color: AppColors.lightGray),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(ResponsiveUtils.w(context, 20)),
      itemCount: _upcomingJobs.length,
      itemBuilder: (context, index) {
        final job = _upcomingJobs[index];
        return Padding(
          padding: EdgeInsets.only(bottom: ResponsiveUtils.h(context, 12)),
          child: _buildJobCardFromApi(job: job, isNextJob: index == 0),
        );
      },
    );
  }

  /// Build the Completed Jobs tab content
  Widget _buildCompletedJobsTab() {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(color: AppColors.primaryTeal),
      );
    }

    if (_completedJobs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 64,
              color: AppColors.lightGray,
            ),
            ResponsiveUtils.verticalSpace(context, 16),
            Text(
              'No completed jobs',
              style: AppTextStyles.body(context).copyWith(
                color: AppColors.textGray,
                fontWeight: FontWeight.bold,
              ),
            ),
            ResponsiveUtils.verticalSpace(context, 8),
            Text(
              'Jobs you complete will appear here',
              style: AppTextStyles.caption(
                context,
              ).copyWith(color: AppColors.lightGray),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(ResponsiveUtils.w(context, 20)),
      itemCount: _completedJobs.length,
      itemBuilder: (context, index) {
        final job = _completedJobs[index];
        return Padding(
          padding: EdgeInsets.only(bottom: ResponsiveUtils.h(context, 12)),
          child: _buildCompletedJobCardFromApi(job: job),
        );
      },
    );
  }

  Widget _buildJobCard({
    required String time,
    required String car,
    required String location,
    required String status,
    List<ServicePayload> services = const [],
    String buttonText = 'Navigate',
    String jobId = '',
    Color bgColor = AppColors.primaryTeal,
    Color statusColor = Colors.transparent,
    Color textColor = AppColors.white,
    Color borderColor = Colors.transparent,
    Color iconColor = AppColors.white,
    Gradient? backgroundGradient,
    VoidCallback? onNavigate,
    VoidCallback? onTap,
    VoidCallback? onMapTap, // New callback for map button
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: backgroundGradient == null ? bgColor : null,
          gradient: backgroundGradient,
          borderRadius: BorderRadius.circular(ResponsiveUtils.r(context, 16)),
          border: borderColor != Colors.transparent
              ? Border.all(color: borderColor, width: 1.5)
              : null,
          boxShadow: backgroundGradient != null
              ? [
                  BoxShadow(
                    color: AppColors.primaryTeal.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
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
                    style: AppTextStyles.body(
                      context,
                    ).copyWith(color: textColor, fontWeight: FontWeight.bold),
                  ),
                  ResponsiveUtils.verticalSpace(context, 4),
                  Text(
                    jobId,
                    style: AppTextStyles.caption(
                      context,
                    ).copyWith(color: textColor.withOpacity(0.7)),
                  ),
                  ResponsiveUtils.verticalSpace(context, 12),
                  Row(
                    children: [
                      Icon(
                        Icons.directions_car,
                        color: iconColor,
                        size: ResponsiveUtils.r(context, 20),
                      ),
                      ResponsiveUtils.horizontalSpace(context, 8),
                      Expanded(
                        child: Text(
                          car,
                          style: AppTextStyles.body(context).copyWith(
                            color: textColor,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (status.isNotEmpty)
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: ResponsiveUtils.w(context, 8),
                            vertical: ResponsiveUtils.h(context, 4),
                          ),
                          decoration: BoxDecoration(
                            color: statusColor == AppColors.white
                                ? AppColors.darkNavy.withValues(alpha: 0.8)
                                : statusColor.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(
                              ResponsiveUtils.r(context, 4),
                            ),
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
                  if (services.isNotEmpty) ...[
                    ResponsiveUtils.verticalSpace(context, 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: services.map((service) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 2),
                          child: Row(
                            children: [
                              Icon(Icons.circle, color: iconColor, size: 6),
                              ResponsiveUtils.horizontalSpace(context, 8),
                              Expanded(
                                child: Text(
                                  service.name,
                                  style: AppTextStyles.caption(context)
                                      .copyWith(
                                        color: textColor,
                                        fontWeight: FontWeight.w500,
                                      ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                  if (location.isNotEmpty &&
                      !location.toLowerCase().contains('unknown')) ...[
                    ResponsiveUtils.verticalSpace(context, 8),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          color: iconColor,
                          size: ResponsiveUtils.r(context, 20),
                        ),
                        ResponsiveUtils.horizontalSpace(context, 8),
                        Expanded(
                          child: Text(
                            location,
                            style: AppTextStyles.caption(context).copyWith(
                              color: textColor,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (onMapTap != null) ...[
                          ResponsiveUtils.horizontalSpace(context, 8),
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: onMapTap,
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: textColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: textColor.withOpacity(0.3),
                                  ),
                                ),
                                child: Icon(
                                  Icons.map_outlined,
                                  size: 18,
                                  color: textColor,
                                ),
                              ),
                            ),
                          ),
                        ],
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
                      borderRadius: BorderRadius.circular(
                        ResponsiveUtils.r(context, 12),
                      ),
                    ),
                  ),
                  child: Text(
                    buttonText,
                    style: AppTextStyles.button(
                      context,
                    ).copyWith(color: AppColors.darkNavy),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompletedJobCard({
    required String car,
    required String location,
    List<ServicePayload> services = const [],
    String jobId = '',
    String? arrivedAt,
    String? completedAt,
  }) {
    // Parse timestamps and calculate duration
    String startTimeDisplay = '';
    String endTimeDisplay = '';
    String durationDisplay = '';
    
    if (arrivedAt != null && arrivedAt.isNotEmpty) {
      try {
        final arrived = DateTime.parse(arrivedAt).toLocal();
        final hour = arrived.hour > 12 ? arrived.hour - 12 : (arrived.hour == 0 ? 12 : arrived.hour);
        final period = arrived.hour >= 12 ? 'PM' : 'AM';
        startTimeDisplay = '${hour.toString().padLeft(2, '0')}:${arrived.minute.toString().padLeft(2, '0')} $period';
      } catch (_) {}
    }
    
    if (completedAt != null && completedAt.isNotEmpty) {
      try {
        final completed = DateTime.parse(completedAt).toLocal();
        final hour = completed.hour > 12 ? completed.hour - 12 : (completed.hour == 0 ? 12 : completed.hour);
        final period = completed.hour >= 12 ? 'PM' : 'AM';
        endTimeDisplay = '${hour.toString().padLeft(2, '0')}:${completed.minute.toString().padLeft(2, '0')} $period';
        
        // Calculate duration
        if (arrivedAt != null && arrivedAt.isNotEmpty) {
          final arrived = DateTime.parse(arrivedAt).toLocal();
          final diff = completed.difference(arrived);
          if (diff.inMinutes < 60) {
            durationDisplay = '${diff.inMinutes} min';
          } else {
            final hours = diff.inHours;
            final mins = diff.inMinutes % 60;
            durationDisplay = mins > 0 ? '${hours}h ${mins}m' : '${hours}h';
          }
        }
      } catch (_) {}
    }
    return Container(
      margin: EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(ResponsiveUtils.r(context, 16)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Green success strip
            Container(
              width: 6,
              decoration: BoxDecoration(color: AppColors.success),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(ResponsiveUtils.w(context, 16)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header: Job ID and Status
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          jobId,
                          style: AppTextStyles.caption(context).copyWith(
                            color: AppColors.textGray.withOpacity(0.8),
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.success.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.check_circle_rounded,
                                size: 14,
                                color: AppColors.success,
                              ),
                              SizedBox(width: 4),
                              Text(
                                "Completed",
                                style: TextStyle(
                                  color: AppColors.success,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  fontFamily: 'Manrope',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    ResponsiveUtils.verticalSpace(context, 16),

                    // Vehicle Info
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.veryLightGray,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.directions_car_filled_rounded,
                            size: 20,
                            color: AppColors.darkNavy,
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                car,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.body(context).copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.darkNavy,
                                  fontSize: ResponsiveUtils.sp(context, 16),
                                ),
                              ),
                              if (location.isNotEmpty) ...[
                                SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.location_on_outlined,
                                      size: 14,
                                      color: AppColors.textGray,
                                    ),
                                    SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        location,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: AppTextStyles.caption(context)
                                            .copyWith(
                                              color: AppColors.textGray,
                                              fontWeight: FontWeight.w500,
                                            ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                              if (services.isNotEmpty) ...[
                                SizedBox(height: 4),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: services.map((service) {
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 2),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.circle,
                                            size: 4,
                                            color: AppColors.textGray,
                                          ),
                                          SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              service.name,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style:
                                                  AppTextStyles.caption(
                                                    context,
                                                  ).copyWith(
                                                    color: AppColors.textGray,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),

                    ResponsiveUtils.verticalSpace(context, 16),
                    Divider(
                      height: 1,
                      color: AppColors.lightGray.withOpacity(0.3),
                    ),
                    ResponsiveUtils.verticalSpace(context, 12),

                    // Footer: Start/End Time and Duration
                    Row(
                      children: [
                        if (startTimeDisplay.isNotEmpty) ...[
                          Icon(
                            Icons.login_rounded,
                            size: 14,
                            color: AppColors.primaryTeal,
                          ),
                          SizedBox(width: 4),
                          Text(
                            startTimeDisplay,
                            style: AppTextStyles.caption(context).copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryTeal,
                            ),
                          ),
                        ],
                        if (endTimeDisplay.isNotEmpty) ...[
                          SizedBox(width: 12),
                          Icon(
                            Icons.logout_rounded,
                            size: 14,
                            color: AppColors.success,
                          ),
                          SizedBox(width: 4),
                          Text(
                            endTimeDisplay,
                            style: AppTextStyles.caption(context).copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.success,
                            ),
                          ),
                        ],
                        Spacer(),
                        if (durationDisplay.isNotEmpty)
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.amber.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.timer_outlined,
                                  size: 14,
                                  color: AppColors.amber,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  durationDisplay,
                                  style: AppTextStyles.caption(context).copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.amber,
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
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _launchMap(String lat, String lng) async {
    final googleMapsUrl =
        Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    if (!await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ToastUtils.showErrorToast(context, 'Could not launch maps');
      }
    }
  }

  /// Build a job card from API Job model
  /// Dynamically changes button text and navigation based on job status
  Widget _buildJobCardFromApi({required Job job, required bool isNextJob}) {
    final vehicle = job.booking?.vehicle;
    final timeSlot = job.timeSlot;
    final booking = job.booking;

    final carName = vehicle?.displayName ?? 'Unknown Vehicle';
    // Parse start_time directly to ensure we prioritize it
    // Fallback to time slot only if start_time is not available
    String displayTime = '';
    if (job.startTime != null && job.startTime!.isNotEmpty) {
      // Use the job's specific start time
      try {
        final parts = job.startTime!.split(':');
        if (parts.length >= 2) {
          int hour = int.parse(parts[0]);
          final minute = parts[1];
          final period = hour >= 12 ? 'PM' : 'AM';
          if (hour > 12) hour -= 12;
          if (hour == 0) hour = 12;
          displayTime = '${hour.toString().padLeft(2, '0')}:$minute $period';
        } else {
          displayTime = job.startTime!;
        }
      } catch (_) {
        displayTime = job.startTime!;
      }
    } else if (timeSlot != null) {
      // Fallback to time slot range if no specific start time
      displayTime = timeSlot.formattedStartTime;
    } else {
      displayTime = 'Scheduled';
    }

    final timeLabel = isNextJob
        ? 'NEXT JOB • $displayTime'
        : 'UPCOMING • $displayTime';

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
      'carModel': vehicle != null
          ? '${vehicle.brandName} ${vehicle.model}'
          : 'Unknown Vehicle',
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
        buttonText = 'Start Journey';
        navigationRoute = '/job-details';
        break;
      case 'en_route':
        buttonText = 'View Map';
        navigationRoute = '/navigate-to-job';
        break;
      case 'arrived':
        // For subscription jobs, skip OTP and go directly to photo upload
        if (job.isSubscription) {
          buttonText = 'Upload Photo';
          navigationRoute = '/job-arrival-photo';
        } else {
          buttonText = 'Enter Start OTP';
          navigationRoute = '/job-verification';
        }
        break;
      case 'in_progress':
        buttonText = 'View Progress';
        navigationRoute = '/wash-progress';
        break;
      case 'washed':
        // For subscription jobs, skip OTP and go directly to completion photo
        if (job.isSubscription) {
          buttonText = 'Upload Completion Photo';
          navigationRoute = '/job-completion-proof';
        } else {
          buttonText = 'Complete Job';
          navigationRoute = '/job-completion-otp';
        }
        break;
      default:
        buttonText = 'View Details';
        navigationRoute = '/job-details';
    }

    // Navigation callback
    final VoidCallback onNavigate = () {
      Navigator.pushNamed(
        context,
        navigationRoute,
        arguments: commonArgs,
      );
    };

    // Map Button Callback
    VoidCallback? onMapTap;
    final lat = job.booking?.property?.resolvedLatitude;
    final lng = job.booking?.property?.resolvedLongitude;
    
    if (lat != null && lat.isNotEmpty && lng != null && lng.isNotEmpty) {
      onMapTap = () => _launchMap(lat, lng);
    } else if (job.booking?.property?.latitude != null && 
               job.booking?.property?.longitude != null) {
       // Fallback to basic lat/long if resolved is missing
       onMapTap = () => _launchMap(
         job.booking!.property!.latitude!, 
         job.booking!.property!.longitude!
       );
    }


    final gradient = isNextJob
        ? const LinearGradient(
            colors: [Color(0xFF00334E), Color(0xFF006D77)], // Navy to Teal
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
        : null;

    return _buildJobCard(
      time: timeLabel,
      car: carName,
      location: booking?.fullAddress ?? '',
      status: job.displayStatus,
      services: booking?.servicesPayload ?? [],
      buttonText: buttonText,
      jobId: 'JOB-${job.id}',
      // For Next Job: use gradient and white text
      // For Normal Job: use white bg and dark text
      bgColor: isNextJob ? AppColors.primaryTeal : AppColors.white,
      backgroundGradient: gradient,
      statusColor: isNextJob ? AppColors.white : AppColors.primaryTeal,
      textColor: isNextJob ? AppColors.white : AppColors.darkNavy,
      borderColor: isNextJob ? Colors.transparent : Colors.transparent,
      iconColor: isNextJob ? AppColors.white : AppColors.textGray,
      // Pass the navigation callback to both the button and the card tap
      onNavigate: isNextJob ? onNavigate : null,
      onTap: onNavigate,
      onMapTap: onMapTap,
    );
  }

  /// Build a completed job card from API Job model
  Widget _buildCompletedJobCardFromApi({required Job job}) {
    final vehicle = job.booking?.vehicle;
    final booking = job.booking;

    final carName = vehicle?.displayName ?? 'Unknown Vehicle';
    final location = booking?.fullAddress ?? '';

    return _buildCompletedJobCard(
      car: carName,
      location: location,
      services: booking?.servicesPayload ?? [],
      jobId: 'JOB-${job.id}',
      arrivedAt: job.arrivedAt,
      completedAt: job.completedAt,
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
          icon: Icon(
            _currentIndex == 0 ? Icons.home_rounded : Icons.home_outlined,
            color: _currentIndex == 0
                ? AppColors.primaryTeal
                : AppColors.lightGray,
          ),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(
            _currentIndex == 1
                ? Icons.calendar_month_rounded
                : Icons.calendar_today_outlined,
            color: _currentIndex == 1
                ? AppColors.primaryTeal
                : AppColors.lightGray,
          ),
          label: 'Availability',
        ),
        BottomNavigationBarItem(
          icon: Icon(
            _currentIndex == 2 ? Icons.person_rounded : Icons.person_outline,
            color: _currentIndex == 2
                ? AppColors.primaryTeal
                : AppColors.lightGray,
          ),
          label: 'Account',
        ),
      ],
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;

  _SliverAppBarDelegate(this._tabBar);

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: AppColors.veryLightGray, // Match background
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
