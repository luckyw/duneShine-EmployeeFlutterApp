import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../utils/responsive_utils.dart';
import '../utils/toast_utils.dart';


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

  // Current month info (today)
  late int _currentYear;
  late int _currentMonth;
  
  // Displayed month info (navigation)
  late int _displayYear;
  late int _displayMonth;
  late int _daysInMonth;
  late String _monthName;


  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _currentYear = now.year;
    _currentMonth = now.month;
    
    // Initialize display date to current date
    _displayYear = _currentYear;
    _displayMonth = _currentMonth;
    
    _updateMonthInfo();
    _fetchAvailability();
  }

  void _updateMonthInfo() {
    _daysInMonth = DateTime(_displayYear, _displayMonth + 1, 0).day;
    _monthName = _getMonthName(_displayMonth);
  }

  void _changeMonth(int offset) {
    setState(() {
      _displayMonth += offset;
      if (_displayMonth > 12) {
        _displayMonth = 1;
        _displayYear++;
      } else if (_displayMonth < 1) {
        _displayMonth = 12;
        _displayYear--;
      }
      
      // Reset selected date if it exceeds days in new month
      _updateMonthInfo();
      if (_selectedDate > _daysInMonth) {
        _selectedDate = 1;
      }
      
      _isFetchingDates = true;
    });
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
          if (localDate.year == _displayYear && localDate.month == _displayMonth) {
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
    final date = DateTime(_displayYear, _displayMonth, day);
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
    if (isError) {
      ToastUtils.showErrorToast(context, message);
    } else {
      ToastUtils.showSuccessToast(context, message);
    }
  }


  @override
  Widget build(BuildContext context) {
    if (_isFetchingDates) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(ResponsiveUtils.w(context, 48)),
          child: const CircularProgressIndicator(),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchAvailability,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: EdgeInsets.all(ResponsiveUtils.w(context, 24)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios, size: 20),
                    onPressed: () => _changeMonth(-1),
                    color: AppColors.primaryTeal,
                  ),
                  Text(
                    '$_monthName $_displayYear',
                    style: TextStyle(
                      fontSize: ResponsiveUtils.sp(context, 24),
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkNavy,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.arrow_forward_ios, size: 20),
                    onPressed: () => _changeMonth(1),
                    color: AppColors.primaryTeal,
                  ),
                ],
              ),

              ResponsiveUtils.verticalSpace(context, 24),
              GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                crossAxisSpacing: ResponsiveUtils.w(context, 8),
                mainAxisSpacing: ResponsiveUtils.h(context, 8),
              ),
              itemCount: _daysInMonth,
              itemBuilder: (context, index) {
                int day = index + 1;
                bool isAvailable = _availableDates.contains(day);
                bool isSelected = day == _selectedDate;
                
                // Compare with Today for "past" logic
                final dateToCheck = DateTime(_displayYear, _displayMonth, day);
                final now = DateTime.now();
                final today = DateTime(now.year, now.month, now.day);
                
                // Make past dates unselectable
                bool isPast = dateToCheck.isBefore(today);


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
                              width: ResponsiveUtils.w(context, 3),
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
              ResponsiveUtils.verticalSpace(context, 32),
              Text(
                'Selected Date: $_monthName $_selectedDate, $_displayYear',

                style: TextStyle(
                  fontSize: ResponsiveUtils.sp(context, 16),
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
                  fontSize: ResponsiveUtils.sp(context, 14),
                  color: _availableDates.contains(_selectedDate)
                      ? AppColors.primaryTeal
                      : AppColors.textGray,
                ),
              ),
              ResponsiveUtils.verticalSpace(context, 24),
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
                            borderRadius: BorderRadius.circular(ResponsiveUtils.r(context, 12)),
                          ),
                          padding: EdgeInsets.symmetric(vertical: ResponsiveUtils.h(context, 16)),
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
                    ResponsiveUtils.horizontalSpace(context, 12),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _setAvailability(false),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(
                            color: AppColors.primaryTeal,
                            width: 2,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(ResponsiveUtils.r(context, 12)),
                          ),
                          padding: EdgeInsets.symmetric(vertical: ResponsiveUtils.h(context, 16)),
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
              ResponsiveUtils.verticalSpace(context, 32),
              // Legend
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildLegendItem(AppColors.primaryTeal, 'Available'),
                  ResponsiveUtils.horizontalSpace(context, 24),
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
        ResponsiveUtils.horizontalSpace(context, 8),
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