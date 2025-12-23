
import 'package:flutter/material.dart';
import '../utils/responsive_utils.dart';
import 'colors.dart';

class AppTextStyles {
  // Headlines & Titles (Manrope)
  static TextStyle headline(BuildContext context) {
    return TextStyle(
      fontFamily: 'Manrope',
      fontSize: ResponsiveUtils.sp(context, 28),
      fontWeight: FontWeight.bold,
      color: AppColors.textDark,
    );
  }

  static TextStyle title(BuildContext context) {
    return TextStyle(
      fontFamily: 'Manrope',
      fontSize: ResponsiveUtils.sp(context, 22),
      fontWeight: FontWeight.bold,
      color: AppColors.textDark,
    );
  }

  // Body & Subtitles (Inter)
  static TextStyle subtitle(BuildContext context) {
    return TextStyle(
      fontFamily: 'Inter',
      fontSize: ResponsiveUtils.sp(context, 16),
      fontWeight: FontWeight.w600, // SemiBold
      color: AppColors.textDark,
    );
  }

  static TextStyle body(BuildContext context) {
    return TextStyle(
      fontFamily: 'Inter',
      fontSize: ResponsiveUtils.sp(context, 14),
      fontWeight: FontWeight.normal,
      color: AppColors.textDark,
    );
  }

  static TextStyle caption(BuildContext context) {
    return TextStyle(
      fontFamily: 'Inter',
      fontSize: ResponsiveUtils.sp(context, 12),
      fontWeight: FontWeight.normal,
      color: AppColors.textGray,
    );
  }

  // Specialized Uses (Manrope)
  static TextStyle price(BuildContext context) {
    return TextStyle(
      fontFamily: 'Manrope',
      fontSize: ResponsiveUtils.sp(context, 24),
      fontWeight: FontWeight.bold,
      color: AppColors.primaryTeal,
    );
  }

  static TextStyle button(BuildContext context) {
    return TextStyle(
      fontFamily: 'Manrope',
      fontSize: ResponsiveUtils.sp(context, 16),
      fontWeight: FontWeight.bold,
      color: AppColors.white,
    );
  }
}
