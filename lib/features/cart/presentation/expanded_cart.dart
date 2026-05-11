import 'package:amana_pos/features/cart/presentation/cart_line.dart';
import 'package:amana_pos/features/cart/presentation/payment_selector.dart';
import 'package:amana_pos/features/cart/presentation/totals_section.dart';
import 'package:amana_pos/features/pos/presentation/bloc/pos_bloc.dart';
import 'package:amana_pos/features/pos/presentation/pos_screen.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ExpandedCart extends StatelessWidget {
  final VoidCallback onCollapse;
  final VoidCallback onCheckout;

  const ExpandedCart({
    super.key,
    required this.onCollapse,
    required this.onCheckout,
  });

  Future<void> _confirmClearCart(BuildContext context) async {
    final colors = context.appColors;

    final shouldClear = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDims.rXl),
        ),
        title: Text(
          'Clear sale?',
          style: AppTextStyles.bs400(context).copyWith(
            fontWeight: FontWeight.w900,
            color: colors.textPrimary,
          ),
        ),
        content: Text(
          'This will remove all items from the current sale.',
          style: AppTextStyles.bs100(context).copyWith(
            color: colors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(dialogCtx, true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (shouldClear == true && context.mounted) {
      context.read<PosBloc>().add(const PosClearCart());
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return BlocListener<PosBloc, PosState>(
      listenWhen: (prev, curr) =>
          (prev.submitStatus != curr.submitStatus &&
              curr.submitStatus == PosSubmitStatus.success) ||
          (prev.items.isNotEmpty && curr.items.isEmpty),
      listener: (context, _) {
        if (Navigator.of(context).canPop()) Navigator.of(context).pop();
      },
      child: Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppDims.rXxl),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: BlocBuilder<PosBloc, PosState>(
        buildWhen: (prev, curr) =>
            prev.items != curr.items ||
            prev.paymentMethod != curr.paymentMethod ||
            prev.submitStatus != curr.submitStatus,
        builder: (context, state) {
          return Column(
            children: [
              SafeArea(
                top: true,
                bottom: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Drag handle
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        margin: const EdgeInsets.symmetric(
                            vertical: AppDims.s3),
                        decoration: BoxDecoration(
                          color: colors.border,
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                    ),

                    // Header row
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppDims.s4,
                        0,
                        AppDims.s2,
                        AppDims.s2,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Review Sale',
                                  style: AppTextStyles.bs500(context).copyWith(
                                    color: colors.textPrimary,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                                Text(
                                  '${state.itemCount} item${state.itemCount == 1 ? '' : 's'}',
                                  style: AppTextStyles.bs100(context).copyWith(
                                    color: colors.textSecondary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          TextButton.icon(
                            onPressed:
                                state.submitStatus == PosSubmitStatus.loading
                                    ? null
                                    : () => _confirmClearCart(context),
                            icon: const Icon(
                                Icons.delete_outline_rounded, size: 16),
                            label: const Text('Clear'),
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFFDC2626),
                              visualDensity: VisualDensity.compact,
                            ),
                          ),
                          IconButton(
                            tooltip: 'Close',
                            visualDensity: VisualDensity.compact,
                            onPressed: onCollapse,
                            icon: Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: colors.textPrimary,
                              size: 26,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              Divider(height: 1, color: colors.border),

              Expanded(
                child: ListView.separated(
                  padding: EdgeInsets.zero,
                  itemCount: state.items.length,
                  separatorBuilder: (_, _) =>
                      Divider(height: 1, color: colors.border),
                  itemBuilder: (_, index) {
                    final item = state.items[index];
                    return CartLine(
                      key: ValueKey(item.product.id),
                      item: item,
                    );
                  },
                ),
              ),

              Container(
                decoration: BoxDecoration(
                  color: colors.surface,
                  border: Border(
                    top: BorderSide(color: colors.border),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    PaymentSelector(paymentMethod: state.paymentMethod),

                    TotalsSection(state: state),

                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppDims.s4,
                        AppDims.s3,
                        AppDims.s4,
                        AppDims.s4,
                      ),
                      child: SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: FilledButton(
                          onPressed:
                              state.submitStatus == PosSubmitStatus.loading
                                  ? null
                                  : onCheckout,
                          style: FilledButton.styleFrom(
                            backgroundColor: colors.primary,
                            disabledBackgroundColor: colors.border,
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(AppDims.rMd),
                            ),
                          ),
                          child: state.submitStatus == PosSubmitStatus.loading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : Text(
                                  'Charge ${money(state.total)}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTextStyles.bs600(context).copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
      ),
    );
  }
}
