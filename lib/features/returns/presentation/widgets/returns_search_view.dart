import 'package:amana_pos/features/returns/presentation/bloc/returns_bloc.dart';
import 'package:amana_pos/features/sales_history/data/models/sale_history_item.dart';
import 'package:amana_pos/theme/app_colors.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/utilities/format.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:solar_icons/solar_icons.dart';

class ReturnsSearchView extends StatelessWidget {
  final TextEditingController controller;
  final ReturnsState state;
  const ReturnsSearchView({super.key, required this.controller, required this.state});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _SearchField(controller: controller),
        Expanded(child: _SearchResults(state: state)),
      ],
    );
  }
}

// ─── Search Field ────────────────────────────────────────────────────────────

class _SearchField extends StatefulWidget {
  final TextEditingController controller;
  const _SearchField({required this.controller});

  @override
  State<_SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<_SearchField> {
  final _focusNode = FocusNode();
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() => _isFocused = _focusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
      color: colors.surface,
      padding: const EdgeInsets.fromLTRB(
          AppDims.s4, AppDims.s3, AppDims.s4, AppDims.s3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              boxShadow: _isFocused
                  ? [
                BoxShadow(
                  color: AppColors.danger.withValues(alpha: 0.15),
                  blurRadius: 0,
                  spreadRadius: 2,
                ),
              ]
                  : [],
            ),
            child: TextField(
              controller: widget.controller,
              focusNode: _focusNode,
              autofocus: true,
              onChanged: (q) =>
                  context.read<ReturnsBloc>().add(ReturnsSearchChanged(q)),
              textAlignVertical: TextAlignVertical.center,
              textInputAction: TextInputAction.search,
              style: AppTextStyles.bs200(context),
              decoration: InputDecoration(
                filled: true,
                fillColor: colors.surfaceSoft,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: colors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: colors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(
                    color: AppColors.danger,
                    width: 1.5,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 13),
                hintText: 'Receipt number, amount...',
                hintStyle: AppTextStyles.bs200(context)
                    .copyWith(color: colors.textHint),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  size: 20,
                  color: _isFocused ? AppColors.danger : colors.textHint,
                ),
                prefixIconConstraints: const BoxConstraints(
                  minWidth: 46,
                  minHeight: 48,
                ),
                suffixIcon: ValueListenableBuilder<TextEditingValue>(
                  valueListenable: widget.controller,
                  builder: (_, value, __) {
                    if (value.text.isEmpty) return const SizedBox.shrink();
                    return GestureDetector(
                      onTap: () {
                        widget.controller.clear();
                        context
                            .read<ReturnsBloc>()
                            .add(const ReturnsSearchChanged(''));
                      },
                      child: Container(
                        margin: const EdgeInsets.all(10),
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: colors.surfaceSoft,
                          shape: BoxShape.circle,
                          border: Border.all(color: colors.border),
                        ),
                        child: Icon(
                          Icons.close_rounded,
                          size: 13,
                          color: colors.textSecondary,
                        ),
                      ),
                    );
                  },
                ),
                suffixIconConstraints: const BoxConstraints(
                  minWidth: 44,
                  minHeight: 48,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppDims.s2),
          Text(
            'Receipt number, amount, or customer name',
            style: AppTextStyles.bs300(context)
                .copyWith(color: colors.textHint),
          ),
        ],
      ),
    );
  }
}

// ─── Search Results ───────────────────────────────────────────────────────────

class _SearchResults extends StatelessWidget {
  final ReturnsState state;
  const _SearchResults({required this.state});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    if (state.searchStatus == ReturnsSearchStatus.idle) {
      return _EmptyState(
        icon: SolarIconsOutline.saleSquare,
        iconColor: AppColors.danger,
        iconBg: AppColors.dangerLight,
        title: 'Find a sale to return',
        subtitle: 'Enter a receipt number or amount above',
      );
    }

    if (state.searchStatus == ReturnsSearchStatus.loading) {
      return const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
              strokeWidth: 2.5, color: AppColors.danger),
        ),
      );
    }

    if (state.searchStatus == ReturnsSearchStatus.failure) {
      return _EmptyState(
        icon: Icons.error_outline_rounded,
        iconColor: AppColors.danger,
        iconBg: AppColors.dangerLight,
        title: 'Search failed',
        subtitle: state.errorMessage ?? 'Please try again',
      );
    }

    if (state.searchResults.isEmpty) {
      return _EmptyState(
        icon: Icons.search_off_rounded,
        iconColor: colors.textHint,
        iconBg: colors.surfaceSoft,
        title: 'No sales found',
        subtitle: 'Try a different receipt number or amount',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(
          horizontal: AppDims.s4, vertical: AppDims.s3),
      itemCount: state.searchResults.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppDims.s2),
      itemBuilder: (context, index) {
        final sale = state.searchResults[index];
        return _SaleResultTile(
          sale: sale,
          onTap: () =>
              context.read<ReturnsBloc>().add(ReturnsSaleSelected(sale)),
        );
      },
    );
  }
}

// ─── Empty State ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String subtitle;

  const _EmptyState({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.subtitle,
  });

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
              color: iconBg,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(icon, size: 36, color: iconColor),
          ),
          const SizedBox(height: AppDims.s3),
          Text(
            title,
            style: AppTextStyles.bs400(context)
                .copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppDims.s2),
          Text(
            subtitle,
            style: AppTextStyles.bs100(context)
                .copyWith(color: colors.textSecondary),
          ),
        ],
      ),
    );
  }
}

// ─── Sale Result Tile ─────────────────────────────────────────────────────────

class _SaleResultTile extends StatelessWidget {
  final SaleHistoryItem sale;
  final VoidCallback onTap;
  const _SaleResultTile({required this.sale, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final canReturn = sale.canBeReturned;

    return Opacity(
      opacity: canReturn ? 1.0 : 0.45,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: colors.border),
        ),
        child: Material(
          color: colors.surface,
          borderRadius: BorderRadius.circular(13),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: canReturn ? onTap : null,
            highlightColor: AppColors.dangerLight.withValues(alpha: 0.5),
            splashColor: AppColors.dangerLight.withValues(alpha: 0.3),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppDims.s4, vertical: AppDims.s3),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: canReturn
                          ? AppColors.dangerLight
                          : colors.surfaceSoft,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      canReturn
                          ? SolarIconsOutline.undoLeft
                          : Icons.block_rounded,
                      size: 20,
                      color: canReturn ? AppColors.danger : colors.textHint,
                    ),
                  ),
                  const SizedBox(width: AppDims.s3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          sale.displayRef,
                          style: AppTextStyles.bs100(context).copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: 12.5,
                            fontFamily: 'monospace',
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${DateFormat('d MMM · HH:mm').format(sale.createdAt)} · '
                              '${sale.paymentLabel} · '
                              '${sale.itemCount} item${sale.itemCount == 1 ? '' : 's'}',
                          style: AppTextStyles.sm100(context)
                              .copyWith(color: colors.textSecondary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (!canReturn) ...[
                          const SizedBox(height: 4),
                          Text(
                            sale.isOfflinePending
                                ? 'Pending sync — cannot return yet'
                                : 'Already ${sale.status.label.toLowerCase()}',
                            style: AppTextStyles.sm100(context)
                                .copyWith(color: colors.textHint),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: AppDims.s3),
                  Text(
                    AppFormat.moneyWithUnit(sale.total),
                    style: AppTextStyles.bs200(context).copyWith(
                      fontWeight: FontWeight.w800,
                      color: canReturn
                          ? AppColors.danger
                          : colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}