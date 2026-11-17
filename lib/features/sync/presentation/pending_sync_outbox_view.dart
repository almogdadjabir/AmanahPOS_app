import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/core/sync/outbox/outbox_entry.dart';
import 'package:amana_pos/features/sales_history/presentation/widgets/sale_format.dart';
import 'package:amana_pos/features/sync/presentation/bloc/pending_sync_bloc.dart';
import 'package:amana_pos/features/sync/presentation/widgets/catalog_editor.dart';
import 'package:amana_pos/features/sync/presentation/widgets/sync_badge.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/widgets/app_confirm_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Sync-engine-on body of the Pending Sync screen: every unsynced outbox row
/// (current scope and other scopes) with retry / discard, the conflict
/// actions of rejected catalog rows (edit and retry, merge into existing),
/// and the parked image uploads with retry.
class PendingSyncOutboxView extends StatelessWidget {
  final List<PendingSyncRow> rows;
  final List<PendingUploadRow> failedUploads;

  /// Opens an entity's edit form ("Edit and retry"); tests inject one.
  final CatalogEditorOpener editor;

  const PendingSyncOutboxView({
    super.key,
    required this.rows,
    this.failedUploads = const [],
    this.editor = openCatalogEditor,
  });

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
        for (final r in rows) _OutboxRow(row: r, editor: editor),
        for (final u in failedUploads) _UploadRow(upload: u),
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
  final CatalogEditorOpener editor;
  const _OutboxRow({required this.row, required this.editor});

  String _entity(BuildContext c) {
    final tr = c.tr;
    switch (row.entry.entity) {
      case 'sale':
        return tr.syOxEntitySale;
      case 'stock':
        return tr.syOxEntityStock;
      case 'inbound':
        return tr.syOxEntityInbound;
      case 'product':
        return tr.syOxEntityProduct;
      case 'category':
        return tr.syOxEntityCategory;
      case 'vendor':
        return tr.syOxEntityVendor;
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
      final body = isSale
          ? tr.syOxDiscardSaleBody
          : !row.isCatalog
          ? tr.syOxDiscardRowBody
          : e.op == 'create'
          ? tr.syOxDiscardCatalogCreateBody
          : tr.syOxDiscardCatalogEditBody;
      final choice = await showAppConfirmSheetChoice(
        context,
        title: isSale ? tr.syOxDiscardSaleTitle : tr.syOxDiscardRowTitle,
        message: maybeSent ? '$body ${tr.syOxDiscardMaybeOnServer}' : body,
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

    /// "Edit and retry": the normal edit form, then the edit is folded
    /// into the rejected row (only when something was saved).
    Future<void> editRetry() async {
      final messenger = ScaffoldMessenger.of(context);
      final target = await bloc.editTarget(row);
      if (target == null || !context.mounted) return;
      final json = target.json;
      if (json == null) {
        messenger.showSnackBar(SnackBar(content: Text(tr.syOxEditGone)));
        return;
      }
      await editor(context, e.entity, json);
      bloc.add(
        OnPendingSyncEditRetry(e.mutationId, editedAfterSeq: target.seq),
      );
    }

    /// Plain retry. A row naming an item that is gone from this phone is
    /// sent only after the user confirms (T5 I4): the server would record
    /// it without that link.
    Future<void> retry() async {
      if (row.missingDependency) {
        final ok = await showAppConfirmSheet(
          context,
          title: tr.syOxRetryMissingTitle,
          message: tr.syOxRetryMissingBody,
          confirmLabel: tr.syOxRetryMissingConfirm,
        );
        if (!ok) return;
      }
      bloc.add(OnPendingSyncRetryRow(e.mutationId));
    }

    /// "Merge into existing": a standard confirm with the affected counts
    /// and what happens to the copy (stock added, edits and photo dropped,
    /// M3) and to an inactive target (M2).
    Future<void> merge() async {
      final report = await bloc.previewMerge(row);
      if (!context.mounted) return;
      if (report == null) {
        // Refused (the row changed): the bloc reports it.
        bloc.add(OnPendingSyncMerge(e.mutationId));
        return;
      }
      final ok = await showAppConfirmSheet(
        context,
        title: tr.syOxMergeTitle,
        message: [
          tr.syOxMergeBody(row.conflictLabel ?? tr.syOxMergeExistingFallback),
          tr.syOxMergeCount(report.total),
          if (e.entity == 'product') tr.syOxMergeStockAdded,
          tr.syOxMergeEditsDropped,
          if (report.targetInactive) tr.syOxMergeTargetInactive,
        ].join(' '),
        confirmLabel: tr.syOxMerge,
      );
      if (ok) bloc.add(OnPendingSyncMerge(e.mutationId));
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
              if (row.missingDependency)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    tr.syOxRetryMissingHint,
                    style: text.bodySmall!.copyWith(color: colors.warning),
                  ),
                ),
              if (row.stale)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    tr.syOxStaleHint,
                    style: text.bodySmall!.copyWith(color: colors.textHint),
                  ),
                ),
              if (!row.otherScope && !row.canDiscard)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    tr.syOxDiscardBlockedByDependents(row.dependents),
                    style: text.bodySmall!.copyWith(color: colors.textHint),
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
                Wrap(
                  alignment: WrapAlignment.end,
                  children: [
                    if (row.canEditRetry)
                      TextButton(
                        key: ValueKey('pending-sync-edit-${e.mutationId}'),
                        onPressed: editRetry,
                        child: Text(tr.syOxEditRetry),
                      )
                    else if (rejected && !row.otherScope)
                      TextButton(
                        onPressed: retry,
                        child: Text(tr.syOxRetry),
                      ),
                    if (row.canMerge)
                      TextButton(
                        key: ValueKey('pending-sync-merge-${e.mutationId}'),
                        onPressed: merge,
                        child: Text(tr.syOxMerge),
                      ),
                    // Another account's rows: "Discard other account's
                    // changes" below (single-row discard is refused). A
                    // create others wait on: merge or edit instead (I3).
                    if (row.canDiscard)
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

/// A parked image upload (403 / 404 / 413 / unreadable file) with retry.
class _UploadRow extends StatelessWidget {
  final PendingUploadRow upload;
  const _UploadRow({required this.upload});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final text = Theme.of(context).textTheme;
    final tr = context.tr;
    final entity = upload.entity == 'category'
        ? tr.syOxEntityCategory
        : tr.syOxEntityProduct;
    final name = upload.label.isNotEmpty ? upload.label : upload.entityId;
    final error = upload.error?.trim() ?? '';
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
                      '$entity · $name',
                      style: text.titleSmall!.copyWith(
                        color: colors.textPrimary,
                      ),
                    ),
                  ),
                  Text(
                    tr.syOxUploadFailed,
                    style: text.labelMedium!.copyWith(color: colors.danger),
                  ),
                ],
              ),
              if (error.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    error,
                    style: text.bodySmall!.copyWith(color: colors.danger),
                  ),
                ),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: TextButton(
                  key: ValueKey(
                    'pending-sync-upload-retry-${upload.entity}-${upload.entityId}',
                  ),
                  onPressed: () => context.read<PendingSyncBloc>().add(
                    OnPendingSyncRetryUpload(upload.entity, upload.entityId),
                  ),
                  child: Text(tr.syOxRetry),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
