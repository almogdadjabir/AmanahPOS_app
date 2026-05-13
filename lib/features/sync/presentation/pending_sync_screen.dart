import 'package:amana_pos/features/pos/data/model/offline/offline_sale_dto.dart';
import 'package:amana_pos/features/sync/presentation/bloc/pending_sync_bloc.dart';
import 'package:amana_pos/features/sync/presentation/widgets/sync_app_bar.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

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

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Scaffold(
      backgroundColor: colors.background,
      body: BlocBuilder<PendingSyncBloc, PendingSyncState>(
        builder: (context, state) {
          return NestedScrollView(
            headerSliverBuilder: (context, _) => [
              SyncAppBar(state: state),
            ],
            body: _buildBody(context, state),
          );
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, PendingSyncState state) {
    if (state.isLoading) return const _LoadingView();

    if (state.status == PendingSyncStatus.error && state.sales.isEmpty) {
      return _ErrorView(
        message: state.errorMessage ?? 'Failed to load pending sales.',
        onRetry: () =>
            context.read<PendingSyncBloc>().add(const OnPendingSyncLoad()),
      );
    }

    if (state.sales.isEmpty) return const _EmptyView();

    return RefreshIndicator(
      color: context.appColors.primary,
      onRefresh: () async =>
          context.read<PendingSyncBloc>().add(const OnPendingSyncLoad()),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(
            AppDims.s4, AppDims.s3, AppDims.s4, 120),
        itemCount: state.sales.length,
        itemBuilder: (context, i) => _SaleCard(
          sale: state.sales[i],
          index: i,
          isSyncing: state.isSyncing,
        ),
      ),
    );
  }
}

class _SaleCard extends StatefulWidget {
  final OfflineSaleDto sale;
  final int index;
  final bool isSyncing;

  const _SaleCard({
    required this.sale,
    required this.index,
    required this.isSyncing,
  });

  @override
  State<_SaleCard> createState() => _SaleCardState();
}

