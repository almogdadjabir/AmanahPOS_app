import 'package:amana_pos/features/cart/presentation/cart_panel.dart';
import 'package:amana_pos/features/pos/presentation/bloc/pos_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CartSheet extends StatelessWidget {
  final VoidCallback onCheckout;

  const CartSheet({
    super.key,
    required this.onCheckout,
  });

  /// Must match NavShell._barHeight.
  /// The cart should sit above the bottom nav bar.
  /// The center FAB will still overlap it because FAB is lifted above the bar.
  static const double _bottomBarHeight = 86;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PosBloc, PosState>(
      buildWhen: (prev, curr) =>
      prev.items != curr.items ||
          prev.submitStatus != curr.submitStatus ||
          prev.paymentMethod != curr.paymentMethod,
      builder: (context, state) {
        if (state.items.isEmpty) return const SizedBox.shrink();

        final safeBottom = MediaQuery.viewPaddingOf(context).bottom;

        return Positioned(
          left: 0,
          right: 0,

          /// Correct position:
          /// above the normal bottom nav, but still behind the floating FAB.
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