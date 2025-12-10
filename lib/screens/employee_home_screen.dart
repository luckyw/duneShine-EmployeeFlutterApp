import 'package:flutter/material.dart';
import '../constants/colors.dart';

class EmployeeHomeScreen extends StatefulWidget {
  const EmployeeHomeScreen({Key? key}) : super(key: key);

  @override
  State<EmployeeHomeScreen> createState() => _EmployeeHomeScreenState();
}

class _EmployeeHomeScreenState extends State<EmployeeHomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _currentIndex = 0;

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
      appBar: AppBar(
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
      ),
      body: SingleChildScrollView(
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
                labelColor: AppColors.white,
                unselectedLabelColor: AppColors.darkNavy,
                tabs: const [
                  Tab(text: 'Upcoming'),
                  Tab(text: 'Completed'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Padding(
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
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
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

  Widget _buildBottomNav() {
    return BottomNavigationBar(
      currentIndex: _currentIndex,
      onTap: (index) {
        setState(() {
          _currentIndex = index;
        });
        if (index == 1) {
          Navigator.pushNamed(context, '/availability');
        } else if (index == 2) {
          Navigator.pushNamed(context, '/employee-account');
        }
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
