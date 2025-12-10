import 'package:flutter/material.dart';
import '../constants/colors.dart';

class AvailabilityWidget extends StatelessWidget {
  final Set<int> availableDates;
  final int selectedDate;
  final void Function(int) onDateSelected;
  final void Function() onSetAvailable;
  final void Function() onSetUnavailable;

  const AvailabilityWidget({
    super.key,
    required this.availableDates,
    required this.selectedDate,
    required this.onDateSelected,
    required this.onSetAvailable,
    required this.onSetUnavailable,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'December 2025',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.darkNavy,
              ),
            ),
            const SizedBox(height: 24),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: 31,
              itemBuilder: (context, index) {
                int day = index + 1;
                bool isAvailable = availableDates.contains(day);
                bool isSelected = day == selectedDate;

                return GestureDetector(
                  onTap: () => onDateSelected(day),
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isAvailable
                          ? AppColors.primaryTeal
                          : AppColors.lightGray,
                      border: isSelected
                          ? Border.all(
                              color: const Color(0xFFFFC107),
                              width: 3,
                            )
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        day.toString(),
                        style: TextStyle(
                          color: AppColors.white,
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
              'Selected Date: December $selectedDate',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.darkNavy,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      onSetAvailable();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Marked as available')),
                      );
                    },
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
                    onPressed: () {
                      onSetUnavailable();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Marked as unavailable')),
                      );
                    },
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
          ],
        ),
      ),
    );
  }
}