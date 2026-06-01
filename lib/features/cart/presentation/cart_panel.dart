import 'dart:math' as math;

import 'package:amana_pos/features/cart/presentation/cart_peek.dart';
import 'package:amana_pos/features/cart/presentation/expanded_cart.dart';
import 'package:amana_pos/features/pos/presentation/bloc/pos_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CartPanel extends StatelessWidget {
  const CartPanel({
    super.key,
    required this.state,
    required this.onCheckout,
  });

  final PosState state;
  final VoidCallback onCheckout;

  static const double _bottomReserve = 112;
  static const double _minSheetHeight = 420;

  void _openCart(BuildContext context) {
    final posBloc = context.read<PosBloc>();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.56),
      builder: (sheetCtx) {
        final size = MediaQuery.sizeOf(sheetCtx);
        final safeBottom = MediaQuery.viewPaddingOf(sheetCtx).bottom;

        final sheetHeight = math.max(
          _minSheetHeight,
          size.height - _bottomReserve - safeBottom,
        );

        return SizedBox(
          height: sheetHeight,
          child: BlocProvider.value(
            value: posBloc,
            child: ExpandedCart(
              onCollapse: () => Navigator.of(sheetCtx).pop(),
              onCheckout: onCheckout,
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return CartPeek(
      state: state,
      onTap: () => _openCart(context),
    );
  }
}