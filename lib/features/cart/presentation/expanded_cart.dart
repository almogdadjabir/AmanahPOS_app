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
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Clear sale?'),
          content: const Text(
            'This will remove all items from the current sale.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Clear'),
            ),
          ],
        );
      },
    );

    if (shouldClear == true && context.mounted) {
      context.read<PosBloc>().add(const PosClearCart());
      context.read<PosBloc>().add(const PosCartExpandedChanged(false));

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Sale cleared'),
          backgroundColor: colors.textPrimary,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<PosBloc>().state;
    final colors = context.appColors;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppDims.s4,
            AppDims.s3,
            AppDims.s2,
            AppDims.s2,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Review Sale',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bs600(context).copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: state.submitStatus == PosSubmitStatus.loading
                    ? null
                    : () => _confirmClearCart(context),
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  size: 18,
                ),
                label: const Text('Clear'),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFFDC2626),
                  visualDensity: VisualDensity.compact,
                ),
              ),
              IconButton(
                tooltip: 'Close cart',
                visualDensity: VisualDensity.compact,
                onPressed: onCollapse,
                icon: Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: colors.textPrimary,
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
            separatorBuilder: (_, __) => Divider(
              height: 1,
              color: colors.border,
            ),
            itemBuilder: (_, index) {
              return CartLine(item: state.items[index]);
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

              SafeArea(
                top: false,
                child: Padding(
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
                      onPressed: state.submitStatus == PosSubmitStatus.loading
                          ? null
                          : onCheckout,
                      style: FilledButton.styleFrom(
                        backgroundColor: colors.primary,
                        disabledBackgroundColor: colors.border,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppDims.rMd),
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
              ),
            ],
          ),
        ),
      ],
    );
  }
}