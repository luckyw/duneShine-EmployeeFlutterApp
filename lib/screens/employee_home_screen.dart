import 'package:flutter/material.dart';
import '../constants/colors.dart';
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
          backgroundColor: const Color(0xFF1A3A52),
          elevation: 0,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Good Morning, Ahmed',
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
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
                    style: TextStyle(
                      color: AppColors.white.withOpacity(0.8),
                      fontSize: 14,
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
                          child: const Text(
                            "Today's Jobs: 5",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.darkNavy,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: RichText(
                            text: const TextSpan(
                              children: [
                                TextSpan(
                                  text: 'Total ',
                                  style: TextStyle(
                                    color: AppColors.darkNavy,
                                    fontSize: 14,
                                  ),
                                ),
                                TextSpan(
                                  text: '| 2 Done',
                                  style: TextStyle(
                                    color: AppColors.primaryTeal,
                                    fontSize: 14,
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
                            statusColor: AppColors.primaryTeal,
                            bgColor: const Color(0xFF1A3A52),
                          ),
                          const SizedBox(height: 12),
                          _buildJobCard(
                            time: 'UPCOMING - 02:00 PM',
                            car: 'BMW X5 - Blue',
                            location: 'Building C, Parking B2, Slot 25',
                            status: 'Pending',
                            statusColor: AppColors.primaryTeal,
                            bgColor: const Color(0xFF1A3A52),
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
    VoidCallback? onNavigate,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
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
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.directions_car,
                        color: AppColors.white, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        car,
                        style: const TextStyle(
                          color: AppColors.white,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    if (status.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          status,
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.location_on,
                        color: AppColors.white, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        location,
                        style: const TextStyle(
                          color: AppColors.white,
                          fontSize: 12,
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
                child: const Text(
                  'Navigate',
                  style: TextStyle(
                    color: AppColors.darkNavy,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
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
        color: const Color(0xFF4CAF50), // Green color for completed jobs
        borderRadius: BorderRadius.circular(12),
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
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  '✓ Done',
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: 12,
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
                  color: AppColors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  car,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.location_on,
                  color: AppColors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  location,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.check_circle,
                        color: AppColors.white, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      completedTime,
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 12,
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
                      style: const TextStyle(
                        color: AppColors.gold,
                        fontSize: 14,
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
