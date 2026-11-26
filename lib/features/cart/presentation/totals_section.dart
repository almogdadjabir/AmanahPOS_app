import 'package:amana_pos/core/permissions/discount_access.dart';
import 'package:amana_pos/features/approval/presentation/owner_approval_sheet.dart';
import 'package:amana_pos/common/auth_bloc/auth_bloc.dart';
import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/core/features/business_features.dart';
import 'package:amana_pos/features/cart/presentation/discount_sheet.dart';
import 'package:amana_pos/features/cart/presentation/total_row.dart';
import 'package:amana_pos/features/pos/domain/cart_discount.dart';
import 'package:amana_pos/features/pos/presentation/bloc/pos_bloc.dart';
import 'package:amana_pos/features/pos/presentation/pos_screen.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/utilities/dependencies_provider.dart';
import 'package:amana_pos/widgets/pressable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class TotalsSection extends StatelessWidget {
  const TotalsSection({
    super.key,
    required this.state,
    this.padding = const EdgeInsetsDirectional.fromSTEB(
      AppDims.s4,
      AppDims.s3,
      AppDims.s4,
      0,
    ),
  });

  final PosState state;
  final EdgeInsetsGeometry padding;

  DiscountAccess _access(BuildContext context, BusinessFeatures? f) =>
      discountAccess(
        context.read<AuthBloc>().state.permissions,
        f ?? getIt<BusinessFeaturesService>().current,
      );

  /// A cashier in "owner PIN" mode needs the owner first.
  Future<bool> _allowed(BuildContext context) async {
    if (_access(context, null) != DiscountAccess.approval) return true;
    return ensureOwnerApproval(context, what: context.tr.oaWhatDiscount);
  }

  Future<void> _openSaleDiscount(BuildContext context) async {
    final tr = context.tr;
    final bloc = context.read<PosBloc>();
    if (!await _allowed(context) || !context.mounted) return;
    final r = await showDiscountSheet(
      context,
      title: tr.dcSaleTitle,
      baseCents: BigInt.from((state.subtotal * 100).round()),
      initial: state.saleDiscount,
    );
    if (r == null) return;
    bloc.add(PosSaleDiscountSet(r.discount));
  }

  @override
  Widget build(BuildContext context) {
    final features = getIt<BusinessFeaturesService>();
    return StreamBuilder<BusinessFeatures>(
      stream: features.changes,
      initialData: features.current,
      builder: (context, snap) => _build(
        context,
        (snap.data?.saleDiscount ?? true) &&
            _access(context, snap.data) != DiscountAccess.none,
      ),
    );
  }

  Widget _build(BuildContext context, bool canDiscount) {
    final colors = context.appColors;
    final tr = context.tr;
    final taxed = state.taxConfig.isActive && state.taxAmount > 0;
    final lineDisc = state.lineDiscountTotal;
    final saleDisc = state.saleDiscountAmount;
    final hasDiscounts = lineDisc > 0 || saleDisc > 0;

    final saleLabel = state.saleDiscount?.kind == DiscountKind.percent
        ? '${tr.dcSaleDiscount} −${state.saleDiscount!.value}%'
        : tr.dcSaleDiscount;

    final discountRows = <Widget>[
      if (lineDisc > 0) ...[
        const SizedBox(height: AppDims.s1),
        TotalRow(label: tr.dcLineDiscounts, value: '−${money(lineDisc)}'),
      ],
      if (saleDisc > 0) ...[
        const SizedBox(height: AppDims.s1),
        Pressable(
          onTap: canDiscount ? () => _openSaleDiscount(context) : null,
          child: TotalRow(label: saleLabel, value: '−${money(saleDisc)}'),
        ),
      ],
      if (canDiscount && saleDisc <= 0 && state.items.isNotEmpty) ...[
        const SizedBox(height: AppDims.s1),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: Pressable(
            onTap: () => _openSaleDiscount(context),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(
                tr.dcAddDiscount,
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  color: colors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ],
    ];

    return RepaintBoundary(
      child: Padding(
        padding: padding,
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: colors.border)),
          ),
          child: Padding(
            padding: const EdgeInsetsDirectional.only(top: AppDims.s3),
            child: Column(
              children: [
                if (taxed && !state.taxConfig.inclusive) ...[
                  TotalRow(
                    label: tr.subtotal,
                    value: money(state.grossSubtotal),
                  ),
                  ...discountRows,
                  const SizedBox(height: AppDims.s1),
                  TotalRow(
                    label: tr.taxWithRate(
                      state.taxConfig.name,
                      state.taxConfig.rateLabel,
                    ),
                    value: money(state.taxAmount),
                  ),
                  const SizedBox(height: AppDims.s2),
                  TotalRow(
                    label: tr.total,
                    value: money(state.total),
                    isTotal: true,
                  ),
                ] else if (taxed) ...[
                  if (hasDiscounts || canDiscount) ...[
                    TotalRow(
                      label: tr.subtotal,
                      value: money(state.grossSubtotal),
                    ),
                    ...discountRows,
                    const SizedBox(height: AppDims.s2),
                  ],
                  TotalRow(
                    label: tr.totalInclTax(
                      state.taxConfig.name,
                      state.taxConfig.rateLabel,
                    ),
                    value: money(state.total),
                    isTotal: true,
                  ),
                  const SizedBox(height: AppDims.s2),
                  TotalRow(label: tr.taxIncluded, value: money(state.taxAmount)),
                ] else ...[
                  TotalRow(
                    label: tr.subtotal,
                    value: money(state.grossSubtotal),
                  ),
                  ...discountRows,
                  const SizedBox(height: AppDims.s2),
                  TotalRow(
                    label: tr.total,
                    value: money(state.total),
                    isTotal: true,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
