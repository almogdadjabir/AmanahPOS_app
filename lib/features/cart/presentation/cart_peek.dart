import 'package:amana_pos/features/pos/presentation/bloc/pos_bloc.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';
import 'package:solar_icons/solar_icons.dart';

class CartPeek extends StatefulWidget {
  final PosState state;
  final VoidCallback onTap;

  const CartPeek({
    super.key,
    required this.state,
    required this.onTap,
  });

  @override
  State<CartPeek> createState() => _CartPeekState();
}

class _CartPeekState extends State<CartPeek> {
  static const double _height = 78;

  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isLoading = widget.state.submitStatus == PosSubmitStatus.loading;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDims.s4),
      child: GestureDetector(
        onTap: isLoading ? null : widget.onTap,
        onTapDown: isLoading ? null : (_) => _setPressed(true),
        onTapCancel: isLoading ? null : () => _setPressed(false),
        onTapUp: isLoading ? null : (_) => _setPressed(false),
        behavior: HitTestBehavior.opaque,
        child: AnimatedScale(
          duration: const Duration(milliseconds: 130),
          curve: Curves.easeOut,
          scale: _pressed ? 0.985 : 1,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            height: _height,
            decoration: BoxDecoration(
              color: colors.secondary,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: colors.onSecondary.withValues(
                  alpha: isDark ? 0.08 : 0.12,
                ),
                width: 1,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          colors.secondary,
                          colors.secondary.withValues(alpha: 0.94),
                        ],
                      ),
                    ),
                  ),
                ),

                Positioned(
                  right: -22,
                  top: -34,
                  child: Container(
                    width: 128,
                    height: 128,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: colors.onSecondary.withValues(alpha: 0.07),
                    ),
                  ),
                ),

                LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth;

                    final centerGap = width < 350
                        ? 72.0
                        : width < 390
                        ? 86.0
                        : width < 430
                        ? 102.0
                        : 118.0;

                    return Row(
                      children: [
                        const SizedBox(width: AppDims.s3),

                        Flexible(
                          flex: 0,
                          child: _ReviewButton(isLoading: isLoading),
                        ),

                        const SizedBox(width: AppDims.s2),

                        const Expanded(
                          flex: 1,
                          child: SizedBox(),
                        ),

                        SizedBox(width: centerGap),

                        Expanded(
                          flex: 3,
                          child: Align(
                            alignment: AlignmentDirectional.centerEnd,
                            child: _CartSummary(
                              itemCount: widget.state.itemCount,
                              total: widget.state.total,
                            ),
                          ),
                        ),

                        const SizedBox(width: AppDims.s2),

                        Flexible(
                          flex: 0,
                          child: _CartIconBadge(
                            quantity: widget.state.itemCount,
                          ),
                        ),

                        const SizedBox(width: AppDims.s2),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ReviewButton extends StatelessWidget {
  final bool isLoading;

  const _ReviewButton({
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withValues(alpha: 0.18),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isLoading)
            SizedBox(
              width: 15,
              height: 15,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: colors.secondary,
              ),
            )
          else
            Icon(
              SolarIconsOutline.altArrowUp,
              size: 20,
              color: colors.secondary,
            ),
          const SizedBox(width: 7),
          Text(
            'Review',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bs200(context).copyWith(
              color: colors.secondary,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.15,
            ),
          ),
        ],
      ),
    );
  }
}

class _CartSummary extends StatelessWidget {
  final int itemCount;
  final double total;

  const _CartSummary({
    required this.itemCount,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return ConstrainedBox(
      constraints: const BoxConstraints(
        minWidth: 74,
        maxWidth: 118,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            'Cart',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.end,
            style: AppTextStyles.sm100(context).copyWith(
              color: colors.onSecondary.withValues(alpha: 0.68),
              fontWeight: FontWeight.w900,
              letterSpacing: 1.1,
              height: 1,
            ),
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerEnd,
            child: Text(
              _formatMoney(total),
              maxLines: 1,
              softWrap: false,
              textAlign: TextAlign.end,
              style: AppTextStyles.bs600(context).copyWith(
                color: colors.onSecondary,
                fontWeight: FontWeight.w900,
                height: 1,
                letterSpacing: -0.5,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$itemCount item${itemCount == 1 ? '' : 's'}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.end,
            style: AppTextStyles.sm100(context).copyWith(
              color: colors.onSecondary.withValues(alpha: 0.65),
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _CartIconBadge extends StatelessWidget {
  final int quantity;

  const _CartIconBadge({
    required this.quantity,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return SizedBox(
      width: 52,
      height: 56,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            top: 4,
            child: Container(
              decoration: BoxDecoration(
                color: colors.onSecondary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(
                SolarIconsOutline.cartLarge,
                size: 28,
                color: colors.onSecondary,
              ),
            ),
          ),
          Positioned(
            top: -4,
            left: -7,
            child: Container(
              constraints: const BoxConstraints(
                minWidth: 27,
                minHeight: 27,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 7),
              decoration: BoxDecoration(
                color: colors.background,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: colors.secondary.withValues(alpha: 0.34),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: colors.shadow.withValues(alpha: 0.18),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  '$quantity',
                  style: AppTextStyles.sm200(context).copyWith(
                    color: colors.secondary,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _formatMoney(double value) {
  final hasDecimals = value % 1 != 0;
  final raw = hasDecimals ? value.toStringAsFixed(2) : value.toStringAsFixed(0);

  final formatted = raw.replaceAllMapped(
    RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
        (match) => '${match[1]},',
  );

  return '$formatted SDG';
}