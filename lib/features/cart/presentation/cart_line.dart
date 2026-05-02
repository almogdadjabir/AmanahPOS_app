import 'package:amana_pos/features/cart/presentation/qty_stepper.dart';
import 'package:amana_pos/features/pos/data/models/pos_cart_item.dart';
import 'package:amana_pos/features/pos/presentation/bloc/pos_bloc.dart';
import 'package:amana_pos/features/pos/presentation/pos_screen.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CartLine extends StatelessWidget {
  final PosCartItem item;

  const CartLine({super.key,
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final productId = item.product.id;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppDims.s4,
        AppDims.s3,
        AppDims.s3,
        AppDims.s3,
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: colors.surfaceSoft,
              borderRadius: BorderRadius.circular(AppDims.rSm),
            ),
            clipBehavior: Clip.antiAlias,
            child: item.product.image?.trim().isNotEmpty == true
                ? Image.network(
              item.product.image!.trim(),
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.local_offer_outlined,
                size: 18,
              ),
            )
                : Icon(
              Icons.local_offer_outlined,
              size: 18,
              color: colors.textHint,
            ),
          ),
          const SizedBox(width: AppDims.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.product.name ?? 'Product',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bs300(context).copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${money(item.price)} × ${item.quantity}',
                  style: AppTextStyles.bs100(context).copyWith(
                    color: colors.textHint,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
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
                PosIncrementItem(productId),
              );
            },
          ),
          const SizedBox(width: AppDims.s2),
          SizedBox(
            width: 70,
            child: Text(
              money(item.lineTotal),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
              style: AppTextStyles.bs300(context).copyWith(
                color: colors.textPrimary,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: productId == null
                ? null
                : () {
              context.read<PosBloc>().add(PosRemoveItem(productId));
            },
            icon: const Icon(
              Icons.close_rounded,
              color: Color(0xFFDC2626),
              size: 19,
            ),
          ),
        ],
      ),
    );
  }
}