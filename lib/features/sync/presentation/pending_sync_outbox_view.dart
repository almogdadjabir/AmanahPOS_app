import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/core/sync/outbox/outbox_entry.dart';
import 'package:amana_pos/features/sync/presentation/bloc/pending_sync_bloc.dart';
import 'package:amana_pos/features/sync/presentation/widgets/sync_badge.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/widgets/app_confirm_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Sync-engine-on body of the Pending Sync screen: every unsynced outbox row
/// (current scope and other scopes) with retry / discard.
class PendingSyncOutboxView extends StatelessWidget {
  final List<PendingSyncRow> rows;
  const PendingSyncOutboxView({super.key, required this.rows});

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    final otherScopes = {
      for (final r in rows)
        if (r.otherScope) r.entry.scope,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SyncBadge(),
        const SizedBox(height: 12),
        for (final r in rows) _OutboxRow(row: r),
        for (final scope in otherScopes)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: TextButton(
              onPressed: () async {
                final bloc = context.read<PendingSyncBloc>();
                final ok = await showAppConfirmSheet(
                  context,
                  title: tr.syOxDiscardOtherTitle,
                  message: tr.syOxDiscardOtherBody,
                  confirmLabel: tr.syOxDiscard,
                );
                if (ok) bloc.add(OnPendingSyncDiscardScope(scope));
              },
              child: Text(tr.syOxDiscardOtherAction),
            ),
          ),
      ],
    );
  }
}

class _OutboxRow extends StatelessWidget {
  final PendingSyncRow row;
  const _OutboxRow({required this.row});

  String _entity(BuildContext c) {
    final tr = c.tr;
    switch (row.entry.entity) {
      case 'sale':
        return tr.syOxEntitySale;
      case 'stock':
        return tr.syOxEntityStock;
      case 'inbound':
        return tr.syOxEntityInbound;
      default:
        return tr.syOxEntityOther;
    }
  }

  String _state(BuildContext c) {
    final tr = c.tr;
    switch (row.entry.status) {
      case OutboxStatus.rejected:
        return tr.syOxStateRejected;
      case OutboxStatus.blocked:
        return tr.syOxStateBlocked;
      case OutboxStatus.inflight:
        return tr.syOxStateInflight;
      default:
        return tr.syOxStatePending;
    }
  }

  String _title(BuildContext c, PendingSyncRow r) {
    final name = r.label.isNotEmpty ? r.label : r.entry.entityId;
    final total = r.total == null ? '' : ' · ${r.total}';
    return '$name$total';
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final text = Theme.of(context).textTheme;
    final tr = context.tr;
    final e = row.entry;
    final rejected = e.status == OutboxStatus.rejected;
    final bloc = context.read<PendingSyncBloc>();
    final error = (e.errorMessage?.trim().isNotEmpty ?? false)
        ? e.errorMessage!.trim()
        : tr.syOxErrorFallback;

    Future<void> discard() async {
      final isSale = e.entity == 'sale';
      final ok = await showAppConfirmSheet(
        context,
        title: isSale ? tr.syOxDiscardSaleTitle : tr.syOxDiscardRowTitle,
        message: isSale ? tr.syOxDiscardSaleBody : tr.syOxDiscardRowBody,
        confirmLabel: tr.syOxDiscard,
      );
      if (ok) bloc.add(OnPendingSyncDiscardRow(e.mutationId));
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${_entity(context)} · ${_title(context, row)}',
                      style: text.titleSmall!.copyWith(
                        color: colors.textPrimary,
                      ),
                    ),
                  ),
                  Text(
                    _state(context),
                    style: text.labelMedium!.copyWith(
                      color: rejected ? colors.danger : colors.textHint,
                    ),
                  ),
                ],
              ),
              if (row.otherScope)
                Text(
                  tr.syOxOtherAccount,
                  style: text.bodySmall!.copyWith(color: colors.warning),
                ),
              if (rejected)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    e.errorCode == null ? error : '$error (${e.errorCode})',
                    style: text.bodySmall!.copyWith(color: colors.danger),
                  ),
                ),
              if (row.waitsBehind != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    tr.syOxWaitsBehind(_title(context, row.waitsBehind!)),
                    style: text.bodySmall!.copyWith(color: colors.textHint),
                  ),
                ),
              if (e.status != OutboxStatus.inflight)
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (rejected && !row.otherScope)
                      TextButton(
                        onPressed: () =>
                            bloc.add(OnPendingSyncRetryRow(e.mutationId)),
                        child: Text(tr.syOxRetry),
                      ),
                    TextButton(onPressed: discard, child: Text(tr.syOxDiscard)),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
