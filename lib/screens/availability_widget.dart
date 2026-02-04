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
    final now = DateTime.now();
    final bool wasCurrentMonth =
        _displayYear == now.year && _displayMonth == now.month;

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

    // Fetch availability if we're back to the current month
    final bool isNowCurrentMonth =
        _displayYear == now.year && _displayMonth == now.month;
    if (isNowCurrentMonth && !wasCurrentMonth) {
      _fetchAvailability();
    }
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
      final availabilities =
          result['data']['availabilities'] as List<dynamic>? ?? [];
      final Set<int> availableDays = {};

      for (var availability in availabilities) {
        final dateString = availability['available_date'] as String?;
        final isAvailable = availability['is_available'] == true;

        if (dateString != null && isAvailable) {
          // Parse UTC date and convert to local timezone
          final utcDate = DateTime.parse(dateString);
          final localDate = utcDate.toLocal();
          // Only add dates from current month
          if (localDate.year == _displayYear &&
              localDate.month == _displayMonth) {
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
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
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
          isError: false,
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
      _showSnackBar(
        result['message'] ?? 'Failed to update availability',
        isError: true,
      );
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
          padding: EdgeInsets.all(ResponsiveUtils.w(context, 20)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Premium Header
              Container(
                padding: EdgeInsets.symmetric(
                  vertical: ResponsiveUtils.h(context, 16),
                  horizontal: ResponsiveUtils.w(context, 16),
                ),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(ResponsiveUtils.r(context, 20)),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.darkNavy.withOpacity(0.05),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildNavButton(
                      icon: Icons.arrow_back_ios_new_rounded,
                      onTap: () => _changeMonth(-1),
                    ),
                    Column(
                      children: [
                        Text(
                          _monthName,
                          style: TextStyle(
                            fontSize: ResponsiveUtils.sp(context, 20),
                            fontWeight: FontWeight.w800,
                            color: AppColors.darkNavy,
                            letterSpacing: 0.5,
                          ),
                        ),
                        Text(
                          _displayYear.toString(),
                          style: TextStyle(
                            fontSize: ResponsiveUtils.sp(context, 14),
                            fontWeight: FontWeight.w500,
                            color: AppColors.textGray.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                    _buildNavButton(
                      icon: Icons.arrow_forward_ios_rounded,
                      onTap: () => _changeMonth(1),
                    ),
                  ],
                ),
              ),

              ResponsiveUtils.verticalSpace(context, 24),

              // Calendar Body
              Container(
                padding: EdgeInsets.all(ResponsiveUtils.w(context, 16)),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(ResponsiveUtils.r(context, 24)),
                  border: Border.all(
                    color: AppColors.lightGray.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  children: [
                    // Days of week header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN']
                          .map(
                            (day) => Expanded(
                              child: Center(
                                child: Text(
                                  day,
                                  style: TextStyle(
                                    fontSize: ResponsiveUtils.sp(context, 10),
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textGray.withOpacity(0.5),
                                    letterSpacing: 1,
                                  ),
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                    ResponsiveUtils.verticalSpace(context, 16),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 7,
                        crossAxisSpacing: ResponsiveUtils.w(context, 8),
                        mainAxisSpacing: ResponsiveUtils.h(context, 8),
                      ),
                      itemCount: _daysInMonth +
                          (DateTime(_displayYear, _displayMonth, 1).weekday - 1),
                      itemBuilder: (context, index) {
                        final int firstDayOffset =
                            DateTime(_displayYear, _displayMonth, 1).weekday - 1;

                        if (index < firstDayOffset) {
                          return const SizedBox.shrink(); 
                        }

                        int day = index - firstDayOffset + 1;

                        // Logic checks
                        final now = DateTime.now();
                        bool isCurrentMonth =
                            _displayYear == now.year && _displayMonth == now.month;
                        bool isToday = isCurrentMonth && day == now.day;
                        bool isInteractable = true; // Allow selecting any date for planning

                        bool isAvailable =
                            isCurrentMonth && _availableDates.contains(day);
                        bool isSelected = _selectedDates.contains(day);

                        return _buildDateCell(
                          day: day,
                          isAvailable: isAvailable,
                          isSelected: isSelected,
                          isToday: isToday,
                          onTap: () {
                            setState(() {
                              if (_selectedDates.contains(day)) {
                                _selectedDates.remove(day);
                              } else {
                                _selectedDates.add(day);
                              }
                            });
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),

              ResponsiveUtils.verticalSpace(context, 24),

              // Action Bar
              if (_isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(color: AppColors.primaryTeal),
                  ),
                )
              else ...[
                // Dynamic Status Text
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _selectedDates.isNotEmpty
                      ? Container(
                          key: ValueKey('selected'),
                          margin: EdgeInsets.only(bottom: ResponsiveUtils.h(context, 16)),
                          padding: EdgeInsets.symmetric(
                            horizontal: ResponsiveUtils.w(context, 16),
                            vertical: ResponsiveUtils.h(context, 8),
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryTeal.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${_selectedDates.length} days selected',
                            style: TextStyle(
                              color: AppColors.primaryTeal,
                              fontWeight: FontWeight.bold,
                              fontSize: ResponsiveUtils.sp(context, 14),
                            ),
                          ),
                        )
                      : const SizedBox(height: 0),
                ),

                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _selectedDates.isEmpty
                            ? null
                            : () => _processAvailabilityUpdate(true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryTeal,
                          disabledBackgroundColor: AppColors.lightGray.withOpacity(0.3),
                          elevation: _selectedDates.isEmpty ? 0 : 4,
                          shadowColor: AppColors.primaryTeal.withOpacity(0.4),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              ResponsiveUtils.r(context, 16),
                            ),
                          ),
                          padding: EdgeInsets.symmetric(
                            vertical: ResponsiveUtils.h(context, 16),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                             const Icon(Icons.check_circle_outline, size: 20),
                             const SizedBox(width: 8),
                             Text(
                              'Available',
                              style: TextStyle(
                                fontSize: ResponsiveUtils.sp(context, 16),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    ResponsiveUtils.horizontalSpace(context, 12),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _selectedDates.isEmpty
                            ? null
                            : () => _processAvailabilityUpdate(false),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: _selectedDates.isEmpty
                                ? AppColors.lightGray.withOpacity(0.3)
                                : AppColors.error.withOpacity(0.5),
                            width: 1.5,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              ResponsiveUtils.r(context, 16),
                            ),
                          ),
                          padding: EdgeInsets.symmetric(
                            vertical: ResponsiveUtils.h(context, 16),
                          ),
                        ),
                        child: Text(
                          'Unavailable',
                          style: TextStyle(
                            color: _selectedDates.isEmpty
                                ? AppColors.lightGray
                                : AppColors.error,
                            fontWeight: FontWeight.bold,
                            fontSize: ResponsiveUtils.sp(context, 16),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],

              ResponsiveUtils.verticalSpace(context, 40),

              // Modern Legend
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: ResponsiveUtils.w(context, 24),
                  vertical: ResponsiveUtils.h(context, 16),
                ),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(60),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildLegendItem(AppColors.primaryTeal, 'Available'),
                    ResponsiveUtils.horizontalSpace(context, 24),
                    _buildLegendItem(AppColors.lightGray.withOpacity(0.3), 'Empty'),
                    ResponsiveUtils.horizontalSpace(context, 24),
                    _buildLegendItem(AppColors.amber, 'Selected'),
                  ],
                ),
              ),
              ResponsiveUtils.verticalSpace(context, 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavButton({required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.veryLightGray,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          size: 18,
          color: AppColors.primaryTeal,
        ),
      ),
    );
  }

  Widget _buildDateCell({
    required int day,
    required bool isAvailable,
    required bool isSelected,
    required bool isToday,
    required VoidCallback onTap,
  }) {
    Color bgColor;
    Color textColor;
    Border? border;

    if (isSelected) {
      bgColor = AppColors.amber.withOpacity(0.15);
      textColor = AppColors.darkNavy;
      border = Border.all(color: AppColors.amber, width: 2);
    } else if (isAvailable) {
      bgColor = AppColors.primaryTeal;
      textColor = AppColors.white;
      border = null;
    } else {
      bgColor = Colors.transparent;
      textColor = AppColors.darkNavy;
      border = null;
    }

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: bgColor,
          shape: BoxShape.circle,
          border: border,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Text(
              day.toString(),
              style: TextStyle(
                color: textColor,
                fontWeight: isToday || isSelected || isAvailable
                    ? FontWeight.bold
                    : FontWeight.normal,
                fontSize: ResponsiveUtils.sp(context, 14),
              ),
            ),
            if (isToday)
              Positioned(
                bottom: 6,
                child: Container(
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isAvailable ? AppColors.white : AppColors.primaryTeal,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: label == 'Selected' ? Border.all(color: AppColors.amber, width: 2) : (label == 'Empty' ? Border.all(color: AppColors.lightGray, width: 1) : null),
          ),
          // For 'Selected' legend, show the border style
          child: label == 'Selected' ? null : null, 
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textGray,
          ),
        ),
      ],
    );
  }
}
