import 'package:flutter/material.dart';

/// Responsive utilities for scaling dimensions and fonts across different
/// screen sizes and accessibility settings.
/// 
/// Design base: iPhone 13/14 (375 x 812 logical pixels)
class ResponsiveUtils {
  static const double _designWidth = 375.0;
  static const double _designHeight = 812.0;

  /// Width-based scaling for horizontal elements
  static double w(BuildContext context, double size) {
    return size * MediaQuery.sizeOf(context).width / _designWidth;
  }

  /// Height-based scaling for vertical elements
  static double h(BuildContext context, double size) {
    return size * MediaQuery.sizeOf(context).height / _designHeight;
  }

  /// Font scaling that RESPECTS device accessibility text size settings.
  static double sp(BuildContext context, double size) {
    final double widthScale = MediaQuery.sizeOf(context).width / _designWidth;
    final double textScale = MediaQuery.textScalerOf(context).scale(1.0);
    final double clampedTextScale = textScale.clamp(0.85, 1.25);
    return size * widthScale * clampedTextScale;
  }

  /// Radius scaling
  static double r(BuildContext context, double size) {
    final double widthScale = MediaQuery.sizeOf(context).width / _designWidth;
    final double heightScale = MediaQuery.sizeOf(context).height / _designHeight;
    return size * (widthScale + heightScale) / 2;
  }

  /// Get screen width
  static double screenWidth(BuildContext context) {
    return MediaQuery.sizeOf(context).width;
  }

  /// Get screen height
  static double screenHeight(BuildContext context) {
    return MediaQuery.sizeOf(context).height;
  }

  /// Vertical space helper
  static Widget verticalSpace(BuildContext context, double height) {
    return SizedBox(height: h(context, height));
  }

  /// Horizontal space helper
  static Widget horizontalSpace(BuildContext context, double width) {
    return SizedBox(width: w(context, width));
  }

  /// Check if device is a small phone
  static bool isSmallPhone(BuildContext context) {
    return MediaQuery.sizeOf(context).width < 360;
  }

  /// Check if device is a large phone/tablet
  static bool isLargeDevice(BuildContext context) {
    return MediaQuery.sizeOf(context).width > 414;
  }
}
