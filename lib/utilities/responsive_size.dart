import 'package:amana_pos/config/constants.dart';
import 'package:flutter/material.dart';

class ResponsiveSize {
  // iPhone 16 Pro - 656
  static const double mobileWidth = 402.0;
  static const double mobileHeight = 874.0;

  static const double tabletWidth = 768.0;
  static const double tabletHeight = 1024.0;

  static double _getBaseDimension(BuildContext context, bool isHeight) {
    if (Constants.isTablet) {
      return MediaQuery.orientationOf(context) == Orientation.portrait
          ? (isHeight ? tabletHeight : tabletWidth)
          : (isHeight ? tabletWidth : tabletHeight);
    } else {
      return isHeight ? mobileHeight : mobileWidth;
    }
  }

  static double _getBaseHeight(BuildContext context) {
    Constants.isTablet = _isTablet(context);
    return _getBaseDimension(context, true);
  }

  static double _getBaseWidth(BuildContext context) {
    return _getBaseDimension(context, false);
  }

  static double getResponsiveSize(BuildContext context, double baseSize) {
    final double screenHeight = MediaQuery.sizeOf(context).height;
    final double baseHeight = _getBaseHeight(context);

    // Scale based on height
    return baseSize * (screenHeight / baseHeight);
  }

  static double getResponsiveWidth(BuildContext context, double baseSize) {
    final double screenWidth = MediaQuery.sizeOf(context).width;
    final double baseWidth = _getBaseWidth(context);

    // Scale based on width
    return baseSize * (screenWidth / baseWidth);
  }

  static double getResponsiveFontSize(
      BuildContext context,
      double baseFontSize,
      ) {
    final double screenWidth = MediaQuery.sizeOf(context).width;
    final double baseWidth = _getBaseWidth(context);

    // Scale font based on width (more consistent than diagonal)
    final double scaleFactor = screenWidth / baseWidth;

    // Apply scaling
    return baseFontSize * scaleFactor;
  }


  static bool _isTablet(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return width > 600;
  }
}