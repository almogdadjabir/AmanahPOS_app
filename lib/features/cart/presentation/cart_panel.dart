import 'package:amana_pos/features/cart/presentation/cart_peek.dart';
import 'package:amana_pos/features/cart/presentation/expanded_cart.dart';
import 'package:amana_pos/features/pos/presentation/bloc/pos_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CartPanel extends StatelessWidget {
  final PosState state;
  final VoidCallback onCheckout;

  const CartPanel({super.key, required this.state, required this.onCheckout});

  void _openCart(BuildContext context) {
    final posBloc = context.read<PosBloc>();

    final bottomReserve = 64.0 + MediaQuery.of(context).viewPadding.bottom;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.50),
      builder: (sheetCtx) {

        final sheetHeight =
            MediaQuery.of(sheetCtx).size.height - bottomReserve;

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
