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
  Set<int> _selectedDates = {}; // Changed to Set for multi-select
  bool _isLoading = false;

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
      
      _updateMonthInfo();
      _selectedDates.clear(); // Clear selection on month change
      _availableDates.clear(); // Clear availability data for new month
    });
    // No need to fetch availability for other months since only today is interactable
  }


  Future<void> _fetchAvailability() async {
    final token = _authService.token;
    if (token == null) {
      setState(() {
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

      if (!mounted) return;
      setState(() {
        _availableDates = availableDays;
        _isLoading = false;
      });
    } else {
      if (!mounted) return;
      setState(() {
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


  Future<void> _processAvailabilityUpdate(bool makeAvailable) async {
    final token = _authService.token;
    if (token == null) {
      _showSnackBar('Not authenticated. Please login again.', isError: true);
      return;
    }

    if (_selectedDates.isEmpty) {
      _showSnackBar('Please select at least one date', isError: true);
      return;
    }

    // Filter dates to avoid redundant API calls
    // If making available: only include dates that are NOT currently available
    // If making unavailable: only include dates that ARE currently available
    final List<String> datesToUpdate = [];
    int ignoredCount = 0;

    for (final day in _selectedDates) {
      final isCurrentlyAvailable = _availableDates.contains(day);
      
      if (makeAvailable && !isCurrentlyAvailable) {
        datesToUpdate.add(_formatDateForApi(day));
      } else if (!makeAvailable && isCurrentlyAvailable) {
        datesToUpdate.add(_formatDateForApi(day));
      } else {
        ignoredCount++;
      }
    }

    if (datesToUpdate.isEmpty) {
      if (ignoredCount > 0) {
        _showSnackBar(
          makeAvailable 
            ? 'Selected dates are already available' 
            : 'Selected dates are already unavailable', 
          isError: false
        );
      }
      return; // No API call needed
    }

    setState(() => _isLoading = true);

    final result = await _apiService.setAvailability(
      token: token,
      availableDates: datesToUpdate,
      isAvailable: makeAvailable,
    );

    if (!mounted) return;
    if (result['success'] == true) {
      _showSnackBar(
        makeAvailable 
          ? 'Marked ${datesToUpdate.length} days as available' 
          : 'Marked ${datesToUpdate.length} days as unavailable',
        isError: false,
      );
      
      // Clear selection after successful update
      setState(() {
        _selectedDates.clear();
      });
      
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
              


              ResponsiveUtils.verticalSpace(context, 12),
              
              // Days of week header
              Padding(
                padding: EdgeInsets.symmetric(vertical: ResponsiveUtils.h(context, 8)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: ['M', 'T', 'W', 'T', 'F', 'S', 'S'].map((day) => Expanded(
                    child: Center(
                      child: Text(
                        day,
                        style: TextStyle(
                          fontSize: ResponsiveUtils.sp(context, 14),
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryTeal.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                  )).toList(),
                ),
              ),

              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  crossAxisSpacing: ResponsiveUtils.w(context, 8),
                  mainAxisSpacing: ResponsiveUtils.h(context, 8),
                ),
                itemCount: _daysInMonth + (DateTime(_displayYear, _displayMonth, 1).weekday - 1),
                itemBuilder: (context, index) {
                  final int firstDayOffset = DateTime(_displayYear, _displayMonth, 1).weekday - 1;
                  
                  if (index < firstDayOffset) {
                    return const SizedBox.shrink(); // Empty space for previous month days
                  }

                  int day = index - firstDayOffset + 1;
                bool isAvailable = _availableDates.contains(day);
                bool isSelected = _selectedDates.contains(day);
                
                // Only actual today's date is interactable
                final now = DateTime.now();
                bool isToday = _displayYear == now.year && 
                               _displayMonth == now.month && 
                               day == now.day;
                
                bool isInteractable = isToday;

                return GestureDetector(
                  onTap: !isInteractable ? null : () {
                    setState(() {
                      if (_selectedDates.contains(day)) {
                        _selectedDates.remove(day);
                      } else {
                        _selectedDates.add(day);
                      }
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isInteractable
                          ? (isAvailable 
                              ? AppColors.primaryTeal 
                              : AppColors.lightGray.withValues(alpha: 0.3))
                          : isAvailable
                              ? AppColors.primaryTeal.withValues(alpha: 0.5)
                              : AppColors.lightGray.withValues(alpha: 0.1),
                      border: isInteractable
                          ? Border.all(
                              color: isSelected ? AppColors.amber : AppColors.primaryTeal.withValues(alpha: 0.5),
                              width: ResponsiveUtils.w(context, 2),
                            )
                          : isSelected
                              ? Border.all(
                                  color: AppColors.amber,
                                  width: ResponsiveUtils.w(context, 3),
                                )
                              : null,
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Text(
                          day.toString(),
                          style: TextStyle(
                            color: isInteractable
                                ? (isAvailable ? AppColors.white : AppColors.darkNavy)
                                : isAvailable 
                                    ? AppColors.white.withValues(alpha: 0.7) 
                                    : AppColors.darkNavy.withValues(alpha: 0.4),
                            fontSize: 14,
                            fontWeight: isInteractable ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        if (isSelected)
                           Positioned(
                             bottom: 4,
                             child: Icon(Icons.check, size: 10, color: isAvailable ? AppColors.white : AppColors.darkNavy),
                           )
                      ],
                    ),
                  ),
                );
              },
            ),
              ResponsiveUtils.verticalSpace(context, 32),
              Text(
                _selectedDates.isEmpty 
                  ? 'Select dates to update status' 
                  : '${_selectedDates.length} days selected',
                style: TextStyle(
                  fontSize: ResponsiveUtils.sp(context, 16),
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkNavy,
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
                        onPressed: _selectedDates.isEmpty ? null : () => _processAvailabilityUpdate(true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryTeal,
                          disabledBackgroundColor: AppColors.lightGray,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(ResponsiveUtils.r(context, 12)),
                          ),
                          padding: EdgeInsets.symmetric(vertical: ResponsiveUtils.h(context, 16)),
                        ),
                        child: const Text(
                          'Mark Available',
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
                        onPressed: _selectedDates.isEmpty ? null : () => _processAvailabilityUpdate(false),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: _selectedDates.isEmpty ? AppColors.lightGray : AppColors.primaryTeal,
                            width: 2,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(ResponsiveUtils.r(context, 12)),
                          ),
                          padding: EdgeInsets.symmetric(vertical: ResponsiveUtils.h(context, 16)),
                        ),
                        child: Text(
                          'Mark Unavailable',
                          style: TextStyle(
                            color: _selectedDates.isEmpty ? AppColors.lightGray : AppColors.primaryTeal,
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
                  ResponsiveUtils.horizontalSpace(context, 16),
                  _buildLegendItem(AppColors.lightGray.withOpacity(0.3), 'Not Set'),
                  ResponsiveUtils.horizontalSpace(context, 16),
                  Row(
                    children: [
                      Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.amber, width: 2),
                        ),
                      ),
                      ResponsiveUtils.horizontalSpace(context, 8),
                      const Text(
                        'Selected',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textGray,
                        ),
                      ),
                    ],
                  ),
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