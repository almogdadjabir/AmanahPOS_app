import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/core/offline/presentation/bloc/offline_status_bloc.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';
import 'package:amana_pos/theme/phosphor_icons.dart';

class PreparationSteps extends StatelessWidget {
  const PreparationSteps({super.key, required this.state});

  final OfflineStatusState state;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _PreparationStepTile(
          title: context.tr.poStepBusiness,
          subtitle: context.tr.poStepBusinessSub,
          status: _businessStepStatus(),
        ),
        const SizedBox(height: AppDims.s3),
        _PreparationStepTile(
          title: context.tr.poStepSales,
          subtitle: context.tr.poStepSalesSub,
          status: _bootstrapStepStatus(),
        ),
        const SizedBox(height: AppDims.s3),
        _PreparationStepTile(
          title: context.tr.poStepPending,
          subtitle: state.pendingSalesCount > 0
              ? context.tr.poPendingWaiting(state.pendingSalesCount)
              : context.tr.poPendingNone,
          status: _salesStepStatus(),
        ),
        const SizedBox(height: AppDims.s3),
        _PreparationStepTile(
          title: context.tr.poStepAssets,
          subtitle: context.tr.poStepAssetsSub,
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
    if (state.assetStatus == OfflineAssetStatus.success)
      return _StepStatus.done;
    if (state.assetStatus == OfflineAssetStatus.failure) {
      return _StepStatus.warning;
    }
    return _StepStatus.waiting;
  }
}

enum _StepStatus { waiting, loading, done, warning, error }

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
                  : Icon(icon, size: 19, color: statusColor),
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
        return PhosphorIconsRegular.check;
      case _StepStatus.warning:
        return PhosphorIconsRegular.cloudWarning;
      case _StepStatus.error:
        return PhosphorIconsRegular.warningCircle;
      case _StepStatus.waiting:
        return PhosphorIconsRegular.dotsThree;
      case _StepStatus.loading:
        return PhosphorIconsRegular.arrowsClockwise;
    }
  }

  Color _color(BuildContext context) {
    switch (status) {
      case _StepStatus.done:
        return context.appColors.success;
      case _StepStatus.warning:
        return context.appColors.warning;
      case _StepStatus.error:
        return context.appColors.danger;
      case _StepStatus.waiting:
        return context.appColors.textHint;
      case _StepStatus.loading:
        return context.appColors.primary;
    }
  }
}
