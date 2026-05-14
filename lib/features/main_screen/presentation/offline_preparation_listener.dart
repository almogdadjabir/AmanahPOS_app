import 'package:amana_pos/common/auth_bloc/auth_bloc.dart';
import 'package:amana_pos/core/offline/presentation/bloc/offline_status_bloc.dart';
import 'package:amana_pos/features/dashboard/presentation/bloc/dashboard_summary_bloc.dart';
import 'package:amana_pos/features/notification/presentation/bloc/notification_bloc.dart';
import 'package:amana_pos/features/inventory/presentation/bloc/inventory_bloc.dart';
import 'package:amana_pos/features/pos/presentation/bloc/pos_bloc.dart';
import 'package:amana_pos/core/offline/presentation/preparing_offline_screen.dart';
import 'package:amana_pos/features/business/presentation/fancy_business_bottom_sheet.dart';
import 'package:amana_pos/features/business/presentation/subscription_expired_screen.dart';
import 'package:amana_pos/features/business/presentation/bloc/business_bloc.dart' hide BusinessStatus;
import 'package:amana_pos/features/category/presentation/bloc/category_bloc.dart';
import 'package:amana_pos/features/products/presentation/bloc/product_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class OfflinePreparationListener extends StatefulWidget {
  const OfflinePreparationListener({super.key, required this.child});

  final Widget child;

  @override
  State<OfflinePreparationListener> createState() =>
      _OfflinePreparationListenerState();
}

