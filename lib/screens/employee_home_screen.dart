import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../constants/text_styles.dart';
import '../models/job_model.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import 'availability_widget.dart';
import 'account_widget.dart';

class EmployeeHomeScreen extends StatefulWidget {
  const EmployeeHomeScreen({Key? key}) : super(key: key);

  @override
  State<EmployeeHomeScreen> createState() => _EmployeeHomeScreenState();
}

class _EmployeeHomeScreenState extends State<EmployeeHomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _currentIndex = 0;
  Set<int> availableDates = {};
  int selectedDate = 1;

  // API state
  bool _isLoading = true;
  String? _errorMessage;
  List<Job> _allJobs = [];
  List<Job> get _upcomingJobs => _allJobs.where((job) => !job.isCompleted).toList();
  List<Job> get _completedJobs => _allJobs.where((job) => job.isCompleted).toList();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchTodaysJobs();
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
    debugPrint('Today\'s jobs response: $response');

    if (response['success'] == true) {
      final data = response['data'] as Map<String, dynamic>;
      final jobsList = data['jobs'] as List<dynamic>? ?? [];
      
      setState(() {
        _allJobs = jobsList
            .map((json) => Job.fromJson(json as Map<String, dynamic>))
            .toList();
        _isLoading = false;
      });
      debugPrint('Loaded ${_allJobs.length} jobs');
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
    debugPrint('Building appBar for index: $_currentIndex');
    switch (_currentIndex) {
      case 0:
        return AppBar(
          backgroundColor: AppColors.primaryTeal,
          elevation: 0,
          leading: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Image.asset(
              'assets/images/Gemini_Generated_Image_sx5ts1sx5ts1sx5t.png',
              fit: BoxFit.contain,
            ),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Good Morning, ${AuthService().employeeName}',
                style: AppTextStyles.headline(context).copyWith(
                  color: AppColors.white,
                  fontSize: 20, // AppBar size override
                ),
              ),
              Row(
                children: [
                  const Text(
                    '☁️',
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '25°C',
                    style: AppTextStyles.body(context).copyWith(
                      color: AppColors.white.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      case 1:
        return AppBar(
          title: const Text('Mark Availability'),
          centerTitle: true,
        );
      case 2:
        return AppBar(
          title: const Text('My Account'),
          centerTitle: true,
        );
      default:
        return null;
    }
  }

  Widget _getBody() {
    switch (_currentIndex) {
      case 0:
        return Column(
          children: [
            SingleChildScrollView(
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.gold, width: 2),
                      borderRadius: BorderRadius.circular(12),
                      color: const Color(0xFFFEF5E7),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            "Today's Jobs: ${_allJobs.length}",
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
                                  text: 'Total ',
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
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: AppColors.veryLightGray,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      indicator: BoxDecoration(
                        color: AppColors.primaryTeal,
                        borderRadius: BorderRadius.circular(12),
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
                  const SizedBox(height: 16),
                ],
              ),
            ),
            Expanded(
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
                              : RefreshIndicator(
                                  onRefresh: _fetchTodaysJobs,
                                  child: SingleChildScrollView(
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
                      : RefreshIndicator(
                          onRefresh: _fetchTodaysJobs,
                          child: SingleChildScrollView(
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
                        ),
                ],
              ),
            ),
          ],
        );
      case 1:
        return AvailabilityWidget(
          availableDates: availableDates,
          selectedDate: selectedDate,
          onDateSelected: (date) => setState(() => selectedDate = date),
          onSetAvailable: () => setState(() => availableDates.add(selectedDate)),
          onSetUnavailable: () => setState(() => availableDates.remove(selectedDate)),
        );
      case 2:
        return const AccountWidget();
      default:
        return Container();
    }
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
        borderRadius: BorderRadius.circular(12),
        border: borderColor != Colors.transparent
            ? Border.all(color: borderColor, width: 1.5)
            : null,
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
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
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.directions_car, color: iconColor, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        car,
                        style: AppTextStyles.body(context).copyWith(
                          color: textColor,
                        ),
                      ),
                    ),
                    if (status.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor == AppColors.white
                              ? AppColors.darkNavy.withValues(alpha: 0.8)
                              : statusColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          status,
                          style: AppTextStyles.caption(context).copyWith(
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.location_on, color: iconColor, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        location,
                        style: AppTextStyles.caption(context).copyWith(
                          color: textColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (onNavigate != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              child: ElevatedButton(
                onPressed: onNavigate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFC107),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
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
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.lightGray, width: 1.5),
      ),
      padding: const EdgeInsets.all(16),
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
    final apartment = job.booking?.apartment;
    final timeSlot = job.timeSlot;
    final booking = job.booking;
    
    final carName = vehicle?.displayName ?? 'Unknown Vehicle';
    final location = apartment?.fullAddress ?? 'Unknown Location';
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
      'carModel': vehicle?.brandName ?? 'Unknown',
      'carColor': vehicle?.color ?? '',
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
      location: location,
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
    final apartment = job.booking?.apartment;
    final timeSlot = job.timeSlot;
    final booking = job.booking;
    
    final carName = vehicle?.displayName ?? 'Unknown Vehicle';
    final location = apartment?.fullAddress ?? 'Unknown Location';
    
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
