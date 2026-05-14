import 'package:amana_pos/common/auth_bloc/auth_bloc.dart';
import 'package:amana_pos/core/offline/presentation/widgets/offline_cached_image.dart';
import 'package:amana_pos/features/cart/presentation/qty_stepper.dart';
import 'package:amana_pos/features/pos/data/model/pos_cart_item.dart';
import 'package:amana_pos/features/pos/presentation/bloc/pos_bloc.dart';
import 'package:amana_pos/features/pos/presentation/pos_screen.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solar_icons/solar_icons.dart';

class CartLine extends StatelessWidget {
  final PosCartItem item;

  const CartLine({
    super.key,
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final productId = item.product.id;
    final imageUrl = item.product.thumbnailUrl ?? item.product.image;

    return Container(
      padding: const EdgeInsets.all(AppDims.s3),
      decoration: BoxDecoration(
        color: colors.surfaceSoft.withValues(alpha: 0.76),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: colors.border.withValues(alpha: 0.78),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _ProductThumb(
            imageUrl: imageUrl,
            name: item.product.name,
          ),

          const SizedBox(width: AppDims.s3),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _RemoveButton(
                      enabled: productId != null,
                      onTap: productId == null
                          ? null
                          : () {
                        context.read<PosBloc>().add(
                          PosRemoveItem(productId),
                        );
                      },
                    ),

                    const SizedBox(width: AppDims.s2),

                    Expanded(
                      child: Text(
                        item.product.name ?? 'Product',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.end,
                        style: AppTextStyles.bs400(context).copyWith(
                          color: colors.textPrimary,
                          fontWeight: FontWeight.w900,
                          height: 1.15,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppDims.s2),

                Row(
                  children: [
                    Text(
                      '${money(item.price)} each',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.sm100(context).copyWith(
                        color: colors.textHint,
                        fontWeight: FontWeight.w800,
                      ),
                    ),

                    const Spacer(),

                    QtyStepper(
                      qty: item.quantity,
                      onMinus: productId == null
                          ? null
                          : () {
                        context.read<PosBloc>().add(
                          PosDecrementItem(productId),
                        );
                      },
                      onPlus: productId == null
                          ? null
                          : () {
                        context.read<PosBloc>().add(
                          PosIncrementItem(
                            productId,
                            ignoreStockLimit: context
                                .read<AuthBloc>()
                                .state
                                .permissions
                                .isRestaurant,
                          ),
                        );
                      },
                    ),
                  ],
                ),

                const SizedBox(height: AppDims.s2),

                SizedBox(
                  width: double.infinity,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: AlignmentDirectional.centerEnd,
                    child: Text(
                      money(item.lineTotal),
                      maxLines: 1,
                      softWrap: false,
                      textAlign: TextAlign.end,
                      style: AppTextStyles.bs500(context).copyWith(
                        color: colors.primary,
                        fontWeight: FontWeight.w900,
                        height: 1,
                        letterSpacing: -0.25,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductThumb extends StatelessWidget {
  final String? imageUrl;
  final String? name;

  const _ProductThumb({
    required this.imageUrl,
    required this.name,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final hasImage = imageUrl?.trim().isNotEmpty == true;

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: 78,
        height: 78,
        decoration: BoxDecoration(
          color: _placeholderColor(name),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: colors.border.withValues(alpha: 0.5),
          ),
        ),
        child: hasImage
            ? OfflineCachedImage(
          imageUrl: imageUrl,
          fit: BoxFit.cover,
        )
            : Center(
          child: Text(
            _shortName(name),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bs300(context).copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }

  Color _placeholderColor(String? value) {
    final seed = value ?? 'product';

    final palette = <Color>[
      const Color(0xFF1E3A8A),
      const Color(0xFF7C2D12),
      const Color(0xFF9F1239),
      const Color(0xFF365314),
      const Color(0xFF155E75),
    ];

    final hash = seed.codeUnits.fold<int>(
      0,
          (previous, element) => previous + element,
    );

    return palette[hash % palette.length];
  }

  String _shortName(String? value) {
    final text = value?.trim();
    if (text == null || text.isEmpty) return 'POS';

    final words = text.split(RegExp(r'\s+'));
    if (words.length == 1) {
      return words.first.length <= 4
          ? words.first
          : words.first.substring(0, 4);
    }

    return '${words[0][0]}${words[1][0]}'.toUpperCase();
  }
}

class _RemoveButton extends StatelessWidget {
  final bool enabled;
  final VoidCallback? onTap;

  const _RemoveButton({
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
        opacity: enabled ? 1 : 0.4,
        child: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: colors.danger.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: colors.danger.withValues(alpha: 0.22),
            ),
          ),
          child: Icon(
            SolarIconsOutline.closeCircle,
            size: 18,
            color: colors.danger,
          ),
        ),
      ),
    );
  }
}