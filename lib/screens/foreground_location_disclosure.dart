import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../utils/responsive_utils.dart';

class ForegroundLocationDisclosure extends StatelessWidget {
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  const ForegroundLocationDisclosure({
    super.key,
    required this.onAccept,
    required this.onDecline,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ResponsiveUtils.r(context, 16)),
      ),
      backgroundColor: AppColors.white,
      child: Padding(
        padding: EdgeInsets.all(ResponsiveUtils.w(context, 24)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.location_on,
              size: ResponsiveUtils.r(context, 48),
              color: AppColors.primaryTeal,
            ),
            ResponsiveUtils.verticalSpace(context, 16),
            Text(
              'Location Access Required',
              style: TextStyle(
                fontSize: ResponsiveUtils.sp(context, 20),
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
              textAlign: TextAlign.center,
            ),
            ResponsiveUtils.verticalSpace(context, 16),
            Text(
              'DuneShine collects location data to enable job routing, verify arrivals, and let the dispatch team monitor on-shift partners while you are using the app.',
              style: TextStyle(
                fontSize: ResponsiveUtils.sp(context, 14),
                color: AppColors.textGray,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            ResponsiveUtils.verticalSpace(context, 8),
            Text(
              'Location tracking stops the moment your shift ends.',
              style: TextStyle(
                fontSize: ResponsiveUtils.sp(context, 14),
                color: AppColors.textGray,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            ResponsiveUtils.verticalSpace(context, 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onDecline,
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        vertical: ResponsiveUtils.h(context, 12),
                      ),
                      side: const BorderSide(color: AppColors.lightGray),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          ResponsiveUtils.r(context, 8),
                        ),
                      ),
                    ),
                    child: Text(
                      'Not Now',
                      style: TextStyle(
                        color: AppColors.textGray,
                        fontSize: ResponsiveUtils.sp(context, 16),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                ResponsiveUtils.horizontalSpace(context, 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onAccept,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryTeal,
                      padding: EdgeInsets.symmetric(
                        vertical: ResponsiveUtils.h(context, 12),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          ResponsiveUtils.r(context, 8),
                        ),
                      ),
                    ),
                    child: Text(
                      'Allow',
                      style: TextStyle(
                        color: AppColors.white,
                        fontSize: ResponsiveUtils.sp(context, 16),
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
