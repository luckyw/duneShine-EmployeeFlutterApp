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
                expandedHeight: _isShiftStarted ? ResponsiveUtils.h(context, 160) : ResponsiveUtils.h(context, 120),
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
                        colors: [
                          AppColors.white,
                          AppColors.veryLightGray,
                        ],
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
                                  style: AppTextStyles.headline(context).copyWith(
                                    color: AppColors.darkNavy,
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
                actions: [
                   Container(
                     margin: EdgeInsets.only(right: ResponsiveUtils.w(context, 16)),
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
                ],
              ),

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
                      ResponsiveUtils.h(context, 20)
                    ),
                    padding: EdgeInsets.all(ResponsiveUtils.w(context, 16)),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(ResponsiveUtils.r(context, 16)),
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
                                      style: AppTextStyles.headline(context).copyWith(
                                        color: AppColors.darkNavy,
                                        fontSize: ResponsiveUtils.sp(context, 24),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    TextSpan(
                                      text: ' Upcoming',
                                      style: AppTextStyles.body(context).copyWith(
                                        color: AppColors.darkNavy,
                                        fontSize: ResponsiveUtils.sp(context, 14),
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
                      padding: EdgeInsets.symmetric(horizontal: ResponsiveUtils.w(context, 20)),
                      indicator: BoxDecoration(
                        color: AppColors.darkNavy,
                        borderRadius: BorderRadius.circular(ResponsiveUtils.r(context, 30)),
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

  Widget _buildStartShiftView() {
    return Padding(
      padding: EdgeInsets.all(ResponsiveUtils.w(context, 24)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ResponsiveUtils.verticalSpace(context, 40),
          
          ScaleTransition(
            scale: _pulseAnimation,
            child: Container(
              padding: EdgeInsets.all(ResponsiveUtils.w(context, 30)),
              decoration: BoxDecoration(
                color: AppColors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryTeal.withOpacity(0.2),
                    blurRadius: 40,
                    spreadRadius: 10,
                  ),
                  BoxShadow(
                    color: AppColors.primaryTeal.withOpacity(0.1),
                    blurRadius: 60,
                    spreadRadius: 20,
                  ),
                ],
              ),
              child: Icon(
                Icons.work_outline_rounded,
                size: ResponsiveUtils.r(context, 60),
                color: AppColors.primaryTeal,
              ),
            ),
          ),
          
          ResponsiveUtils.verticalSpace(context, 40),
          
          Text(
            'Ready to start?',
            style: AppTextStyles.headline(context).copyWith(
              color: AppColors.darkNavy,
              fontSize: ResponsiveUtils.sp(context, 28),
              fontWeight: FontWeight.w800,
            ),
            textAlign: TextAlign.center,
          ),
          ResponsiveUtils.verticalSpace(context, 48),
          
          SizedBox(
            width: double.infinity,
            height: ResponsiveUtils.h(context, 56),
            child: ElevatedButton(
              onPressed: _isAttendanceLoading ? null : _handleCheckIn,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryTeal,
                foregroundColor: Colors.white,
                elevation: 8,
                shadowColor: AppColors.primaryTeal.withOpacity(0.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(ResponsiveUtils.r(context, 16)),
                ),
              ),
              child: _isAttendanceLoading
                  ? SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.play_arrow_rounded, size: 28),
                        SizedBox(width: 8),
                        Text(
                          'Start Shift Now',
                          style: TextStyle(
                            fontSize: ResponsiveUtils.sp(context, 18),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          
          ResponsiveUtils.verticalSpace(context, 32),
          
          // Preview of upcoming work
          if (_upcomingJobs.isNotEmpty) ...[
             Text(
              "Sneak peek: ${_upcomingJobs.length} jobs waiting",
              style: AppTextStyles.caption(context).copyWith(
                color: AppColors.textGray,
                fontWeight: FontWeight.w600,
              ),
             ),
             ResponsiveUtils.verticalSpace(context, 16),
             // Just show the first one as a preview
             Opacity(
               opacity: 0.6,
               child: _buildJobPreviewItem(_upcomingJobs.first, 0),
             ),
          ],
        ],
      ),
    );
  }

  Widget _buildUpcomingJobsTab() {
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
              Icon(Icons.error_outline, color: AppColors.error, size: 48),
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
      );
    }
    if (_upcomingJobs.isEmpty) {
      return Center(
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
      );
    }
    return ListView.separated(
      padding: EdgeInsets.all(ResponsiveUtils.w(context, 16)),
      itemCount: _upcomingJobs.length,
      separatorBuilder: (context, index) => SizedBox(height: ResponsiveUtils.h(context, 12)),
      itemBuilder: (context, index) {
        // Add a slight delay for entrance animation effect if desired
        // For now just the card
        return _buildJobCardFromApi(
          job: _upcomingJobs[index],
          isNextJob: index == 0,
        );
      },
    );
  }

  Widget _buildCompletedJobsTab() {
    if (_completedJobs.isEmpty) {
      return Center(
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
      );
    }
    return ListView.separated(
      padding: EdgeInsets.all(ResponsiveUtils.w(context, 16)),
      itemCount: _completedJobs.length,
      separatorBuilder: (context, index) => SizedBox(height: ResponsiveUtils.h(context, 12)),
      itemBuilder: (context, index) {
        return _buildCompletedJobCardFromApi(
          job: _completedJobs[index],
        );
      },
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
    Gradient? backgroundGradient,
    VoidCallback? onNavigate,
    VoidCallback? onTap,
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
                  )
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
                          fontWeight: FontWeight.bold,
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
                            fontWeight: FontWeight.bold,
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
              decoration: BoxDecoration(
                color: AppColors.success,
              ),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(ResponsiveUtils.w(context, 16)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header: Time and Status
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          time,
                          style: AppTextStyles.caption(context).copyWith(
                            color: AppColors.textGray.withOpacity(0.8),
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.success.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check_circle_rounded, size: 14, color: AppColors.success),
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
                           child: Icon(Icons.directions_car_filled_rounded, size: 20, color: AppColors.darkNavy),
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
                                      Icon(Icons.location_on_outlined, size: 14, color: AppColors.textGray),
                                      SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          location,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: AppTextStyles.caption(context).copyWith(
                                            color: AppColors.textGray,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                   ],
                                 ),
                               ],
                             ],
                           ),
                         ),
                      ],
                    ),
                    
                    ResponsiveUtils.verticalSpace(context, 16),
                    Divider(height: 1, color: AppColors.lightGray.withOpacity(0.3)),
                    ResponsiveUtils.verticalSpace(context, 12),
                    
                    // Footer: Completed Time & Earnings
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                         Row(
                           children: [
                             Icon(Icons.access_time_rounded, size: 16, color: AppColors.textGray),
                             SizedBox(width: 6),
                             Text(
                               completedTime,
                               style: AppTextStyles.caption(context).copyWith(
                                 fontWeight: FontWeight.w600,
                                 color: AppColors.textGray,
                               ),
                             ),
                           ],
                         ),
                         Container(
                           padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                           decoration: BoxDecoration(
                             color: AppColors.gold.withOpacity(0.12),
                             borderRadius: BorderRadius.circular(12),
                             border: Border.all(color: AppColors.gold.withOpacity(0.3)),
                           ),
                           child: Row(
                             children: [
                               Text(
                                 earnings,
                                 style: AppTextStyles.body(context).copyWith(
                                   fontWeight: FontWeight.w800,
                                   color: Color(0xFFB8860B), // Dark Goldenrod for better readability on light bg
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
        ? 'NEXT JOB • ${timeSlot?.formattedStartTime ?? ''}'
        : 'UPCOMING • ${timeSlot?.formattedStartTime ?? ''}';

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
      'carModel':
          vehicle != null ? '${vehicle.brandName} ${vehicle.model}' : 'Unknown Vehicle',
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
      buttonText: buttonText,
      // For Next Job: use gradient and white text
      // For Normal Job: use white bg and dark text
      bgColor: isNextJob ? AppColors.primaryTeal : AppColors.white,
      backgroundGradient: gradient,
      statusColor: isNextJob ? AppColors.white : AppColors.primaryTeal,
      textColor: isNextJob ? AppColors.white : AppColors.darkNavy,
      borderColor: isNextJob ? Colors.transparent : Colors.transparent,
      iconColor: isNextJob ? AppColors.white : AppColors.textGray,
      onNavigate: isNextJob
          ? () {
              Navigator.pushNamed(
                context,
                navigationRoute,
                arguments: commonArgs,
              );
            }
          : null,
      onTap: !isNextJob
          ? () {
              Navigator.pushNamed(
                context,
                navigationRoute,
                arguments: commonArgs,
              );
            }
          : null,
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

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;

  _SliverAppBarDelegate(this._tabBar);

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
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
