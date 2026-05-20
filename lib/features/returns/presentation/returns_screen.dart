import 'package:amana_pos/common/auth_bloc/auth_bloc.dart';
import 'package:amana_pos/features/returns/presentation/bloc/returns_bloc.dart';
import 'package:amana_pos/features/returns/presentation/widgets/item_selector_view.dart';
import 'package:amana_pos/features/returns/presentation/widgets/return_success_sheet.dart';
import 'package:amana_pos/features/returns/presentation/widgets/returns_search_view.dart';
import 'package:amana_pos/features/sales_history/data/models/sale_history_item.dart';
import 'package:amana_pos/theme/app_colors.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/utilities/format.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:solar_icons/solar_icons.dart';

class ReturnsScreen extends StatefulWidget {
  final SaleHistoryItem? preloadedSale;
  const ReturnsScreen({super.key, this.preloadedSale});

  @override
  State<ReturnsScreen> createState() => _ReturnsScreenState();
}

class _ReturnsScreenState extends State<ReturnsScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.preloadedSale != null) {
      context
          .read<ReturnsBloc>()
          .add(ReturnsPreloadSale(widget.preloadedSale!));
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSuccessShown(BuildContext context, ReturnsState state) {
    final businessName =
        context.read<AuthBloc>().state.defaultBusiness?.name ?? 'AmanaPOS';
    final originalRef = state.selectedSale?.displayRef ?? '';
    ReturnSuccessSheet.show(
      context,
      result: state.refundResult!,
      businessName: businessName,
      originalReceiptRef: originalRef,
    );
    context.read<ReturnsBloc>().add(const ReturnsReset());
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return BlocListener<ReturnsBloc, ReturnsState>(
      listenWhen: (prev, curr) =>
      prev.submitStatus != curr.submitStatus &&
          curr.submitStatus == ReturnsSubmitStatus.success,
      listener: (context, state) => _onSuccessShown(context, state),
      child: BlocBuilder<ReturnsBloc, ReturnsState>(
        builder: (context, state) {
          final hasSale = state.selectedSale != null;

          return Scaffold(
            backgroundColor: colors.background,
            appBar: AppBar(
              backgroundColor: colors.surface,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              titleSpacing: AppDims.s4,
              leading: GestureDetector(
                onTap: () {
                  if (hasSale) {
                    context.read<ReturnsBloc>().add(const ReturnsReset());
                  } else {
                    Navigator.of(context).pop();
                  }
                },
                child: Icon(Icons.arrow_back_ios,
                    size: 18, color: colors.textPrimary)
              ),
              leadingWidth: 58,
              title: hasSale
                  ? _SaleAppBarTitle(sale: state.selectedSale!)
                  : const _DefaultAppBarTitle(),
              // Only the action button in the appbar changes — replace the actions list:
              actions: hasSale
                  ? [
                GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    context
                        .read<ReturnsBloc>()
                        .add(const ReturnsAllToggled());
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: AppDims.s4),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: state.allSelected
                          ? AppColors.danger
                          : AppColors.dangerLight,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppColors.danger.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Text(
                      state.allSelected ? 'Deselect all' : 'Return all',
                      style: AppTextStyles.sm100(context).copyWith(
                        color: state.allSelected
                            ? Colors.white
                            : AppColors.danger,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ]
                  : null,
            ),
            body: hasSale
                ? ItemSelectorView(state: state)
                : ReturnsSearchView(
              controller: _searchCtrl,
              state: state,
            ),
          );
        },
      ),
    );
  }
}

class _DefaultAppBarTitle extends StatelessWidget {
  const _DefaultAppBarTitle();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: AppColors.danger,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            SolarIconsOutline.undoLeft,
            size: 18,
            color: Colors.white,
          ),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'AMANAPOS',
              style: AppTextStyles.sm100(context).copyWith(
                color: AppColors.danger,
                fontSize: 10,
                letterSpacing: 1.0,
                fontWeight: FontWeight.w700,
                height: 1,
              ),
            ),
            Text(
              'Process return',
              style: AppTextStyles.bs200(context).copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 17,
                height: 1.3,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SaleAppBarTitle extends StatelessWidget {
  final SaleHistoryItem sale;
  const _SaleAppBarTitle({required this.sale});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          sale.displayRef,
          style: AppTextStyles.bs200(context).copyWith(
            fontWeight: FontWeight.w900,
            fontFamily: 'monospace',
            fontSize: 13,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          '${DateFormat('d MMM yyyy').format(sale.createdAt)} · ${AppFormat.moneyWithUnit(sale.total)}',
          style: AppTextStyles.bs100(context).copyWith(
            color: colors.textSecondary,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}