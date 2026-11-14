import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/common/motion/motion.dart';
import 'package:amana_pos/config/router/route_strings.dart';
import 'package:amana_pos/core/offline/presentation/bloc/offline_status_bloc.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/widgets/pressable.dart';
import 'package:flutter/material.dart';

class SyncPill extends StatelessWidget {
  const SyncPill({super.key, required this.state});

  final OfflineStatusState state;

  @override
  Widget build(BuildContext context) {
    final vm = _SyncVM.from(context, state);
    final text = Theme.of(context).textTheme;
    final colors = context.appColors;

    return Pressable(
      onTap: state.pendingSalesCount > 0
          ? () => Navigator.of(context).pushNamed(RouteStrings.pendingSyncScreen)
          : null,
      child: AnimatedContainer(
        duration: Motion.duration(AppDims.medium),
        curve: AppDims.ease,
        height: 34,
        padding: const EdgeInsets.symmetric(horizontal: AppDims.s3),
        decoration: BoxDecoration(
          color: vm.background,
          borderRadius: AppDims.borderPill,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (state.isBusy)
              SizedBox(
                width: 10,
                height: 10,
                child: CircularProgressIndicator(
                  strokeWidth: 1.6,
                  color: vm.color,
                ),
              )
            else if (state.pendingSalesCount > 0)
              DecoratedBox(
                decoration: BoxDecoration(
                  color: vm.color,
                  borderRadius: AppDims.borderPill,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      child: Text(
                        '${state.pendingSalesCount}',
                        style: text.labelSmall!.copyWith(
                          color: colors.background,
                          fontWeight: FontWeight.w600,
                          height: 1,
                        ),
                      ),
                    ),
                  ),
                ),
              )
            else
              DecoratedBox(
                decoration: BoxDecoration(
                  color: vm.color,
                  shape: BoxShape.circle,
                ),
                child: const SizedBox(width: 7, height: 7),
              ),
            const SizedBox(width: AppDims.s2 - 1),
            Text(
              vm.label,
              style: text.labelMedium!.copyWith(
                color: vm.color,
                fontWeight: FontWeight.w500,
                height: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SyncVM {
  final String label;
  final Color color;
  final Color background;

  const _SyncVM({
    required this.label,
    required this.color,
    required this.background,
  });

  factory _SyncVM.from(BuildContext context, OfflineStatusState state) {
    final colors = context.appColors;
    final tr = context.tr;

    _SyncVM danger(String label) => _SyncVM(
      label: label,
      color: colors.danger,
      background: colors.dangerContainer,
    );
    _SyncVM warning(String label) => _SyncVM(
      label: label,
      color: colors.warning,
      background: colors.warningContainer,
    );

    if (state.isOffline && !state.canUseAppOffline) {
      return danger(tr.posStatusOffline);
    }
    if (state.isOffline && state.canUseAppOffline) {
      return _SyncVM(
        label: tr.posStatusOffline,
        color: colors.textSecondary,
        background: colors.surfaceSoft,
      );
    }
    if (state.hasFailure) return danger(tr.posStatusSyncIssue);
    if (state.pendingSalesCount > 0) return warning(tr.posStatusPending);
    if (state.isBusy) {
      return _SyncVM(
        label: tr.posStatusSyncing,
        color: colors.info,
        background: colors.infoContainer,
      );
    }
    return _SyncVM(
      label: tr.posStatusSynced,
      color: colors.success,
      background: colors.successContainer,
    );
  }
}
