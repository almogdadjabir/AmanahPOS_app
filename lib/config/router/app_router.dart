import 'dart:io' show Platform;
import 'package:amana_pos/common/motion/motion.dart';
import 'package:amana_pos/barcode_scanner/presentation/screens/barcode_scanner_screen.dart';
import 'package:amana_pos/config/providers/feature_bloc_providers.dart';
import 'package:amana_pos/config/router/route_strings.dart';
import 'package:amana_pos/features/business/data/models/responses/business_response_dto.dart';
import 'package:amana_pos/features/business/presentation/business_detail_screen.dart';
import 'package:amana_pos/features/devices/presentation/printer_settings_screen.dart';
import 'package:amana_pos/features/business/presentation/shop_detail_screen.dart';
import 'package:amana_pos/features/business/presentation/shop_management_screen.dart';
import 'package:amana_pos/features/login/presentation/login_screen.dart';
import 'package:amana_pos/features/main_screen/presentation/main_screen.dart';
import 'package:amana_pos/features/products/data/model/response/category_products_response_dto.dart';
import 'package:amana_pos/features/products/presentation/product_detail_screen.dart';
import 'package:amana_pos/features/products/presentation/product_screen.dart';
import 'package:amana_pos/features/registration/presentation/registration_screen.dart';
import 'package:amana_pos/features/returns/presentation/returns_screen.dart';
import 'package:amana_pos/features/sales_history/data/models/sale_history_item.dart';
import 'package:amana_pos/features/sales_history/presentation/sales_history_screen.dart';
import 'package:amana_pos/features/settings/presentation/settings_screen.dart';
import 'package:amana_pos/features/splash/presentation/splash_screen.dart';
import 'package:amana_pos/features/users/data/models/responses/user_response_dto.dart';
import 'package:amana_pos/features/users/presentation/user_detail_screen.dart';
import 'package:amana_pos/features/inventory/presentation/expiry_alerts_screen.dart';
import 'package:amana_pos/features/notification/presentation/notifications_screen.dart';
import 'package:amana_pos/features/sync/presentation/pending_sync_screen.dart';
import 'package:amana_pos/features/sync/presentation/bloc/pending_sync_bloc.dart';
import 'package:amana_pos/utilities/dependencies_provider.dart';
import 'package:amana_pos/features/users/presentation/users_screen.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

class AppRouter {
  static const _defaultTransitionDuration = Duration(milliseconds: 300);
  static String? currentRouteName;
  static bool enableIOSSwipeGesture = true;

  Route<dynamic> onGenerateRoute(RouteSettings settings) {
    currentRouteName = settings.name;

    switch (settings.name) {
      case RouteStrings.splash:
        return _buildRoute(
          FeatureBlocProviders.splash(
            child: const SplashScreen(),
          ),
          settings,
        );
      case RouteStrings.login:
        return _buildRoute(
          FeatureBlocProviders.login(
            child: const LoginScreen(),
          ),
          settings,
        );
      case RouteStrings.registration:
        return _buildRoute(
          FeatureBlocProviders.registration(
            child: const RegistrationScreen(),
          ),
          settings,
        );
      case RouteStrings.mainScreen:
        return _buildRoute(const MainScreen(), settings);
      case RouteStrings.businessDetailScreen:
        final args = settings.arguments as Map<String, dynamic>?;
        final BusinessData businessData = args?['businessData'] as BusinessData;
        return _buildRoute(BusinessDetailScreen(business: businessData), settings);
      case RouteStrings.shopDetailScreen:
        final args = settings.arguments as Map<String, dynamic>?;
        final String businessId = args?['businessId'] as String;
        final ShopData shop = args?['shop'] as ShopData;

        return _buildRoute(ShopDetailScreen(businessId: businessId, shop: shop), settings);
      case RouteStrings.userDetailScreen:
        final args = settings.arguments as Map<String, dynamic>?;
        final UserData user = args?['user'] as UserData;

        return _buildRoute(UserDetailScreen(user: user), settings);
      case RouteStrings.productScreen:
        return _materialOrInstant(
          ProductsScreen(isWithAppbar: true),
          settings,
        );

      case RouteStrings.cashiersScreen:
        return _materialOrInstant(
          const UsersScreen(isWithAppbar: true),
          settings,
        );

      case RouteStrings.shopManagementScreen:
        final args = settings.arguments as Map<String, dynamic>;
        return _materialOrInstant(
          ShopManagementScreen(
            business: args['businessData'] as BusinessData,
          ),
          settings,
        );

      case RouteStrings.productDetailScreen:
        final args = settings.arguments as Map<String, dynamic>;
        return _materialOrInstant(
          FeatureBlocProviders.inventory(
            child: ProductDetailScreen(
              product: args['product'] as ProductData,
            ),
          ),
          settings,
        );

      case RouteStrings.settingsScreen:
        return _materialOrInstant(
          FeatureBlocProviders.settings(
            child: const SettingsScreen(),
          ),
          settings,
        );

      case RouteStrings.notificationsScreen:
        return _materialOrInstant(
          const NotificationsScreen(),
          settings,
        );

      case RouteStrings.barcodeScannerScreen:
        return _materialOrInstant(
          FeatureBlocProviders.barcodeScanner(
            child: const BarcodeScannerScreen(),
          ),
          settings,
        );

      case RouteStrings.expiryAlertsScreen:
        return _materialOrInstant(
          FeatureBlocProviders.expiryAlerts(
            child: const ExpiryAlertsScreen(),
          ),
          settings,
        );

      case RouteStrings.pendingSyncScreen:
        return _materialOrInstant(
          BlocProvider(
            create: (_) => getIt<PendingSyncBloc>(),
            child: const PendingSyncScreen(),
          ),
          settings,
        );

      case RouteStrings.salesHistoryScreen:
        return _buildRoute(
          FeatureBlocProviders.salesHistory(
            child: const SalesHistoryScreen(),
          ),
          settings,
        );

      case RouteStrings.printerSettingsScreen:
        return _buildRoute(const PrinterSettingsScreen(), settings);

      case RouteStrings.returnsScreen:
        final preloadedSale = settings.arguments as SaleHistoryItem?;
        return _buildRoute(
          FeatureBlocProviders.returns(
            child: ReturnsScreen(preloadedSale: preloadedSale),
          ),
          settings,
        );

      default:
        return _buildRoute(const SplashScreen(), settings);
    }
  }

  /// Returns an instant (zero-duration, no-transition) route. Used by both
  /// [_buildRoute] when motion is off and [_materialOrInstant] for screens
  /// that previously used [MaterialPageRoute] directly.
  PageRoute _instantRoute(Widget child, RouteSettings settings) {
    return PageRouteBuilder(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) =>
          child,
      transitionDuration: Duration.zero,
      reverseTransitionDuration: Duration.zero,
    );
  }

  /// When motion is on, returns a standard [MaterialPageRoute] (vertical
  /// slide-up transition). When motion is off, returns an instant route so
  /// screens that bypassed [_buildRoute] still respect the off-switch.
  PageRoute _materialOrInstant(Widget child, RouteSettings settings) {
    if (!Motion.on) return _instantRoute(child, settings);
    return MaterialPageRoute(builder: (_) => child, settings: settings);
  }

  PageRoute _buildRoute(Widget child, RouteSettings settings) {
    if (!Motion.on) {
      return _instantRoute(child, settings);
    }

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
