import 'package:amana_pos/common/auth_bloc/auth_bloc.dart';
import 'package:amana_pos/core/offline/presentation/bloc/offline_status_bloc.dart';
import 'package:amana_pos/features/dashboard/presentation/bloc/dashboard_summary_bloc.dart';
import 'package:amana_pos/features/notification/presentation/bloc/notification_bloc.dart';
import 'package:amana_pos/features/inventory/presentation/bloc/inventory_bloc.dart';
import 'package:amana_pos/features/inventory/presentation/bloc/premium_inventory_bloc.dart';
import 'package:amana_pos/features/inventory/presentation/bloc/stock_levels_bloc.dart';
import 'package:amana_pos/features/inventory/presentation/bloc/inbound_bloc.dart';
import 'package:amana_pos/features/inventory/presentation/bloc/vendors_bloc.dart';
import 'package:amana_pos/features/inventory/presentation/bloc/expiry_report_bloc.dart';
import 'package:amana_pos/features/pos/presentation/bloc/pos_bloc.dart';
import 'package:amana_pos/core/offline/presentation/first_setup_screen.dart';
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

  // ── FirstSetupScreen race-condition flags ─────────────────────────────────
  // FirstSetupScreen.show() is deferred to a postFrameCallback.
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
      // The readiness may have been decided before this widget mounted.
      _handleOfflineStateChange(
        context,
        context.read<OfflineStatusBloc>().state,
      );
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
    context.read<PremiumInventoryBloc>().add(const OnPremiumInventoryReset());
    context.read<StockLevelsBloc>().add(const OnStockLevelsReset());
    context.read<InboundBloc>().add(const OnInboundReset());
    context.read<VendorsBloc>().add(const OnVendorsReset());
    context.read<ExpiryReportBloc>().add(const OnExpiryReportReset());
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

        // First setup gate: only the PHASE decides show / close; the screen
        // itself rebuilds on progress.
        BlocListener<OfflineStatusBloc, OfflineStatusState>(
          listenWhen: (prev, curr) =>
              prev.setupStatus.phase != curr.setupStatus.phase,
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

    // A business that arrives after the readiness check must still gate.
    if (hasBusiness) {
      _handleOfflineStateChange(
        context,
        context.read<OfflineStatusBloc>().state,
      );
    }
  }

  // ── First setup (sync bootstrap) ──────────────────────────────────────────

  /// Spec 2026-11-16 phase 2, section 5: while the signed-in scope was never
  /// bootstrapped (required / running / offline / server not ready) POS is
  /// hidden behind [FirstSetupScreen]. It closes only when the final
  /// bootstrap transaction committed (`done`). A later refresh of a
  /// bootstrapped scope never shows it.
  void _handleOfflineStateChange(
    BuildContext context,
    OfflineStatusState offlineState,
  ) {
    final authState = context.read<AuthBloc>().state;

    // Business not loaded yet: no scope to set up; never block here.
    if (authState.defaultBusiness == null ||
        !offlineState.setupStatus.blocksApp) {
      _closePreparingScreen(context);
      return;
    }

    // Guard against double-show, including a show that's already pending.
    if (FirstSetupScreen.isShowing || _pendingShowPreparing) return;

    _pendingShowPreparing = true;
    _pendingClosePreparing = false;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _pendingShowPreparing = false;
      if (!context.mounted) return;

      // If a close arrived before this frame, honour it and skip the show.
      if (_pendingClosePreparing) {
        _pendingClosePreparing = false;
        return;
      }
      if (!context.read<OfflineStatusBloc>().state.setupStatus.blocksApp) {
        return;
      }

      FirstSetupScreen.show(context);
    });
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

    if (!FirstSetupScreen.isShowing) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _pendingClosePreparing = false;
      if (!context.mounted) return;
      FirstSetupScreen.close(context);
    });
  }
}
