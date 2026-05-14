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
import 'package:solar_icons/solar_icons.dart';

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
      builder: (dialogCtx) {
        return AlertDialog(
          backgroundColor: colors.surface,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDims.rXl),
            side: BorderSide(color: colors.border),
          ),
          title: Text(
            'Clear cart?',
            style: AppTextStyles.bs500(context).copyWith(
              fontWeight: FontWeight.w900,
              color: colors.textPrimary,
            ),
          ),
          content: Text(
            'This will remove all items from the current sale.',
            style: AppTextStyles.bs200(context).copyWith(
              color: colors.textSecondary,
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: colors.danger,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(dialogCtx, true),
              child: const Text('Clear'),
            ),
          ],
        );
      },
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
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(34),
          ),
          border: Border(
            top: BorderSide(
              color: colors.border.withValues(alpha: 0.85),
              width: 1,
            ),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: BlocBuilder<PosBloc, PosState>(
          buildWhen: (prev, curr) =>
          prev.items != curr.items ||
              prev.paymentMethod != curr.paymentMethod ||
              prev.submitStatus != curr.submitStatus,
          builder: (context, state) {
            final isLoading = state.submitStatus == PosSubmitStatus.loading;

            return Column(
              children: [
                SafeArea(
                  top: true,
                  bottom: false,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: AppDims.s3),

                      Container(
                        width: 42,
                        height: 5,
                        decoration: BoxDecoration(
                          color: colors.textHint.withValues(alpha: 0.45),
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),

                      const SizedBox(height: AppDims.s4),

                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppDims.s4,
                          0,
                          AppDims.s4,
                          AppDims.s4,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            _ClearButton(
                              enabled: !isLoading,
                              onTap: () => _confirmClearCart(context),
                            ),

                            const Spacer(),

                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'Review sale',
                                  textAlign: TextAlign.end,
                                  style: AppTextStyles.bs600(context).copyWith(
                                    color: colors.textPrimary,
                                    fontWeight: FontWeight.w900,
                                    height: 1,
                                    letterSpacing: -0.4,
                                  ),
                                ),
                                const SizedBox(height: 7),
                                Text(
                                  '${state.itemCount} item${state.itemCount == 1 ? '' : 's'}',
                                  textAlign: TextAlign.end,
                                  style: AppTextStyles.sm200(context).copyWith(
                                    color: colors.textHint,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.6,
                                    height: 1,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(width: AppDims.s3),

                            _CollapseButton(onTap: onCollapse),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                Divider(
                  height: 1,
                  thickness: 1,
                  color: colors.border.withValues(alpha: 0.75),
                ),

                Expanded(
                  child: ListView.separated(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(
                      AppDims.s4,
                      AppDims.s3,
                      AppDims.s4,
                      AppDims.s3,
                    ),
                    itemCount: state.items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: AppDims.s3),
                    itemBuilder: (_, index) {
                      final item = state.items[index];

                      return CartLine(
                        key: ValueKey(item.product.id ?? index),
                        item: item,
                      );
                    },
                  ),
                ),

                Container(
                  decoration: BoxDecoration(
                    color: colors.surface,
                    border: Border(
                      top: BorderSide(
                        color: colors.border.withValues(alpha: 0.75),
                      ),
                    ),
                  ),
                  child: SafeArea(
                    top: false,
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
                            height: 62,
                            child: FilledButton(
                              onPressed: isLoading ? null : onCheckout,
                              style: FilledButton.styleFrom(
                                backgroundColor: colors.primary,
                                disabledBackgroundColor: colors.border,
                                foregroundColor: colors.onPrimary,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(22),
                                ),
                              ),
                              child: isLoading
                                  ? SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  color: colors.onPrimary,
                                  strokeWidth: 2.5,
                                ),
                              )
                                  : Row(
                                children: [
                                  Text(
                                    money(state.total),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTextStyles.bs600(context).copyWith(
                                      color: colors.onPrimary,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: -0.4,
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    'Complete sale',
                                    style: AppTextStyles.bs500(context).copyWith(
                                      color: colors.onPrimary,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: -0.25,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
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

class _ClearButton extends StatelessWidget {
  final bool enabled;
  final VoidCallback onTap;

  const _ClearButton({
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return GestureDetector(
      onTap: enabled ? onTap : null,
      behavior: HitTestBehavior.opaque,
      child: Opacity(
        opacity: enabled ? 1 : 0.45,
        child: Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: colors.danger.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: colors.danger.withValues(alpha: 0.22),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                SolarIconsOutline.trashBinTrash,
                size: 17,
                color: colors.danger,
              ),
              const SizedBox(width: 7),
              Text(
                'Clear',
                style: AppTextStyles.bs200(context).copyWith(
                  color: colors.danger,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CollapseButton extends StatelessWidget {
  final VoidCallback onTap;

  const _CollapseButton({
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: colors.surfaceSoft,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.border),
        ),
        child: Icon(
          SolarIconsOutline.altArrowDown,
          size: 22,
          color: colors.textPrimary,
        ),
      ),
    );
  }
}