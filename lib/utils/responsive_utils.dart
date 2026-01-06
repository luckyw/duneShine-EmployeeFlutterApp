import 'package:flutter/material.dart';

/// Responsive utilities for scaling dimensions and fonts across different
/// screen sizes and accessibility settings.
/// 
/// Design base: iPhone 13/14 (375 x 812 logical pixels)
class ResponsiveUtils {
  static const double _designWidth = 375.0;
  static const double _designHeight = 812.0;

  /// Width-based scaling for horizontal elements (padding, margins, widths)
  static double w(BuildContext context, double size) {
    return size * MediaQuery.of(context).size.width / _designWidth;
  }

  /// Height-based scaling for vertical elements (spacing, heights)
  static double h(BuildContext context, double size) {
    return size * MediaQuery.of(context).size.height / _designHeight;
  }

  /// Font scaling that RESPECTS device accessibility text size settings.
  /// Clamped between 0.85 and 1.25 to prevent extreme overflow on large text settings.
  static double sp(BuildContext context, double size) {
    final double widthScale = MediaQuery.of(context).size.width / _designWidth;
    final double textScale = MediaQuery.textScalerOf(context).scale(1.0);
    // Clamp text scale to prevent extreme overflow while still respecting accessibility
    final double clampedTextScale = textScale.clamp(0.85, 1.25);
    return size * widthScale * clampedTextScale;
  }

  /// Radius scaling (average of width/height for balanced corners)
  static double r(BuildContext context, double size) {
    final double avgScale = (MediaQuery.of(context).size.width / _designWidth +
            MediaQuery.of(context).size.height / _designHeight) /
        2;
    return size * avgScale;
  }

  /// Get screen width
  static double screenWidth(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }

  /// Get screen height
  static double screenHeight(BuildContext context) {
    return MediaQuery.of(context).size.height;
  }

  /// Check if device is a small phone (width < 360)
  static bool isSmallPhone(BuildContext context) {
    return MediaQuery.of(context).size.width < 360;
  }

  /// Check if device is a large phone/tablet (width > 414)
  static bool isLargeDevice(BuildContext context) {
    return MediaQuery.of(context).size.width > 414;
  }
}
