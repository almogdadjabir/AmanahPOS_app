import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/core/offline/presentation/bloc/offline_status_bloc.dart';
import 'package:amana_pos/features/category/presentation/widgets/category_states.dart';
import 'package:amana_pos/features/pos/data/model/offline/offline_sale_dto.dart';
import 'package:amana_pos/features/sales_history/presentation/widgets/sale_format.dart';
import 'package:amana_pos/features/sync/presentation/bloc/pending_sync_bloc.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/theme/phosphor_icons.dart';
import 'package:amana_pos/utilities/dependencies_provider.dart';
import 'package:amana_pos/widgets/app_button.dart';
import 'package:amana_pos/widgets/app_confirm_sheet.dart';
import 'package:amana_pos/widgets/app_large_title.dart';
import 'package:amana_pos/widgets/app_swipe_actions.dart';
import 'package:amana_pos/widgets/directional_icon.dart';
import 'package:amana_pos/widgets/pressable.dart';
import 'package:amana_pos/widgets/shimmer.dart';
import 'package:flutter/cupertino.dart' show CupertinoSliverRefreshControl;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class PendingSyncScreen extends StatefulWidget {
  const PendingSyncScreen({super.key});

  @override
  State<PendingSyncScreen> createState() => _PendingSyncScreenState();
}

class _PendingSyncScreenState extends State<PendingSyncScreen> {
  @override
  void initState() {
    super.initState();
    context.read<PendingSyncBloc>().add(const OnPendingSyncLoad());
  }

