import 'package:amana_pos/features/cart/presentation/cart_peek.dart';
import 'package:amana_pos/features/cart/presentation/expanded_cart.dart';
import 'package:amana_pos/features/pos/presentation/bloc/pos_bloc.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CartPanel extends StatefulWidget {
  final PosState state;
  final VoidCallback onCheckout;

  const CartPanel({super.key,
    required this.state,
    required this.onCheckout,
  });

  @override
  State<CartPanel> createState() => _CartPanelState();
}

class _CartPanelState extends State<CartPanel> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final targetHeight = _expanded
        ? MediaQuery.sizeOf(context).height * 0.82
        : 88.0;

    return AnimatedContainer(
      duration: AppDims.medium,
      curve: Curves.easeOutCubic,
      height: targetHeight,
      decoration: BoxDecoration(
        color: context.appColors.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppDims.rXl),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.14),
            blurRadius: 28,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: AnimatedSwitcher(
        duration: AppDims.fast,
        child: _expanded
            ? ExpandedCart(
          key: const ValueKey('expanded_cart'),
          onCollapse: () {
            setState(() => _expanded = false);
            context.read<PosBloc>().add(const PosCartExpandedChanged(false));
          },
          onCheckout: widget.onCheckout,
        )
            : CartPeek(
          key: const ValueKey('peek_cart'),
          state: widget.state,
          onTap: () {
            setState(() => _expanded = true);
            context.read<PosBloc>().add(const PosCartExpandedChanged(true));
          },
        ),
      ),
    );
  }
}