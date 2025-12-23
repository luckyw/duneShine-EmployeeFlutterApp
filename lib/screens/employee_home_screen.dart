import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../constants/text_styles.dart';
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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
                'Good Morning, Ahmed',
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
                            "Today's Jobs: 5",
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
                                  text: '| 2 Done',
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
                  SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: [
                          _buildJobCard(
                            time: 'NEXT JOB - 09:00 AM',
                            car: 'Toyota Camry - White',
                            location: 'Building A, Parking B1, Slot 12',
                            status: '',
                            bgColor: AppColors.primaryTeal,
                            onNavigate: () {
                              Navigator.pushNamed(
                                context,
                                '/job-details',
                                arguments: {
                                  'jobId': 'JOB-56392',
                                  'carModel': 'Toyota Camry',
                                  'carColor': 'White',
                                  'employeeName': 'Ahmed',
                                  'earnedAmount': 120.0,
                                },
                              );
                            },
                          ),
                          const SizedBox(height: 12),
                          _buildJobCard(
                            time: 'UPCOMING - 11:00 AM',
                            car: 'Honda Accord - Black',
                            location: 'Building A, Parking B1, Slot 12',
                            status: 'Pending',
                            statusColor: AppColors.white,
                            bgColor: AppColors.white,
                            borderColor: AppColors.primaryTeal,
                            textColor: AppColors.textDark,
                            iconColor: AppColors.primaryTeal,
                            onTap: () {
                              Navigator.pushNamed(
                                context,
                                '/job-details',
                                arguments: {
                                  'jobId': 'JOB-56393',
                                  'carModel': 'Honda Accord',
                                  'carColor': 'Black',
                                  'employeeName': 'Ahmed',
                                  'earnedAmount': 100.0,
                                },
                              );
                            },
                          ),
                          const SizedBox(height: 12),
                          _buildJobCard(
                            time: 'UPCOMING - 02:00 PM',
                            car: 'BMW X5 - Blue',
                            location: 'Building C, Parking B2, Slot 25',
                            status: 'Pending',
                            statusColor: AppColors.white,
                            bgColor: AppColors.white,
                            borderColor: AppColors.primaryTeal,
                            textColor: AppColors.textDark,
                            iconColor: AppColors.primaryTeal,
                            onTap: () {
                              Navigator.pushNamed(
                                context,
                                '/job-details',
                                arguments: {
                                  'jobId': 'JOB-56394',
                                  'carModel': 'BMW X5',
                                  'carColor': 'Blue',
                                  'employeeName': 'Ahmed',
                                  'earnedAmount': 150.0,
                                },
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Completed Jobs Tab
                  SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: [
                          _buildCompletedJobCard(
                            time: 'COMPLETED - 08:00 AM',
                            car: 'Mercedes-Benz C-Class - Silver',
                            location: 'Building A, Parking B1, Slot 05',
                            completedTime: 'Completed at 08:45 AM',
                            earnings: '\$25.00',
                          ),
                          const SizedBox(height: 12),
                          _buildCompletedJobCard(
                            time: 'COMPLETED - 07:00 AM',
                            car: 'Audi A4 - Black',
                            location: 'Building B, Parking B3, Slot 18',
                            completedTime: 'Completed at 07:30 AM',
                            earnings: '\$20.00',
                          ),
                          const SizedBox(height: 12),
                          _buildCompletedJobCard(
                            time: 'COMPLETED - Yesterday',
                            car: 'Tesla Model 3 - Red',
                            location: 'Building A, Parking B1, Slot 30',
                            completedTime: 'Completed at 05:15 PM',
                            earnings: '\$30.00',
                          ),
                          const SizedBox(height: 12),
                          _buildCompletedJobCard(
                            time: 'COMPLETED - Yesterday',
                            car: 'Lexus ES - White',
                            location: 'Building C, Parking B2, Slot 42',
                            completedTime: 'Completed at 03:20 PM',
                            earnings: '\$22.00',
                          ),
                        ],
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
                  'Navigate',
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
