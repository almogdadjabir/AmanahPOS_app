import 'package:flutter/widgets.dart';
import 'breakpoints.dart';

extension ResponsiveContext on BuildContext {
  double get _width => MediaQuery.sizeOf(this).width;

  DeviceClass get deviceClass {
    final w = _width;
    if (w >= Breakpoints.desktop) return DeviceClass.desktop;
    if (w >= Breakpoints.tablet)  return DeviceClass.tablet;
    return DeviceClass.mobile;
  }

  bool get isMobile  => deviceClass == DeviceClass.mobile;
  bool get isTablet  => deviceClass == DeviceClass.tablet;
  bool get isDesktop => deviceClass == DeviceClass.desktop;
  bool get isWide    => _width >= Breakpoints.tablet;

  T responsive<T>({required T mobile, T? tablet, required T desktop}) =>
      switch (deviceClass) {
        DeviceClass.desktop => desktop,
        DeviceClass.tablet  => tablet ?? desktop,
        DeviceClass.mobile  => mobile,
      };
}
