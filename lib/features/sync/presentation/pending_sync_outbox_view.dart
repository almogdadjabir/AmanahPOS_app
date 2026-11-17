import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/core/sync/outbox/outbox_entry.dart';
import 'package:amana_pos/features/sales_history/presentation/widgets/sale_format.dart';
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
    final ownRejected = rows.any(
      (r) => !r.otherScope && r.entry.status == OutboxStatus.rejected,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SyncBadge(),
        const SizedBox(height: 12),
        if (ownRejected)
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: TextButton(
              key: const ValueKey('pending-sync-retry-all'),
              onPressed: () => context.read<PendingSyncBloc>().add(
                const OnPendingSyncRetryAll(),
              ),
              child: Text(tr.syOxRetryAll),
            ),
          ),
        for (final r in rows) _OutboxRow(row: r),
        for (final scope in otherScopes)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: TextButton(
              onPressed: () async {
                final bloc = context.read<PendingSyncBloc>();
                // Rows sent at least once may already be on the server.
                final maybeSent = rows.any(
                  (r) => r.entry.scope == scope && r.entry.attempts > 0,
                );
                final ok = await showAppConfirmSheet(
                  context,
                  title: tr.syOxDiscardOtherTitle,
                  message: maybeSent
                      ? '${tr.syOxDiscardOtherBody} '
                            '${tr.syOxDiscardOtherMaybeOnServer}'
                      : tr.syOxDiscardOtherBody,
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
    final total = r.total == null ? '' : ' · ${_money(c, r.total!)}';
    return '$name$total';
  }

  /// Same money format as the sales screens ("26,400 SDG"); an
  /// unparseable amount is shown as stored.
  static String _money(BuildContext c, String raw) {
    final v = num.tryParse(raw);
    return v == null ? raw : saleMoney(c, v);
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
      // Sent at least once (answer lost): the server may already have it.
      // Discard stays possible (no stuck rows), but "Send now" is offered:
      // a replay answers `duplicate` and the row becomes done.
      final maybeSent = e.attempts > 0;
      final choice = await showAppConfirmSheetChoice(
        context,
        title: isSale ? tr.syOxDiscardSaleTitle : tr.syOxDiscardRowTitle,
        message: maybeSent
            ? tr.syOxDiscardMaybeOnServer
            : (isSale ? tr.syOxDiscardSaleBody : tr.syOxDiscardRowBody),
        confirmLabel: tr.syOxDiscard,
        alternativeLabel: maybeSent ? tr.syOxSendNow : null,
      );
      switch (choice) {
        case AppConfirmChoice.confirm:
          bloc.add(OnPendingSyncDiscardRow(e.mutationId));
        case AppConfirmChoice.alternative:
          bloc.add(const OnPendingSyncSendNow());
        case AppConfirmChoice.cancel:
          break;
      }
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
                    // Another account's rows: "Discard other account's
                    // changes" below (single-row discard is refused).
                    if (!row.otherScope)
                      TextButton(
                        onPressed: discard,
                        child: Text(tr.syOxDiscard),
                      ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
