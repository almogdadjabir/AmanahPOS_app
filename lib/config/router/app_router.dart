import 'dart:io' show Platform;
import 'package:amana_pos/config/router/route_strings.dart';
import 'package:amana_pos/features/business/data/models/responses/business_response_dto.dart';
import 'package:amana_pos/features/business/presentation/business_detail_screen.dart';
import 'package:amana_pos/features/business/presentation/shop_detail_screen.dart';
import 'package:amana_pos/features/login/presentation/login_screen.dart';
import 'package:amana_pos/features/main_screen/presentation/main_screen.dart';
import 'package:amana_pos/features/registration/presentation/registration_screen.dart';
import 'package:amana_pos/features/splash/presentation/splash_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class AppRouter {
  static const _defaultTransitionDuration = Duration(milliseconds: 300);
  static String? currentRouteName;
  static bool enableIOSSwipeGesture = true;

  Route<dynamic> onGenerateRoute(RouteSettings settings) {
    currentRouteName = settings.name;

    switch (settings.name) {
      case RouteStrings.splash:
        return _buildRoute(const SplashScreen(), settings);
      case RouteStrings.login:
        return _buildRoute(const LoginScreen(), settings);
      case RouteStrings.registration:
        return _buildRoute(const RegistrationScreen(), settings);
      case RouteStrings.mainScreen:
        return _buildRoute(const MainScreen(), settings);
      case RouteStrings.businessDetailScreen:
        final args = settings.arguments as Map<String, dynamic>?;
        final BusinessData businessData = args?['businessData'] as BusinessData;
        return _buildRoute(BusinessDetailScreen(business: businessData), settings);
      case RouteStrings.shopDetailScreen:
        final args = settings.arguments as Map<String, dynamic>?;

        final String businessId = args?['businessId'] as String;
        final Shops shop = args?['shop'] as Shops;

        return _buildRoute(ShopDetailScreen(businessId: businessId, shop: shop), settings);
      default:
        return _buildRoute(const SplashScreen(), settings);
    }
  }

  PageRoute _buildRoute(Widget child, RouteSettings settings) {
    final isIOS = !kIsWeb && Platform.isIOS;

    // Only enable on iOS AND if feature flag is true
    if (isIOS && enableIOSSwipeGesture) {
      return CupertinoPageRoute(
        settings: settings,
        builder: (context) => child,
      );
    }
    return PageRouteBuilder(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1, 0);
        const end = Offset.zero;
        const curve = Curves.easeInOut;

        final tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        final offsetAnimation = animation.drive(tween);

        return SlideTransition(position: offsetAnimation, child: child);
      },
      transitionDuration: _defaultTransitionDuration,
    );
  }

}

class SlidePageRoute extends PageRoute {
  final Widget child;

  SlidePageRoute({required this.child});

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    const begin = Offset(1, 0);
    const end = Offset.zero;
    const curve = Curves.easeInOut;
    final tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
    final offsetAnimation = animation.drive(tween);
    return SlideTransition(position: offsetAnimation, child: child);
  }

  @override
  bool get maintainState => true;

  @override
  Duration get transitionDuration => const Duration(milliseconds: 300);
}

class FadeInRoute extends PageRoute {
  FadeInRoute({required this.child});

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  final Widget child;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return FadeTransition(opacity: animation, child: child);
  }

  @override
  bool get maintainState => true;

  @override
  Duration get transitionDuration => const Duration(milliseconds: 300);
}