class _SaleCardState extends State<_SaleCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final sale = widget.sale;
    final statusInfo = _statusInfo(sale.status);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppDims.s3),
      child: Container(
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(AppDims.rLg),
          border: Border.all(color: colors.border.withValues(alpha: 0.6)),
        ),
        clipBehavior: Clip.hardEdge,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Left status border
              Container(
                width: 4,
                color: statusInfo.color,
              ),

              // Card content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header row
                    InkWell(
                      onTap: () => setState(() => _expanded = !_expanded),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                            AppDims.s3, AppDims.s3, AppDims.s3, AppDims.s3),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                _StatusChip(statusInfo: statusInfo),
                                const Spacer(),
                                Text(
                                  _relativeTime(sale.createdAt),
                                  style: AppTextStyles.sm200(context).copyWith(
                                    color: colors.textHint,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: AppDims.s2),
                                Icon(
                                  _expanded
                                      ? Icons.keyboard_arrow_up_rounded
                                      : Icons.keyboard_arrow_down_rounded,
                                  size: 18,
                                  color: colors.textHint,
                                ),
                              ],
                            ),
                            const SizedBox(height: AppDims.s2),

                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '#${sale.clientSaleId.length > 8 ? sale.clientSaleId.substring(0, 8).toUpperCase() : sale.clientSaleId.toUpperCase()}',
                                        style: AppTextStyles.sm200(context)
                                            .copyWith(
                                          fontWeight: FontWeight.w800,
                                          color: colors.textSecondary,
                                          fontFeatures: const [
                                            FontFeature.tabularFigures()
                                          ],
                                          letterSpacing: 1.0,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Row(
                                        children: [
                                          _PaymentChip(
                                              method: sale.paymentMethod),
                                          const SizedBox(width: AppDims.s2),
                                          Text(
                                            '${sale.items.length} ${sale.items.length == 1 ? 'item' : 'items'}',
                                            style:
                                                AppTextStyles.sm200(context).copyWith(
                                              color: colors.textHint,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  double.tryParse(sale.total)
                                          ?.toStringAsFixed(2) ??
                                      sale.total,
                                  style: AppTextStyles.bs300(context).copyWith(
                                    fontWeight: FontWeight.w900,
                                    color: colors.textPrimary,
                                    fontFeatures: const [
                                      FontFeature.tabularFigures()
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Error message + delete button for failed sales
                    if (sale.status == 'failed') ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                            AppDims.s3, 0, AppDims.s3, 0),
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(
                              AppDims.s3, AppDims.s2, AppDims.s2, AppDims.s2),
                          decoration: BoxDecoration(
                            color: colors.dangerContainer,
                            borderRadius: BorderRadius.circular(AppDims.rSm),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(top: 1),
                                child: Icon(Icons.error_outline_rounded,
                                    size: 14, color: colors.danger),
                              ),
                              const SizedBox(width: AppDims.s2),
                              Expanded(
                                child: Text(
                                  sale.errorMessage ??
                                      'This sale failed to sync.',
                                  style: AppTextStyles.sm200(context).copyWith(
                                    color: colors.danger,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: AppDims.s2),
                              GestureDetector(
                                onTap: () => _confirmDelete(context, sale),
                                child: Tooltip(
                                  message: 'Discard this sale',
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: colors.danger
                                          .withValues(alpha: 0.12),
                                      borderRadius:
                                          BorderRadius.circular(AppDims.rSm),
                                    ),
                                    child: Icon(Icons.delete_outline_rounded,
                                        size: 16, color: colors.danger),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: AppDims.s3),
                    ],

                    // Expanded items
                    if (_expanded) ...[
                      Divider(
                          height: 1,
                          thickness: 0.5,
                          color: colors.border.withValues(alpha: 0.6),
                          indent: AppDims.s3),
                      ..._buildItems(context, sale),
                      _buildTotalsRow(context, sale),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      )
          .animate(delay: Duration(milliseconds: widget.index * 50))
          .fadeIn(duration: 280.ms)
          .slideY(begin: 0.04, end: 0, curve: Curves.easeOutCubic),
    );
  }

  List<Widget> _buildItems(BuildContext context, OfflineSaleDto sale) {
    final colors = context.appColors;
    return sale.items.map((item) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(
            AppDims.s3, AppDims.s2, AppDims.s3, 0),
        child: Row(
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: colors.textHint,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: AppDims.s2),
            Expanded(
              child: Text(
                item.productName,
                style: AppTextStyles.sm300(context).copyWith(
                  color: colors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: AppDims.s2),
            Text(
              '×${item.quantity % 1 == 0 ? item.quantity.toInt() : item.quantity}',
              style: AppTextStyles.sm200(context).copyWith(
                color: colors.textHint,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: AppDims.s3),
            Text(
              double.tryParse(item.lineTotal)?.toStringAsFixed(2) ??
                  item.lineTotal,
              style: AppTextStyles.sm300(context).copyWith(
                color: colors.textPrimary,
                fontWeight: FontWeight.w800,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  Widget _buildTotalsRow(BuildContext context, OfflineSaleDto sale) {
    final colors = context.appColors;
    final discount = double.tryParse(sale.discountAmount) ?? 0;
    final tax = double.tryParse(sale.taxAmount) ?? 0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppDims.s3, AppDims.s3, AppDims.s3, AppDims.s3),
      child: Column(
        children: [
          Divider(
              height: 1,
              thickness: 0.5,
              color: colors.border.withValues(alpha: 0.6)),
          const SizedBox(height: AppDims.s2),
          if (discount > 0)
            _TotalLine(
                label: 'Discount',
                value: '-${discount.toStringAsFixed(2)}',
                color: colors.success,
                context: context),
          if (tax > 0)
            _TotalLine(
                label: 'Tax',
                value: tax.toStringAsFixed(2),
                color: colors.textSecondary,
                context: context),
          _TotalLine(
              label: 'Total',
              value: double.tryParse(sale.total)?.toStringAsFixed(2) ??
                  sale.total,
              color: colors.textPrimary,
              bold: true,
              context: context),
        ],
      ),
    );
  }

  _StatusInfo _statusInfo(String? status) {
    switch (status) {
      case 'failed':
        return _StatusInfo(
          label: 'Failed',
          color: const Color(0xFFEF4444),
          icon: Icons.error_outline_rounded,
        );
      case 'syncing':
        return _StatusInfo(
          label: 'Syncing',
          color: const Color(0xFF2563EB),
          icon: Icons.sync_rounded,
        );
      default:
        return _StatusInfo(
          label: 'Pending',
          color: const Color(0xFFF59E0B),
          icon: Icons.schedule_rounded,
        );
    }
  }

  Future<void> _confirmDelete(
      BuildContext context, OfflineSaleDto sale) async {
    final colors = context.appColors;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.surface,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDims.rXl)),
        title: Text(
          'Discard this sale?',
          style: AppTextStyles.bs300(context).copyWith(
            fontWeight: FontWeight.w900,
            color: colors.textPrimary,
          ),
        ),
        content: Text(
          'This sale failed to sync and cannot be recovered. '
          'It will be permanently deleted and will NOT be sent to the server.',
          style: AppTextStyles.sm300(context).copyWith(
            color: colors.textSecondary,
            fontWeight: FontWeight.w600,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Cancel',
                style: AppTextStyles.bs100(context)
                    .copyWith(color: colors.textSecondary)),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: colors.danger,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDims.rMd)),
            ),
            child: Text('Discard',
                style: AppTextStyles.bs100(context)
                    .copyWith(color: Colors.white, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      context
          .read<PendingSyncBloc>()
          .add(OnPendingSyncDeleteSale(sale.clientSaleId));
    }
  }

  String _relativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt.toLocal());
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return DateFormat('MMM d, HH:mm').format(dt.toLocal());
  }
}

class _TotalLine extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool bold;
  final BuildContext context;

  const _TotalLine({
    required this.label,
    required this.value,
    required this.color,
    required this.context,
    this.bold = false,
  });

  @override
  Widget build(BuildContext _) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text(
            label,
            style: AppTextStyles.sm300(context).copyWith(
              color: context.appColors.textHint,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: AppTextStyles.sm300(context).copyWith(
              color: color,
              fontWeight: bold ? FontWeight.w900 : FontWeight.w700,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Status + Payment chips ──────────────────────────────────────────────────

class _StatusInfo {
  final String label;
  final Color color;
  final IconData icon;
  const _StatusInfo(
      {required this.label, required this.color, required this.icon});
}

class _StatusChip extends StatelessWidget {
  final _StatusInfo statusInfo;
  const _StatusChip({required this.statusInfo});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: statusInfo.color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: statusInfo.color.withValues(alpha: 0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(statusInfo.icon, size: 12, color: statusInfo.color),
          const SizedBox(width: 4),
          Text(
            statusInfo.label,
            style: AppTextStyles.sm200(context).copyWith(
              fontWeight: FontWeight.w800,
              color: statusInfo.color,
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentChip extends StatelessWidget {
  final String method;
  const _PaymentChip({required this.method});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final label = method.toLowerCase() == 'cash' ? 'Cash' : 'Card';
    final icon = method.toLowerCase() == 'cash'
        ? Icons.payments_outlined
        : Icons.credit_card_rounded;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: colors.surfaceSoft,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: colors.textHint),
          const SizedBox(width: 3),
          Text(
            label,
            style: AppTextStyles.sm200(context).copyWith(
              fontWeight: FontWeight.w700,
              color: colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Empty / Loading / Error states ──────────────────────────────────────────

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: colors.successContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.check_circle_outline_rounded,
                size: 36, color: colors.success),
          ),
          const SizedBox(height: AppDims.s4),
          Text(
            'All synced!',
            style: AppTextStyles.bs300(context).copyWith(
              fontWeight: FontWeight.w900,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: AppDims.s2),
          Text(
            'No pending sales waiting to sync.',
            style: AppTextStyles.bs100(context).copyWith(
              color: colors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ).animate().fadeIn(duration: 360.ms).scale(
            begin: const Offset(0.92, 0.92),
            end: const Offset(1, 1),
            curve: Curves.easeOutBack,
          ),
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return ListView.builder(
      padding:
          const EdgeInsets.fromLTRB(AppDims.s4, AppDims.s3, AppDims.s4, 0),
      itemCount: 4,
      itemBuilder: (_, i) => Padding(
        padding: const EdgeInsets.only(bottom: AppDims.s3),
        child: Container(
          height: 110,
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(AppDims.rLg),
            border: Border.all(color: colors.border.withValues(alpha: 0.4)),
          ),
        )
            .animate(onPlay: (c) => c.repeat())
            .shimmer(duration: 1200.ms, color: colors.border.withValues(alpha: 0.3)),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDims.s6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_rounded, size: 48, color: colors.textHint),
            const SizedBox(height: AppDims.s4),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTextStyles.bs100(context).copyWith(
                color: colors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppDims.s4),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Try again'),
              style: FilledButton.styleFrom(
                backgroundColor: colors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDims.rMd),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
