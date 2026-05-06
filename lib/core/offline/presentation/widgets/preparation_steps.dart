import 'package:amana_pos/core/offline/presentation/bloc/offline_status_bloc.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';

class PreparationSteps extends StatelessWidget {
  const PreparationSteps({super.key,
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