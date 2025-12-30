import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

class AvailabilityWidget extends StatefulWidget {
  const AvailabilityWidget({super.key});

  @override
  State<AvailabilityWidget> createState() => _AvailabilityWidgetState();
}

class _AvailabilityWidgetState extends State<AvailabilityWidget> {
  final ApiService _apiService = ApiService();
  final AuthService _authService = AuthService();

  Set<int> _availableDates = {};
  int _selectedDate = DateTime.now().day;
  bool _isLoading = false;
  bool _isFetchingDates = true;

  // Current month info
  late int _currentYear;
  late int _currentMonth;
  late int _daysInMonth;
  late String _monthName;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _currentYear = now.year;
    _currentMonth = now.month;
    _daysInMonth = DateTime(_currentYear, _currentMonth + 1, 0).day;
    _monthName = _getMonthName(_currentMonth);
    _fetchAvailability();
  }

  Future<void> _fetchAvailability() async {
    final token = _authService.token;
    if (token == null) {
      setState(() {
        _isFetchingDates = false;
        _isLoading = false;
      });
      return;
    }

    final result = await _apiService.getAvailability(token: token);

    if (result['success'] == true && mounted) {
      final availabilities = result['data']['availabilities'] as List<dynamic>? ?? [];
      final Set<int> availableDays = {};

      for (var availability in availabilities) {
        final dateString = availability['available_date'] as String?;
        final isAvailable = availability['is_available'] == true;
        
        if (dateString != null && isAvailable) {
          // Parse UTC date and convert to local timezone
          final utcDate = DateTime.parse(dateString);
          final localDate = utcDate.toLocal();
          // Only add dates from current month
          if (localDate.year == _currentYear && localDate.month == _currentMonth) {
            availableDays.add(localDate.day);
          }
        }
      }

      setState(() {
        _availableDates = availableDays;
        _isFetchingDates = false;
        _isLoading = false;
      });
    } else {
      setState(() {
        _isFetchingDates = false;
        _isLoading = false;
      });
    }
  }

  String _getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }

  String _formatDateForApi(int day) {
    final date = DateTime(_currentYear, _currentMonth, day);
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Future<void> _setAvailability(bool isAvailable) async {
    final token = _authService.token;
    if (token == null) {
      _showSnackBar('Not authenticated. Please login again.', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    final dateString = _formatDateForApi(_selectedDate);
    
    final result = await _apiService.setAvailability(
      token: token,
      availableDates: [dateString],
      isAvailable: isAvailable,
    );

    if (result['success'] == true) {
      _showSnackBar(
        isAvailable ? 'Marked as available' : 'Marked as unavailable',
        isError: false,
      );
      // Refetch all availability dates from the API
      await _fetchAvailability();
    } else {
      setState(() => _isLoading = false);
      _showSnackBar(result['message'] ?? 'Failed to update availability', isError: true);
    }
  }

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : AppColors.primaryTeal,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isFetchingDates) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(48),
          child: CircularProgressIndicator(),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchAvailability,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$_monthName $_currentYear',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkNavy,
                ),
              ),
              const SizedBox(height: 24),
              GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: _daysInMonth,
              itemBuilder: (context, index) {
                int day = index + 1;
                bool isAvailable = _availableDates.contains(day);
                bool isSelected = day == _selectedDate;
                bool isPast = DateTime(_currentYear, _currentMonth, day)
                    .isBefore(DateTime.now().subtract(const Duration(days: 1)));

                return GestureDetector(
                  onTap: isPast ? null : () => setState(() => _selectedDate = day),
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isPast
                          ? AppColors.lightGray.withValues(alpha: 0.5)
                          : isAvailable
                              ? AppColors.primaryTeal
                              : AppColors.lightGray,
                      border: isSelected
                          ? Border.all(
                              color: AppColors.amber,
                              width: 3,
                            )
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        day.toString(),
                        style: TextStyle(
                          color: isPast
                              ? AppColors.white.withValues(alpha: 0.5)
                              : AppColors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
              const SizedBox(height: 32),
              Text(
                'Selected Date: $_monthName $_selectedDate, $_currentYear',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkNavy,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _availableDates.contains(_selectedDate)
                    ? 'Status: Available ✓'
                    : 'Status: Not set',
                style: TextStyle(
                  fontSize: 14,
                  color: _availableDates.contains(_selectedDate)
                      ? AppColors.primaryTeal
                      : AppColors.textGray,
                ),
              ),
              const SizedBox(height: 24),
              if (_isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(),
                  ),
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _setAvailability(true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryTeal,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text(
                          'Set Available',
                          style: TextStyle(
                            color: AppColors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _setAvailability(false),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(
                            color: AppColors.primaryTeal,
                            width: 2,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text(
                          'Set Unavailable',
                          style: TextStyle(
                            color: AppColors.primaryTeal,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 32),
              // Legend
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildLegendItem(AppColors.primaryTeal, 'Available'),
                  const SizedBox(width: 24),
                  _buildLegendItem(AppColors.lightGray, 'Not Set'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textGray,
          ),
        ),
      ],
    );
  }
}