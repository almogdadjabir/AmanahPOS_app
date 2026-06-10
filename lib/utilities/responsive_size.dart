import 'package:flutter/material.dart';

class ResponsiveSize {
  // iPhone 16 Pro - 656
  static const double mobileWidth = 402.0;
  static const double mobileHeight = 874.0;

  static const double tabletWidth = 768.0;
  static const double tabletHeight = 1024.0;

  static bool _isTablet(BuildContext context) {
    return MediaQuery.sizeOf(context).width > 600;
  }

  static double _getBaseDimension(BuildContext context, bool isHeight) {
    if (_isTablet(context)) {
      return MediaQuery.orientationOf(context) == Orientation.portrait
          ? (isHeight ? tabletHeight : tabletWidth)
          : (isHeight ? tabletWidth : tabletHeight);
    } else {
      return isHeight ? mobileHeight : mobileWidth;
    }
  }

  static double getResponsiveSize(BuildContext context, double baseSize) {
    final double screenHeight = MediaQuery.sizeOf(context).height;
    final double baseHeight = _getBaseDimension(context, true);

    // Scale based on height
    return baseSize * (screenHeight / baseHeight);
  }

  static double getResponsiveWidth(BuildContext context, double baseSize) {
    final double screenWidth = MediaQuery.sizeOf(context).width;
    final double baseWidth = _getBaseDimension(context, false);

    // Scale based on width
    return baseSize * (screenWidth / baseWidth);
  }

  static double getResponsiveFontSize(
      BuildContext context,
      double baseFontSize,
      ) {
    final double screenWidth = MediaQuery.sizeOf(context).width;
    final double baseWidth = _getBaseDimension(context, false);

    double scaleFactor = screenWidth / baseWidth;

    // On desktop screens, cap scaling so fonts stay at their intended design size.
    // Without this, a 1440px screen would scale fonts to ~1.875x the base size.
    if (screenWidth >= 1024) {
      scaleFactor = scaleFactor.clamp(0.0, 1.0);
    }

    return baseFontSize * scaleFactor;
  }
}