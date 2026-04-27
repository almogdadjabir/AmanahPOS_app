import 'dart:async';

import 'package:amana_pos/config/constants.dart';
import 'package:amana_pos/config/router/app_router.dart';
import 'package:amana_pos/config/router/route_strings.dart';
import 'package:amana_pos/utilities/global_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

class RouteUtils {
  RouteUtils._();

  static bool _isNavigating = false;
  static String? _pendingSnackbarMessage;

  static String? getCurrentRouteName() {
    try {
      return AppRouter.currentRouteName;
    } catch (e) {
      debugPrint('RouteUtils: Failed to get current route name: $e');
      return null;
    }
  }

  static String? currentRouteName() => getCurrentRouteName();

  static Future<void> routeToLogin() async {
    if (_isNavigating) {
      debugPrint('RouteUtils: navigation already in progress — skipping');
      return;
    }
    _isNavigating = true;
    _pendingSnackbarMessage = 'Sorry, your session has expired. Please log in again.';

    try {
      final success = await _navigateToWelcomeWithRetry();

      if (success) {
        _scheduleSnackbar();
      } else {
        _pendingSnackbarMessage = null;
        _showSnackbarSafely(message: 'Session expired. Please restart the app.');
      }
    } catch (e) {
      debugPrint('RouteUtils: routeToLogin threw: $e');
      _pendingSnackbarMessage = null;
    } finally {
      Future.delayed(const Duration(seconds: 3), () {
        _isNavigating = false;
        debugPrint('RouteUtils: navigation lock released');
      });
    }
  }

  static void showSessionExpiredSnackbar() {
    _showSnackbarSafely(message: 'Sorry, your session has expired. Please log in again.');
  }

  static void resetNavigationState() {
    _isNavigating = false;
    _pendingSnackbarMessage = null;
  }

  static Future<bool> _navigateToWelcomeWithRetry({int maxAttempts = 5}) async {
    for (int attempt = 0; attempt < maxAttempts; attempt++) {
      final success = await _tryNavigateToWelcome();
      if (success) return true;

      debugPrint('RouteUtils: attempt ${attempt + 1}/$maxAttempts failed, retrying...');
      await Future.delayed(Duration(milliseconds: 50 * (1 << attempt)));
    }
    return false;
  }

  static Future<bool> _tryNavigateToWelcome() async {
    try {
      final navigator = Constants.navigatorKey.currentState;
      if (navigator == null || !navigator.mounted) return false;

      if (getCurrentRouteName() == RouteStrings.splash) {
        debugPrint('RouteUtils: already on welcome');
        return true;
      }

      final completer = Completer<bool>();

      SchedulerBinding.instance.addPostFrameCallback((_) async {
        try {
          final nav = Constants.navigatorKey.currentState;
          if (nav == null || !nav.mounted) {
            completer.complete(false);
            return;
          }
          await nav.pushNamedAndRemoveUntil(
            RouteStrings.splash,
                (Route<dynamic> route) => false,
          );
          completer.complete(true);
        } catch (e) {
          debugPrint('RouteUtils: pushNamedAndRemoveUntil threw: $e');
          completer.complete(false);
        }
      });

      return await completer.future.timeout(
        const Duration(seconds: 2),
        onTimeout: () {
          debugPrint('RouteUtils: navigation timed out');
          return false;
        },
      );
    } catch (e) {
      debugPrint('RouteUtils: _tryNavigateToWelcome threw: $e');
      return false;
    }
  }

  static void _scheduleSnackbar() {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        Future.delayed(const Duration(milliseconds: 200), () {
          _showPendingSnackbarIfExists();
        });
      });
    });
  }

  static void _showPendingSnackbarIfExists() {
    if (_pendingSnackbarMessage == null) return;
    final message = _pendingSnackbarMessage!;
    _pendingSnackbarMessage = null;
    _showSnackbarSafely(message: message);
  }

  static void _showSnackbarSafely({required String message}) {
    try {
      if (Constants.navigatorKey.currentContext != null) {
        GlobalSnackBar.show(message: message, isError: true, isTop: true);
      } else {
        debugPrint('RouteUtils: context unavailable for snackbar');
      }
    } catch (e) {
      debugPrint('RouteUtils: failed to show snackbar: $e');
    }
  }
}