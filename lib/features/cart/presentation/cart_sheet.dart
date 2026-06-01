import 'package:amana_pos/features/cart/presentation/cart_panel.dart';
import 'package:amana_pos/features/pos/presentation/bloc/pos_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CartSheet extends StatelessWidget {
  const CartSheet({
    super.key,
    required this.onCheckout,
  });

  final VoidCallback onCheckout;

  static const double _bottomBarHeight = 86;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PosBloc, PosState>(
      buildWhen: (prev, curr) =>
      prev.items != curr.items ||
          prev.submitStatus != curr.submitStatus ||
          prev.paymentMethod != curr.paymentMethod,
      builder: (context, state) {
        if (state.items.isEmpty) {
          return const SizedBox.shrink();
        }

        final safeBottom = MediaQuery.viewPaddingOf(context).bottom;

        return PositionedDirectional(
          start: 0,
          end: 0,
          bottom: _bottomBarHeight + safeBottom,
          child: CartPanel(
            state: state,
            onCheckout: onCheckout,
          ),
        );
      },
    );
  }
}