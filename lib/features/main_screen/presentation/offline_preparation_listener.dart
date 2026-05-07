import 'package:amana_pos/common/auth_bloc/auth_bloc.dart';
import 'package:amana_pos/core/offline/presentation/bloc/offline_status_bloc.dart';
import 'package:amana_pos/core/offline/presentation/preparing_offline_screen.dart';
import 'package:amana_pos/features/business/presentation/fancy_business_bottom_sheet.dart';
import 'package:amana_pos/features/business/presentation/subscription_expired_screen.dart';
import 'package:amana_pos/features/category/presentation/bloc/category_bloc.dart';
import 'package:amana_pos/features/products/presentation/bloc/product_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class OfflinePreparationListener extends StatelessWidget {
  const OfflinePreparationListener({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [

        // ── 1. Session switch → reset data blocs ──────────────────────────
        // sessionId bumps when AuthBloc detects a different user logged in.
        // NavigationBloc handles its own reset via its AuthBloc subscription.
        BlocListener<AuthBloc, AuthState>(
          listenWhen: (prev, curr) => prev.sessionId != curr.sessionId,
          listener: (context, _) {
            context.read<ProductBloc>().add(const OnProductReset());
            context.read<CategoryBloc>().add(const OnCategoryReset());
          },
        ),

        // ── 2. Business availability → "no business" sheet ────────────────
        BlocListener<AuthBloc, AuthState>(
          listenWhen: (prev, curr) =>
          prev.businessStatus != curr.businessStatus ||
              prev.defaultBusiness != curr.defaultBusiness,
          listener: _handleBusinessStateChange,
        ),

        // ── 3. Offline bootstrap / asset sync ─────────────────────────────
        BlocListener<OfflineStatusBloc, OfflineStatusState>(
          listenWhen: (prev, curr) =>
          prev.bootstrapStatus != curr.bootstrapStatus ||
              prev.hasCache != curr.hasCache ||
              prev.canUseAppOffline != curr.canUseAppOffline,
          listener: _handleOfflineStateChange,
        ),

        // ── 4. Subscription expiry blocker ────────────────────────────────
        BlocListener<AuthBloc, AuthState>(
          listenWhen: (prev, curr) =>
          prev.defaultBusiness?.activeSubscription?.daysRemaining !=
              curr.defaultBusiness?.activeSubscription?.daysRemaining,
          listener: _handleSubscriptionState,
        ),

      ],
      child: child,
    );
  }

  // ── Handlers ──────────────────────────────────────────────────────────────

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

  void _handleOfflineStateChange(
      BuildContext context,
      OfflineStatusState offlineState,
      ) {
    final authState = context.read<AuthBloc>().state;

    if (authState.defaultBusiness == null) {
      _closePreparingScreen(context);
      return;
    }

    final bootstrapReady =
        offlineState.bootstrapStatus == OfflineBootstrapStatus.success ||
            offlineState.hasCache ||
            offlineState.canUseAppOffline;

    if (!bootstrapReady &&
        offlineState.bootstrapStatus == OfflineBootstrapStatus.loading) {
      if (PreparingOfflineScreen.isShowing) return;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        PreparingOfflineScreen.show(context);
      });
      return;
    }

    if (bootstrapReady) _closePreparingScreen(context);
  }

  void _handleSubscriptionState(BuildContext context, AuthState authState) {
    final sub = authState.defaultBusiness?.activeSubscription;
    if (sub == null) return;

    final isExpired = !(sub.isFree ?? true) && (sub.daysRemaining ?? 0) <= 0;

    if (isExpired) {
      if (SubscriptionExpiredScreen.isShowing) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        SubscriptionExpiredScreen.show(context);
      });
    } else {
      if (!SubscriptionExpiredScreen.isShowing) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        SubscriptionExpiredScreen.close(context);
      });
    }
  }

  void _closePreparingScreen(BuildContext context) {
    if (!PreparingOfflineScreen.isShowing) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;
      PreparingOfflineScreen.close(context);
    });
  }
}