class _OfflinePreparationListenerState
    extends State<OfflinePreparationListener> {
  int _lastSessionId = 0;

  // ── SubscriptionExpiredScreen race-condition flags ────────────────────────
  bool _pendingShow = false;
  bool _pendingClose = false;

  // ── PreparingOfflineScreen race-condition flags ───────────────────────────
  // PreparingOfflineScreen.show() is deferred to a postFrameCallback.
  // Without these flags, a close that arrives before the frame runs is a
  // no-op (isShowing is still false), and the screen gets stuck permanently.
  bool _pendingShowPreparing = false;
  bool _pendingClosePreparing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _syncSession(context.read<AuthBloc>().state.sessionId);
      _handleSubscriptionState(context, context.read<AuthBloc>().state);
    });
  }

  void _syncSession(int sessionId) {
    if (sessionId == _lastSessionId) return;
    _lastSessionId = sessionId;

    context.read<ProductBloc>().add(const OnProductReset());
    context.read<CategoryBloc>().add(const OnCategoryReset());
    context.read<BusinessBloc>().add(const OnBusinessReset());
    context.read<InventoryBloc>().add(const OnInventoryReset());
    context.read<NotificationBloc>().add(const OnNotificationReset());
    context.read<PosBloc>().add(const PosSessionReset());
    context.read<DashboardSummaryBloc>().add(const OnDashboardSummaryReset());
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [

        BlocListener<AuthBloc, AuthState>(
          listenWhen: (prev, curr) => prev.sessionId != curr.sessionId,
          listener: (context, state) => _syncSession(state.sessionId),
        ),

        BlocListener<AuthBloc, AuthState>(
          listenWhen: (prev, curr) =>
          prev.businessStatus != curr.businessStatus ||
              prev.defaultBusiness != curr.defaultBusiness,
          listener: _handleBusinessStateChange,
        ),

        BlocListener<OfflineStatusBloc, OfflineStatusState>(
          listenWhen: (prev, curr) =>
          prev.bootstrapStatus != curr.bootstrapStatus ||
              prev.hasCache != curr.hasCache ||
              prev.canUseAppOffline != curr.canUseAppOffline,
          listener: _handleOfflineStateChange,
        ),

        BlocListener<AuthBloc, AuthState>(
          listenWhen: (prev, curr) =>
              prev.defaultBusiness?.activeSubscription?.daysRemaining !=
                  curr.defaultBusiness?.activeSubscription?.daysRemaining ||
              (prev.defaultBusiness == null) != (curr.defaultBusiness == null),
          listener: _handleSubscriptionState,
        ),

        // ── 5. Back online → retry business load + refresh badge ─────────
        BlocListener<OfflineStatusBloc, OfflineStatusState>(
          listenWhen: (prev, curr) =>
              prev.connectionStatus != curr.connectionStatus &&
              curr.connectionStatus == OfflineConnectionStatus.online,
          listener: (context, x) {
            final authState = context.read<AuthBloc>().state;
            if (authState.defaultBusiness == null && authState.isLoggedIn) {
              context.read<AuthBloc>().add(OnLoadBusinessEvent());
            }
            if (authState.isLoggedIn) {
              context.read<NotificationBloc>().add(const OnLoadUnreadCount());
            }
          },
        ),

        // ── 6. User authenticated → load unread count ─────────────────────
        BlocListener<AuthBloc, AuthState>(
          listenWhen: (prev, curr) => !prev.isLoggedIn && curr.isLoggedIn,
          listener: (context, _) {
            context.read<NotificationBloc>().add(const OnLoadUnreadCount());
          },
        ),

      ],
      child: widget.child,
    );
  }

  // ── Business state ─────────────────────────────────────────────────────────

  void _handleBusinessStateChange(BuildContext context, AuthState authState) {
    final hasBusiness = authState.defaultBusiness != null;

    if (authState.businessStatus == BusinessStatus.success && !hasBusiness) {
      _closePreparingScreen(context);

      if (FancyBusinessBottomSheet.isShowing) return;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        FancyBusinessBottomSheet.show(context);
      });
      return;
    }

    if (hasBusiness && FancyBusinessBottomSheet.isShowing) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        final navigator = Navigator.of(context, rootNavigator: true);
        if (navigator.canPop()) navigator.pop();
        FancyBusinessBottomSheet.reset();
      });
    }
  }

  // ── Offline / bootstrap state ─────────────────────────────────────────────

  void _handleOfflineStateChange(
      BuildContext context,
      OfflineStatusState offlineState,
      ) {
    final authState = context.read<AuthBloc>().state;

    // Business not loaded yet — dismiss any overlay so the app isn't blocked.
    if (authState.defaultBusiness == null) {
      _closePreparingScreen(context);
      return;
    }

    final bootstrapReady =
        offlineState.bootstrapStatus == OfflineBootstrapStatus.success ||
            offlineState.hasCache ||
            offlineState.canUseAppOffline;

    if (bootstrapReady) {
      // Has local data — always safe to proceed, dismiss overlay.
      _closePreparingScreen(context);
      return;
    }

    // No cache. Only block the UI while a bootstrap is actively in progress.
    if (offlineState.bootstrapStatus == OfflineBootstrapStatus.loading) {
      // Guard against double-show, including a show that's already pending.
      if (PreparingOfflineScreen.isShowing || _pendingShowPreparing) return;

      _pendingShowPreparing = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _pendingShowPreparing = false;
        if (!context.mounted) return;

        // If a close arrived before this frame, honour it and skip the show.
        if (_pendingClosePreparing) {
          _pendingClosePreparing = false;
          return;
        }

        PreparingOfflineScreen.show(context);
      });
      return;
    }

    // Not ready AND not loading (failure / initial) — dismiss so the user
    // is never permanently blocked. The error is visible in the main UI.
    _closePreparingScreen(context);
  }

  // ── Subscription state ────────────────────────────────────────────────────

  void _handleSubscriptionState(BuildContext context, AuthState authState) {
    final sub = authState.defaultBusiness?.activeSubscription;
    if (sub == null) return;

    final isExpired = !(sub.isFree ?? true) && (sub.daysRemaining ?? 0) <= 0;

    if (isExpired) {
      if (SubscriptionExpiredScreen.isShowing || _pendingShow) return;
      _pendingShow = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _pendingShow = false;
        if (!context.mounted) return;
        if (_pendingClose) {
          _pendingClose = false;
          return;
        }
        final currentSub =
            context.read<AuthBloc>().state.defaultBusiness?.activeSubscription;
        if (currentSub == null) return;
        final stillExpired =
            !(currentSub.isFree ?? true) && (currentSub.daysRemaining ?? 0) <= 0;
        if (!stillExpired) return;

        SubscriptionExpiredScreen.show(context);
      });
    } else {
      _pendingClose = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _pendingClose = false;
        if (!context.mounted) return;
        if (!SubscriptionExpiredScreen.isShowing) return;
        SubscriptionExpiredScreen.close(context);
      });
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  void _closePreparingScreen(BuildContext context) {
    // Cancel any pending show so it doesn't re-appear after this close.
    _pendingClosePreparing = true;

    if (!PreparingOfflineScreen.isShowing) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _pendingClosePreparing = false;
      if (!context.mounted) return;
      PreparingOfflineScreen.close(context);
    });
  }
}
