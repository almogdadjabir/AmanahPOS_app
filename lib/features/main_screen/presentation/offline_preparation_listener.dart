import 'package:amana_pos/common/auth_bloc/auth_bloc.dart';
import 'package:amana_pos/core/offline/presentation/bloc/offline_status_bloc.dart';
import 'package:amana_pos/core/offline/presentation/preparing_offline_screen.dart';
import 'package:amana_pos/features/business/presentation/fancy_business_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class OfflinePreparationListener extends StatelessWidget {
  const OfflinePreparationListener({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<AuthBloc, AuthState>(
          listenWhen: (previous, current) {
            return previous.businessStatus != current.businessStatus ||
                previous.defaultBusiness != current.defaultBusiness;
          },
          listener: _handleAuthStateChange,
        ),
        BlocListener<OfflineStatusBloc, OfflineStatusState>(
          listenWhen: (previous, current) {
            return previous.bootstrapStatus != current.bootstrapStatus ||
                previous.assetStatus != current.assetStatus ||
                previous.salesSyncStatus != current.salesSyncStatus ||
                previous.hasCache != current.hasCache ||
                previous.canUseAppOffline != current.canUseAppOffline ||
                previous.connectionStatus != current.connectionStatus;
          },
          listener: _handleOfflineStateChange,
        ),
      ],
      child: child,
    );
  }

  void _handleAuthStateChange(BuildContext context, AuthState authState) {
    final hasBusiness = authState.defaultBusiness != null;

    final shouldShowNoBusinessSheet =
        authState.businessStatus == BusinessStatus.success && !hasBusiness;

    if (shouldShowNoBusinessSheet) {
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
        if (navigator.canPop()) {
          navigator.pop();
        }

        FancyBusinessBottomSheet.reset();
      });
    }
  }

  void _handleOfflineStateChange(
      BuildContext context,
      OfflineStatusState offlineState,
      ) {
    final authState = context.read<AuthBloc>().state;
    final hasBusiness = authState.defaultBusiness != null;

    if (!hasBusiness) {
      _closePreparingScreen(context);
      return;
    }

    final bootstrapReady =
        offlineState.bootstrapStatus == OfflineBootstrapStatus.success ||
            offlineState.hasCache ||
            offlineState.canUseAppOffline;

    final shouldShowPreparingScreen =
        !bootstrapReady &&
            offlineState.bootstrapStatus == OfflineBootstrapStatus.loading;

    final shouldClosePreparingScreen = bootstrapReady;

    if (shouldShowPreparingScreen) {
      if (PreparingOfflineScreen.isShowing) return;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        PreparingOfflineScreen.show(context);
      });

      return;
    }

    if (shouldClosePreparingScreen) {
      _closePreparingScreen(context);
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