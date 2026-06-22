import 'package:amana_pos/config/constants.dart';
import 'package:amana_pos/config/router/app_router.dart';
import 'package:amana_pos/config/router/route_strings.dart';
import 'package:amana_pos/features/pin/data/pin_vault_service.dart';
import 'package:amana_pos/utilities/dependencies_provider.dart';
import 'package:flutter/widgets.dart';

/// Re-locks the app with the PIN screen when it returns to the foreground after
/// being backgrounded longer than [_timeout]. Cold-start locking is handled by
/// the splash flow; this covers the resume case for a shared POS device.
class AppLockObserver extends StatefulWidget {
  final Widget child;
  const AppLockObserver({super.key, required this.child});

  @override
  State<AppLockObserver> createState() => _AppLockObserverState();
}

class _AppLockObserverState extends State<AppLockObserver>
    with WidgetsBindingObserver {
  static const _timeout = Duration(minutes: 2);
  DateTime? _backgroundedAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _backgroundedAt ??= DateTime.now();
    } else if (state == AppLifecycleState.resumed) {
      _maybeLock();
    }
  }

  Future<void> _maybeLock() async {
    final since = _backgroundedAt;
    _backgroundedAt = null;
    if (since == null || DateTime.now().difference(since) < _timeout) return;

    // Don't stack the lock screen if already on an auth surface.
    final current = AppRouter.currentRouteName;
    if (current == RouteStrings.pinUnlockScreen ||
        current == RouteStrings.pinSetupScreen ||
        current == RouteStrings.login ||
        current == RouteStrings.splash) {
      return;
    }

    if (await getIt<PinVaultService>().hasAnyEnrolled()) {
      Constants.navigatorKey.currentState?.pushNamedAndRemoveUntil(
        RouteStrings.pinUnlockScreen,
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