  Future<void> _refresh() async {
    final bloc = context.read<PendingSyncBloc>();
    bloc.add(const OnPendingSyncLoad());
    try {
      await bloc.stream
          .firstWhere(
            (s) =>
                s.status == PendingSyncStatus.loaded ||
                s.status == PendingSyncStatus.error,
          )
          .timeout(const Duration(seconds: 10));
    } catch (_) {
      // Timed out: let the control settle.
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom + 24;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const _NavBar(),
            Expanded(
              child: BlocBuilder<PendingSyncBloc, PendingSyncState>(
                builder: (context, state) => CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  slivers: [
                    CupertinoSliverRefreshControl(onRefresh: _refresh),
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(
                        AppDims.s4,
                        0,
                        AppDims.s4,
                        bottomInset,
                      ),
                      sliver: SliverToBoxAdapter(child: _content(state)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _content(PendingSyncState state) {
    final tr = context.tr;
    final title = AppLargeTitle(title: tr.syTitle);

    if (state.isLoading || state.status == PendingSyncStatus.initial) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [title, const _HeaderSkeleton()],
      );
    }

    if (state.status == PendingSyncStatus.error && state.sales.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          title,
          CategoryStateCard(
            icon: PhosphorIconsRegular.wifiSlash,
            tone: CategoryStateTone.danger,
            title: tr.somethingWentWrong,
            body: tr.nfErrorBody,
            actionLabel: tr.retry,
            secondaryAction: true,
            onAction: () =>
                context.read<PendingSyncBloc>().add(const OnPendingSyncLoad()),
          ),
        ],
      );
    }

    return BlocBuilder<OfflineStatusBloc, OfflineStatusState>(
      bloc: getIt<OfflineStatusBloc>(),
      buildWhen: (p, c) =>
          p.connectionStatus != c.connectionStatus ||
          p.lastSalesSyncAt != c.lastSalesSyncAt,
      builder: (context, offline) {
        final sales = state.sales;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            title,
            if (offline.isOffline && sales.isNotEmpty) ...[
              _OfflineBanner(text: tr.syOffline),
              const SizedBox(height: 12),
            ],
            _Header(
              count: sales.length,
              syncing: state.isSyncing,
              offline: offline.isOffline,
              lastSyncedAt: offline.lastSalesSyncAt,
            ),
            if (sales.isNotEmpty) ...[
              _SectionLabel(tr.syWaitingHeader),
              _SalesGroup(sales: sales),
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(20, 8, 20, 0),
                child: Text(
                  tr.syFoot,
                  style: Theme.of(context).textTheme.bodySmall!.copyWith(
                    fontSize: 13,
                    height: 18 / 13,
                    color: context.appColors.textHint,
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _NavBar extends StatelessWidget {
  const _NavBar();

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return SizedBox(
      height: 44,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: [
            Pressable(
              onTap: () => Navigator.of(context).maybePop(),
              child: SizedBox(
                height: 44,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(width: 4),
                    DirectionalIcon(
                      icon: PhosphorIconsRegular.caretLeft,
                      size: 24,
                      color: colors.primary,
                    ),
                    Text(
                      context.tr.back,
                      style: TextStyle(fontSize: 17, color: colors.primary),
                    ),
                    const SizedBox(width: 8),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

BoxDecoration _cardDecoration(AppThemeColors colors) => BoxDecoration(
  color: colors.surface,
  borderRadius: AppDims.borderLg,
  border: Border.all(color: colors.border),
);

class _OfflineBanner extends StatelessWidget {
  final String text;
  const _OfflineBanner({required this.text});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.warningContainer,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 1),
              child: Icon(
                PhosphorIconsRegular.wifiSlash,
                size: 20,
                color: colors.warning,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 15,
                  height: 20 / 15,
                  color: colors.warning,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final int count;
  final bool syncing;
  final bool offline;
  final DateTime? lastSyncedAt;

  const _Header({
    required this.count,
    required this.syncing,
    required this.offline,
    required this.lastSyncedAt,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final text = Theme.of(context).textTheme;
    final tr = context.tr;
    final clear = count == 0;

    final last = Text(
      lastSyncedAt != null
          ? tr.syLastSynced(saleWhen(context, lastSyncedAt!))
          : tr.syNeverSynced,
      textAlign: TextAlign.center,
      style: text.bodySmall!.copyWith(fontSize: 13, color: colors.textHint),
    );

    return DecoratedBox(
      decoration: _cardDecoration(colors),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
        child: clear
            ? Column(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: colors.successContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      PhosphorIconsRegular.check,
                      size: 32,
                      color: colors.success,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    tr.syAllDoneTitle,
                    textAlign: TextAlign.center,
                    style: text.titleLarge!.copyWith(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    tr.syAllDoneBody,
                    textAlign: TextAlign.center,
                    style: text.bodyMedium!.copyWith(
                      fontSize: 15,
                      color: colors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  last,
                ],
              )
            : Column(
                children: [
                  Text(
                    '$count',
                    style: text.displayLarge!.copyWith(
                      fontSize: 56,
                      height: 58 / 56,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -1.7,
                      color: colors.textPrimary,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  Text(
                    tr.syWaitingLabel(count),
                    style: text.bodyMedium!.copyWith(
                      fontSize: 15,
                      color: colors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 14),
                  AppButton(
                    label: syncing ? tr.sySyncing : tr.sySyncNow,
                    width: double.infinity,
                    isLoading: syncing,
                    prefixIcon: syncing
                        ? null
                        : const Icon(
                            PhosphorIconsRegular.arrowsClockwise,
                            size: 20,
                          ),
                    onPressed: (syncing || offline)
                        ? null
                        : () {
                            HapticFeedback.selectionClick();
                            context.read<PendingSyncBloc>().add(
                              const OnPendingSyncRetryAll(),
                            );
                          },
                  ),
                  const SizedBox(height: 10),
                  last,
                ],
              ),
      ),
    );
  }
}

class _HeaderSkeleton extends StatelessWidget {
  const _HeaderSkeleton();

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return AppSkeleton(
      child: DecoratedBox(
        decoration: _cardDecoration(colors),
        child: const Padding(
          padding: EdgeInsets.fromLTRB(16, 18, 16, 16),
          child: Column(
            children: [
              Shimmer(width: 80, height: 50, radius: 10),
              SizedBox(height: 10),
              Shimmer(width: 150, height: 14, radius: 6),
              SizedBox(height: 16),
              Shimmer(width: double.infinity, height: 48, radius: 12),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel(this.label);

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(20, 22, 20, 7),
      child: Text(
        label,
        style: Theme.of(
          context,
        ).textTheme.labelLarge!.copyWith(color: colors.textHint),
      ),
    );
  }
}

class _SalesGroup extends StatefulWidget {
  final List<OfflineSaleDto> sales;
  const _SalesGroup({required this.sales});

  @override
  State<_SalesGroup> createState() => _SalesGroupState();
}

class _SalesGroupState extends State<_SalesGroup> {
  final Set<String> _open = {};

  Future<void> _delete(OfflineSaleDto sale) async {
    final tr = context.tr;
    final bloc = context.read<PendingSyncBloc>();
    final ok = await showAppConfirmSheet(
      context,
      title: tr.syDeleteTitle,
      message: tr.syDeleteBody,
      confirmLabel: tr.syDeleteAction,
    );
    if (ok) bloc.add(OnPendingSyncDeleteSale(sale.clientSaleId));
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final tr = context.tr;
    final sales = widget.sales;

    return DecoratedBox(
      decoration: _cardDecoration(colors),
      child: ClipRRect(
        borderRadius: AppDims.borderLg,
        child: Column(
          children: [
            for (var i = 0; i < sales.length; i++) ...[
              if (i > 0)
                Divider(
                  height: 0.5,
                  thickness: 0.5,
                  indent: AppDims.s4 + 44 + AppDims.s3,
                  color: colors.border,
                ),
              AppSwipeActions(
                key: ValueKey(sales[i].clientSaleId),
                actions: [
                  if (sales[i].status == 'failed')
                    AppSwipeAction(
                      label: tr.sySwipeRetry,
                      icon: PhosphorIconsRegular.arrowsClockwise,
                      color: colors.primary,
                      onTap: () => context.read<PendingSyncBloc>().add(
                        const OnPendingSyncRetryAll(),
                      ),
                    ),
                  AppSwipeAction(
                    label: tr.sySwipeDelete,
                    icon: PhosphorIconsRegular.trash,
                    color: colors.danger,
                    onTap: () => _delete(sales[i]),
                  ),
                ],
                child: _SaleRow(
                  sale: sales[i],
                  expanded: _open.contains(sales[i].clientSaleId),
                  onTap: () => setState(() {
                    final id = sales[i].clientSaleId;
                    if (!_open.remove(id)) _open.add(id);
                  }),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SaleRow extends StatelessWidget {
  final OfflineSaleDto sale;
  final bool expanded;
  final VoidCallback onTap;

  const _SaleRow({
    required this.sale,
    required this.expanded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final text = Theme.of(context).textTheme;
    final tr = context.tr;
    final failed = sale.status == 'failed';
    final id = sale.clientSaleId;
    final short = (id.length > 8 ? id.substring(0, 8) : id).toUpperCase();
    final reason = sale.errorMessage?.trim().isNotEmpty == true
        ? sale.errorMessage!.trim()
        : tr.syFailedFallback;
    final total = double.tryParse(sale.total) ?? 0;

    return Column(
      children: [
        Pressable(
          onTap: onTap,
          scale: 1,
          child: ColoredBox(
            color: colors.surface,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 60),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDims.s4,
                  vertical: AppDims.s2,
                ),
                child: Row(
                  children: [
                    SalePaymentTile(method: sale.paymentMethod),
                    const SizedBox(width: AppDims.s3),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '\u2066#$short\u2069 · ${tr.syItemsCount(sale.items.length)}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: text.bodyLarge!.copyWith(
                              fontSize: 17,
                              fontWeight: FontWeight.w500,
                              color: colors.textPrimary,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 1),
                            child: Text(
                              failed
                                  ? reason
                                  : saleWhen(context, sale.createdAt),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: text.bodySmall!.copyWith(
                                fontSize: 13,
                                color: failed ? colors.danger : colors.textHint,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppDims.s2),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Directionality(
                          textDirection: TextDirection.ltr,
                          child: Text(
                            saleNumber(total),
                            style: text.bodyLarge!.copyWith(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                              color: colors.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 3),
                        _StatusPill(failed: failed),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (expanded)
          ColoredBox(
            color: colors.surfaceSoft,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDims.s4,
                vertical: 10,
              ),
              child: Column(
                children: [
                  for (final item in sale.items)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${item.productName} × ${saleQty(item.quantity)}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: text.bodyMedium!.copyWith(
                                fontSize: 14,
                                color: colors.textSecondary,
                              ),
                            ),
                          ),
                          Directionality(
                            textDirection: TextDirection.ltr,
                            child: Text(
                              saleNumber(double.tryParse(item.lineTotal) ?? 0),
                              style: text.bodyMedium!.copyWith(
                                fontSize: 14,
                                color: colors.textSecondary,
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  final bool failed;
  const _StatusPill({required this.failed});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final tr = context.tr;
    final (bg, fg) = failed
        ? (colors.dangerContainer, colors.danger)
        : (colors.warningContainer, colors.warning);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        child: Text(
          failed ? tr.syPillFailed : tr.syPillWaiting,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: fg,
          ),
        ),
      ),
    );
  }
}
