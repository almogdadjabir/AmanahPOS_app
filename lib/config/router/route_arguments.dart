/// Navigation argument keys used across the application
/// Centralizes all route argument keys to prevent typos and enable refactoring
class RouteArguments {
  RouteArguments._();

  // PIN Generation Screen
  static const String pinType = 'pinType';
  static const String onGeneratePin = 'onGeneratePin';

  // OTP Screen
  static const String title = 'title';
  static const String phoneNumber = 'phoneNumber';
  static const String isEmail = 'isEmail';
  static const String otpType = 'oTPType';
  static const String onVerified = 'onVerified';
  static const String onUnMask = 'onUnMask';
  static const String onBackPressed = 'onBackPressed';
  static const String payload = 'payload';

  // Master Verify Screen
  static const String withDifferentWay = 'withDifferentWay';
  static const String withAuthentication = 'withAuthentication';

  // Common
  static const String isProceed = 'isProceed';
  static const String isRegistered = 'isRegistered';
  static const String identityClaim = 'identityClaim';
}
