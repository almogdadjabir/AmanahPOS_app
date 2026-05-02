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

  const CartLine({
    super.key,
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
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: colors.surfaceSoft,
                  borderRadius: BorderRadius.circular(AppDims.rMd),
                ),
                clipBehavior: Clip.antiAlias,
                child: item.product.image?.trim().isNotEmpty == true
                    ? Image.network(
                  item.product.image!.trim(),
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Icon(
                    Icons.local_offer_outlined,
                    size: 20,
                    color: colors.textHint,
                  ),
                )
                    : Icon(
                  Icons.local_offer_outlined,
                  size: 20,
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
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bs300(context).copyWith(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w900,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: AppDims.s1),
                    Text(
                      '${money(item.price)} each',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bs100(context).copyWith(
                        color: colors.textHint,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                onPressed: productId == null
                    ? null
                    : () {
                  context.read<PosBloc>().add(
                    PosRemoveItem(productId),
                  );
                },
                icon: const Icon(
                  Icons.close_rounded,
                  color: Color(0xFFDC2626),
                  size: 20,
                ),
              ),
            ],
          ),

          const SizedBox(height: AppDims.s3),

          Row(
            children: [
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
              const Spacer(),
              Text(
                money(item.lineTotal),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.end,
                style: AppTextStyles.bs500(context).copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}