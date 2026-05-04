import 'package:amana_pos/core/offline/presentation/bloc/offline_status_bloc.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/utilities/dependencies_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class PreparingOfflineScreen {
  static bool isShowing = false;

  static Future<void> show(BuildContext context) async {
    if (isShowing) return;

    isShowing = true;

    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'Preparing Offline Mode',
      useRootNavigator: true,
      transitionDuration: const Duration(milliseconds: 420),
      pageBuilder: (_, _, _) {
        return BlocProvider.value(
          value: getIt<OfflineStatusBloc>(),
          child: const _PreparingOfflineDialogBody(),
        );
      },
      transitionBuilder: (_, animation, _, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );

        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.96, end: 1).animate(curved),
            child: child,
          ),
        );
      },
    );

    isShowing = false;
  }

  static void close(BuildContext context) {
    if (!isShowing) return;

    final navigator = Navigator.of(context, rootNavigator: true);
    if (navigator.canPop()) {
      navigator.pop();
    }

    isShowing = false;
  }

  static void reset() {
    isShowing = false;
  }
}

class _PreparingOfflineDialogBody extends StatelessWidget {
  const _PreparingOfflineDialogBody();

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: colors.surface,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppDims.s5),
            child: BlocBuilder<OfflineStatusBloc, OfflineStatusState>(
              builder: (context, state) {
                return Column(
                  children: [
                    const Spacer(),

                    const _OfflineHero()
                        .animate()
                        .fadeIn(duration: 420.ms)
                        .scale(
                      begin: const Offset(0.92, 0.92),
                      end: const Offset(1, 1),
                      curve: Curves.easeOutCubic,
                    ),

                    const SizedBox(height: AppDims.s6),

                    Text(
                      'Preparing Offline Mode',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.lg200(context).copyWith(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    )
                        .animate()
                        .fadeIn(duration: 420.ms)
                        .slideY(
                      begin: 0.16,
                      end: 0,
                      curve: Curves.easeOutCubic,
                    ),

                    const SizedBox(height: AppDims.s2),

                    Text(
                      _description(state),
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bs400(context).copyWith(
                        color: colors.textSecondary,
                        height: 1.45,
                        fontWeight: FontWeight.w600,
                      ),
                    )
                        .animate()
                        .fadeIn(delay: 90.ms, duration: 420.ms)
                        .slideY(
                      begin: 0.16,
                      end: 0,
                      curve: Curves.easeOutCubic,
                    ),

                    const SizedBox(height: AppDims.s6),

                    _PreparationSteps(state: state)
                        .animate()
                        .fadeIn(delay: 180.ms, duration: 420.ms)
                        .slideY(
                      begin: 0.12,
                      end: 0,
                      curve: Curves.easeOutCubic,
                    ),

                    const Spacer(),

                    _FooterStatus(state: state)
                        .animate()
                        .fadeIn(delay: 260.ms, duration: 420.ms)
                        .slideY(
                      begin: 0.22,
                      end: 0,
                      curve: Curves.easeOutCubic,
                    ),

                    const SizedBox(height: AppDims.s2),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  String _description(OfflineStatusState state) {
    if (state.connectionStatus == OfflineConnectionStatus.offline) {
      return 'Internet is required only for the first setup. Please connect once so AmanaPOS can prepare your business for offline use.';
    }

    if (state.isBootstrapLoading) {
      return 'Please keep the app open while we download your business data, products, categories, stock, and customers.';
    }

    if (state.isAssetsLoading) {
      return 'Your business data is ready. We are updating product and category assets in the background.';
    }

    if (state.hasFailure) {
      return state.errorMessage ?? 'Something went wrong while preparing offline mode.';
    }

    return 'Almost done. AmanaPOS is getting your workspace ready for poor internet and offline sales.';
  }
}

class _OfflineHero extends StatefulWidget {
  const _OfflineHero();

  @override
  State<_OfflineHero> createState() => _OfflineHeroState();
}

class _OfflineHeroState extends State<_OfflineHero>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _float;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _float = Tween<double>(begin: -6, end: 6).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return AnimatedBuilder(
      animation: _float,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _float.value),
          child: child,
        );
      },
      child: Container(
        width: 132,
        height: 132,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colors.primary.withValues(alpha: 0.18),
              const Color(0xFF0D9488).withValues(alpha: 0.10),
              colors.surfaceSoft,
            ],
          ),
          border: Border.all(
            color: colors.primary.withValues(alpha: 0.20),
          ),
          boxShadow: [
            BoxShadow(
              color: colors.primary.withValues(alpha: 0.12),
              blurRadius: 32,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 82,
              height: 82,
              decoration: BoxDecoration(
                color: colors.surface,
                shape: BoxShape.circle,
                border: Border.all(color: colors.border),
              ),
            ),
            Icon(
              Icons.cloud_sync_rounded,
              size: 44,
              color: colors.primary,
            ),
            Positioned(
              right: 26,
              bottom: 28,
              child: Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: const Color(0xFF16A34A),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: colors.surface,
                    width: 3,
                  ),
                ),
                child: const Icon(
                  Icons.offline_bolt_rounded,
                  size: 16,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PreparationSteps extends StatelessWidget {
  const _PreparationSteps({
    required this.state,
  });

  final OfflineStatusState state;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _PreparationStepTile(
          title: 'Business workspace',
          subtitle: 'Business and shops',
          status: _businessStepStatus(),
        ),
        const SizedBox(height: AppDims.s3),
        _PreparationStepTile(
          title: 'Sales data',
          subtitle: 'Products, categories, customers, and stock',
          status: _bootstrapStepStatus(),
        ),
        const SizedBox(height: AppDims.s3),
        _PreparationStepTile(
          title: 'Pending sales',
          subtitle: state.pendingSalesCount > 0
              ? '${state.pendingSalesCount} sale(s) waiting to sync'
              : 'No pending sales',
          status: _salesStepStatus(),
        ),
        const SizedBox(height: AppDims.s3),
        _PreparationStepTile(
          title: 'Product assets',
          subtitle: 'Images and thumbnails',
          status: _assetStepStatus(),
        ),
      ],
    );
  }

  _StepStatus _businessStepStatus() {
    if (state.hasCache || state.canUseAppOffline) return _StepStatus.done;
    if (state.isBootstrapLoading) return _StepStatus.loading;
    if (state.hasFailure) return _StepStatus.error;
    return _StepStatus.waiting;
  }

  _StepStatus _bootstrapStepStatus() {
    if (state.canUseAppOffline) return _StepStatus.done;
    if (state.isBootstrapLoading) return _StepStatus.loading;
    if (state.bootstrapStatus == OfflineBootstrapStatus.failure) {
      return _StepStatus.error;
    }
    return _StepStatus.waiting;
  }

  _StepStatus _salesStepStatus() {
    if (state.isSalesSyncing) return _StepStatus.loading;
    if (state.salesSyncStatus == OfflineSalesSyncStatus.failure) {
      return _StepStatus.error;
    }
    if (state.pendingSalesCount == 0) return _StepStatus.done;
    return _StepStatus.warning;
  }

  _StepStatus _assetStepStatus() {
    if (state.isAssetsLoading) return _StepStatus.loading;
    if (state.assetStatus == OfflineAssetStatus.success) return _StepStatus.done;
    if (state.assetStatus == OfflineAssetStatus.failure) {
      return _StepStatus.warning;
    }
    return _StepStatus.waiting;
  }
}

