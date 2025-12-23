
import 'package:flutter/material.dart';

class ResponsiveUtils {
  static double sp(BuildContext context, double size) {
    // Simple scaling based on width, can be improved with ScreenUtil-like logic if needed
    double scaleFactor = MediaQuery.of(context).size.width / 375.0;
    return size * scaleFactor;
  }
}
