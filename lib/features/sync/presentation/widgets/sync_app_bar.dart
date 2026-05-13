import 'package:amana_pos/features/pos/data/model/offline/offline_sale_dto.dart';
import 'package:amana_pos/features/sync/presentation/bloc/pending_sync_bloc.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SyncAppBar extends StatelessWidget {
  final PendingSyncState state;
  const SyncAppBar({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final count = state.sales.length;
    final total = _totalAmount(state.sales);
    final hasPending = count > 0;
    final isSyncing = state.isSyncing;

    return SliverAppBar(
      expandedHeight: hasPending ? 148 : 100,
      pinned: true,
      elevation: 0,
      scrolledUnderElevation: 1,
      backgroundColor: colors.surface,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        onPressed: () => Navigator.of(context).pop(),
        icon: Icon(Icons.arrow_back_rounded, color: colors.textPrimary),
      ),
      title: Text(
        'Sync management',
        style: AppTextStyles.sm300(context).copyWith(
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
      ),
      actions: [
        if (hasPending)
          Padding(
            padding: const EdgeInsets.only(right: AppDims.s3),
            child: BlocBuilder<PendingSyncBloc, PendingSyncState>(
              buildWhen: (p, c) => p.isSyncing != c.isSyncing,
              builder: (context, s) => FilledButton.icon(
                onPressed: s.isSyncing
                    ? null
                    : () => context
                    .read<PendingSyncBloc>()
                    .add(const OnPendingSyncRetryAll()),
                style: FilledButton.styleFrom(
                  backgroundColor: colors.primary,
                  disabledBackgroundColor: colors.primary.withValues(alpha: 0.5),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppDims.rMd),
                  ),
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppDims.s3, vertical: 0),
                  minimumSize: const Size(0, 36),
                ),
                icon: s.isSyncing
                    ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
                    : const Icon(Icons.sync_rounded, size: 16),
                label: Text(
                  s.isSyncing ? 'Syncing…' : 'Sync All',
                  style: AppTextStyles.sm300(context).copyWith(
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
                AppDims.s4, 60, AppDims.s4, AppDims.s3),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'Pending Sync',
                  style: AppTextStyles.bs500(context).copyWith(
                    fontWeight: FontWeight.w900,
                    color: colors.textPrimary,
                  ),
                ),
                if (hasPending) ...[
                  const SizedBox(height: 6),
                  headerBanner(
                    context: context,
                    count: count,
                    total: total,
                    isSyncing: isSyncing,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  double _totalAmount(List<OfflineSaleDto> sales) {
    return sales.fold(0.0, (sum, s) => sum + (double.tryParse(s.total) ?? 0));
  }


  Widget headerBanner({
    required BuildContext context,
    required int count,
    required double total,
    required bool isSyncing,
}){
    const amber = Color(0xFFF59E0B);
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppDims.s3, vertical: AppDims.s2),
      decoration: BoxDecoration(
        color: amber.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppDims.rMd),
        border: Border.all(color: amber.withValues(alpha: 0.30)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, size: 16, color: amber),
          const SizedBox(width: AppDims.s2),
          Expanded(
            child: Text(
              '$count ${count == 1 ? 'sale' : 'sales'} not yet synced',
              style: AppTextStyles.sm200(context).copyWith(
                fontWeight: FontWeight.w700,
                color: amber,
              ),
            ),
          ),
          Text(
            total.toStringAsFixed(2),
            style: AppTextStyles.sm300(context).copyWith(
              fontWeight: FontWeight.w900,
              color: amber,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
