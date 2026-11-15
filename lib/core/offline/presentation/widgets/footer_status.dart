import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/core/offline/presentation/bloc/offline_status_bloc.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:amana_pos/theme/phosphor_icons.dart';

class FooterStatus extends StatelessWidget {
  const FooterStatus({super.key, required this.state});

  final OfflineStatusState state;

  String _connection(BuildContext context) {
    final tr = context.tr;
    return switch (state.connectionStatus) {
      OfflineConnectionStatus.online => tr.poOnline,
      OfflineConnectionStatus.offline => tr.poOffline,
      OfflineConnectionStatus.unknown => tr.poChecking,
    };
  }

  String _status(BuildContext context) {
    final tr = context.tr;
    if (state.isBootstrapLoading) return tr.poUpdatingData;
    if (state.isAssetsLoading) return tr.poUpdatingAssets;
    if (state.isSalesSyncing) return tr.poSyncingSales;
    if (state.pendingSalesCount > 0) {
      return tr.poPendingCount(state.pendingSalesCount);
    }
    if (state.isOffline && state.canUseAppOffline) return tr.poOfflineReady;
    if (state.hasFailure) return tr.poSyncFailed;
    if (state.lastSalesSyncAt != null || state.lastBootstrapSyncAt != null) {
      return tr.poSynced;
    }
    return tr.poReady;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    final canRetry =
        state.hasFailure &&
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
              icon: const Icon(PhosphorIconsRegular.arrowsClockwise),
              label: Text(context.tr.poTryAgain),
              style: FilledButton.styleFrom(
                backgroundColor: colors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDims.rMd),
                ),
                textStyle: AppTextStyles.bs600(
                  context,
                ).copyWith(fontWeight: FontWeight.w900),
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
                      ? PhosphorIconsRegular.wifiHigh
                      : PhosphorIconsRegular.wifiSlash,
                  size: 17,
                  color:
                      state.connectionStatus == OfflineConnectionStatus.online
                      ? colors.success
                      : colors.warning,
                ),
                const SizedBox(width: AppDims.s2),
                Flexible(
                  child: Text(
                    '${_connection(context)} · ${_status(context)}',
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
          context.tr.poFooterNote,
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
