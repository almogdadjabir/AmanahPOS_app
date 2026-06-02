// lib/core/responsive/breakpoints.dart
abstract final class Breakpoints {
  Breakpoints._();

  static const double tablet  = 600;
  static const double desktop = 1024;
  static const double large   = 1440;
}

enum DeviceClass { mobile, tablet, desktop }
