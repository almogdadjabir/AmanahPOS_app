import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/config/router/route_strings.dart';
import 'package:amana_pos/core/offline/presentation/bloc/offline_status_bloc.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';

class SyncPill extends StatelessWidget {
  const SyncPill({super.key, required this.state});

  final OfflineStatusState state;

  @override
  Widget build(BuildContext context) {
    final vm = _SyncVM.from(context, state);

    return GestureDetector(
      onTap: state.pendingSalesCount > 0
          ? () => Navigator.of(context).pushNamed(RouteStrings.pendingSyncScreen)
          : null,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
        height: 46,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: vm.color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: vm.color.withValues(alpha: 0.28),
            width: 1.1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (state.isBusy)
              SizedBox(
                width: 8,
                height: 8,
                child: CircularProgressIndicator(
                  strokeWidth: 1.6,
                  color: vm.color,
                ),
              )
            else
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: vm.color,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: vm.color.withValues(alpha: 0.55),
                      blurRadius: 6,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),

            const SizedBox(width: 7),

            Text(
              vm.label,
              style: AppTextStyles.sm300(context).copyWith(
                color: vm.color,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
                height: 1,
              ),
            ),

            // Pending count badge
            if (state.pendingSalesCount > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.34),
                  ),
                ),
                child: Text(
                  '${state.pendingSalesCount}',
                  style: AppTextStyles.sm100(context).copyWith(
                    color: const Color(0xFFF59E0B),
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SyncVM {
  final String label;
  final Color color;

  const _SyncVM({required this.label, required this.color});

  factory _SyncVM.from(BuildContext context, OfflineStatusState state) {
    final colors = context.appColors;
    if (state.isOffline && !state.canUseAppOffline) {
      return _SyncVM(label: context.tr.posStatusOffline, color: colors.danger);
    }
    if (state.isOffline && state.canUseAppOffline) {
      return _SyncVM(label: context.tr.posStatusOffline, color: const Color(0xFFF59E0B));
    }
    if (state.hasFailure) {
      return _SyncVM(label: context.tr.posStatusSyncIssue, color: colors.danger);
    }
    if (state.pendingSalesCount > 0) {
      return _SyncVM(label: context.tr.posStatusPending, color: const Color(0xFFF59E0B));
    }
    if (state.isBusy) {
      return _SyncVM(label: context.tr.posStatusSyncing, color: const Color(0xFF38BDF8));
    }
    return _SyncVM(label: context.tr.posStatusSynced, color: const Color(0xFF22C55E));
  }
}