import 'package:amana_pos/config/enum.dart';
import 'package:flutter/cupertino.dart';

class Constants {
  static const cachedProfile = 'cachedProfile';
  static const authToken = 'auth_token';
  static const refreshToken = 'refresh_token';
  static const isDarkTheme = 'is_dark_theme';
  static const appTheme = 'app_theme';
  static const isBigFontSize = 'is_big_font_size';
  static bool isTablet = true;
  static const xTenantID = 'x_tenant_iD';

  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  static ScreenMode? currentSelectedMode = ScreenMode.light;


}
