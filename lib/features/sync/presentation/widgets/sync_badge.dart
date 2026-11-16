import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/core/sync/sync_engine.dart';
import 'package:amana_pos/core/sync/sync_flags.dart';
import 'package:amana_pos/features/sync/presentation/bloc/sync_badge_cubit.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/utilities/dependencies_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Unsynced count + engine phase. Renders nothing with the sync engine off.
/// "Server unreachable" comes from the engine's server ping, not device Wi-Fi.
class SyncBadge extends StatelessWidget {
  const SyncBadge({super.key});

  @override
  Widget build(BuildContext context) {
    if (!kSyncEngineEnabled) return const SizedBox.shrink();
    return FutureBuilder<SyncBadgeCubit>(
      future: getIt.getAsync<SyncBadgeCubit>(),
      builder: (context, snap) {
        final cubit = snap.data;
        if (cubit == null) return const SizedBox.shrink();
        return BlocBuilder<SyncBadgeCubit, SyncBadgeState>(
          bloc: cubit,
          builder: (context, s) => _Badge(state: s),
        );
      },
    );
  }
}

class _Badge extends StatelessWidget {
  final SyncBadgeState state;
  const _Badge({required this.state});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final tr = context.tr;
    final st = state.status;
    final (label, color) = st.needsLogin
        ? (tr.syOxNeedsLogin, colors.danger)
        : !st.serverReachable && state.unsynced > 0
        ? (tr.syOxServerUnreachable, colors.warning)
        : switch (st.phase) {
            SyncPhase.pinging ||
            SyncPhase.pushing ||
            SyncPhase.pulling => (tr.syOxSyncing, colors.primary),
            _ when state.unsynced > 0 => (
              tr.syOxUnsynced(state.unsynced),
              st.rejected > 0 ? colors.danger : colors.textSecondary,
            ),
            _ => (tr.syOxAllSynced, colors.success),
          };
    final text = Theme.of(context).textTheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            state.unsynced > 0 && label != tr.syOxUnsynced(state.unsynced)
                ? '$label · ${tr.syOxUnsynced(state.unsynced)}'
                : label,
            style: text.labelMedium!.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}