enum _StepStatus {
  waiting,
  loading,
  done,
  warning,
  error,
}

class _PreparationStepTile extends StatelessWidget {
  const _PreparationStepTile({
    required this.title,
    required this.subtitle,
    required this.status,
  });

  final String title;
  final String subtitle;
  final _StepStatus status;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final statusColor = _color(context);
    final icon = _icon();

    return Container(
      padding: const EdgeInsets.all(AppDims.s4),
      decoration: BoxDecoration(
        color: colors.surfaceSoft,
        borderRadius: BorderRadius.circular(AppDims.rMd),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: status == _StepStatus.loading
                  ? SizedBox(
                width: 17,
                height: 17,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: statusColor,
                ),
              )
                  : Icon(
                icon,
                size: 19,
                color: statusColor,
              ),
            ),
          ),
          const SizedBox(width: AppDims.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.bs400(context).copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bs200(context).copyWith(
                    color: colors.textSecondary,
                    fontWeight: FontWeight.w600,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _icon() {
    switch (status) {
      case _StepStatus.done:
        return Icons.check_rounded;
      case _StepStatus.warning:
        return Icons.sync_problem_rounded;
      case _StepStatus.error:
        return Icons.error_outline_rounded;
      case _StepStatus.waiting:
        return Icons.more_horiz_rounded;
      case _StepStatus.loading:
        return Icons.sync_rounded;
    }
  }

  Color _color(BuildContext context) {
    switch (status) {
      case _StepStatus.done:
        return const Color(0xFF16A34A);
      case _StepStatus.warning:
        return const Color(0xFFF59E0B);
      case _StepStatus.error:
        return context.appColors.danger;
      case _StepStatus.waiting:
        return context.appColors.textHint;
      case _StepStatus.loading:
        return context.appColors.primary;
    }
  }
}

class _FooterStatus extends StatelessWidget {
  const _FooterStatus({
    required this.state,
  });

  final OfflineStatusState state;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    final canRetry = state.hasFailure &&
        state.connectionStatus == OfflineConnectionStatus.online;

    return Column(
      children: [
        if (canRetry)
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton.icon(
              onPressed: () {
                context.read<OfflineStatusBloc>().add(
                  const OnOfflineStatusRefreshRequested(),
                );
              },
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try Again'),
              style: FilledButton.styleFrom(
                backgroundColor: colors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDims.rMd),
                ),
                textStyle: AppTextStyles.bs600(context).copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          )
        else
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: AppDims.s4,
              vertical: AppDims.s3,
            ),
            decoration: BoxDecoration(
              color: colors.surfaceSoft,
              borderRadius: BorderRadius.circular(AppDims.rMd),
              border: Border.all(color: colors.border),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  state.connectionStatus == OfflineConnectionStatus.online
                      ? Icons.wifi_rounded
                      : Icons.wifi_off_rounded,
                  size: 17,
                  color: state.connectionStatus == OfflineConnectionStatus.online
                      ? const Color(0xFF16A34A)
                      : const Color(0xFFF59E0B),
                ),
                const SizedBox(width: AppDims.s2),
                Flexible(
                  child: Text(
                    '${state.connectionLabel} · ${state.statusLabel}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bs200(context).copyWith(
                      color: colors.textSecondary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: AppDims.s3),
        Text(
          'This setup is required only once. After that, AmanaPOS can keep working during poor internet.',
          textAlign: TextAlign.center,
          style: AppTextStyles.bs200(context).copyWith(
            color: colors.textHint,
            fontWeight: FontWeight.w700,
            height: 1.35,
          ),
        ),
      ],
    );
  }
}