import 'package:amana_pos/features/cart/presentation/bloc/cart_bloc.dart';
import 'package:amana_pos/features/dashboard/data/models/cart_item.dart';
import 'package:amana_pos/features/dashboard/data/models/discount.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/utilities/format.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Bottom sheet — compact peek with item count + total, expands to full cart.
class CartSheet extends StatelessWidget {
  final bool expanded;
  final ValueChanged<bool> onExpandedChanged;
  final VoidCallback onCharge;

  const CartSheet({
    super.key,
    required this.expanded,
    required this.onExpandedChanged,
    required this.onCharge,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CartBloc, CartState>(
      builder: (context, cartState) {
        final mediaH = MediaQuery.of(context).size.height;
        final targetH = expanded
            ? mediaH * 0.85
            : (cartState.isEmpty ? 0.0 : AppDims.cartPeekHeight.toDouble());

        return Stack(
          children: [
            // Backdrop when expanded
            IgnorePointer(
              ignoring: !expanded,
              child: AnimatedOpacity(
                duration: AppDims.fast,
                opacity: expanded ? 1 : 0,
                child: GestureDetector(
                  onTap: () => onExpandedChanged(false),
                  child: Container(color: Colors.black.withOpacity(0.45)),
                ),
              ),
            ),
            // Sheet
            Positioned(
              left: 0, right: 0, bottom: 0,
              child: AnimatedContainer(
                duration: AppDims.medium,
                curve: Curves.easeOutCubic,
                height: targetH,
                decoration: BoxDecoration(
                  color: context.appColors.background,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(AppDims.rXl),
                    topRight: Radius.circular(AppDims.rXl),
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x29000000),
                      blurRadius: 24,
                      offset: Offset(0, -8),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: AnimatedSwitcher(
                  duration: AppDims.fast,
                  child: expanded
                      ? _ExpandedView(
                    onCollapse: () => onExpandedChanged(false),
                    onCharge: onCharge,
                  )
                      : (cartState.isEmpty
                      ? const SizedBox.shrink()
                      : _PeekBar(onTap: () => onExpandedChanged(true))),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ─── Peek bar ────────────────────────────────────────────────────────────────

class _PeekBar extends StatelessWidget {
  final VoidCallback onTap;
  const _PeekBar({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cartState = context.watch<CartBloc>().state;
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        height: AppDims.cartPeekHeight.toDouble(),
        child: Stack(
          children: [
            // Drag handle
            Positioned(
              top: 8, left: 0, right: 0,
              child: Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: context.appColors.border,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDims.s4, vertical: AppDims.s3,
              ),
              child: Row(
                children: [
                  _CartBadge(count: cartState.itemCount),
                  const SizedBox(width: AppDims.s3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${cartState.itemCount} item${cartState.itemCount == 1 ? '' : 's'} · #ORD-2451',
                          style: TextStyle(
                            fontFamily: 'NunitoSans',
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: context.appColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        RichText(
                          text: TextSpan(
                            style: const TextStyle(fontFamily: 'NunitoSans'),
                            children: [
                              TextSpan(
                                text: AppFormat.money(cartState.total),
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: context.appColors.textPrimary,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              TextSpan(
                                text: '  ${AppFormat.currency}',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: context.appColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                    decoration: BoxDecoration(
                      color: context.appColors.primary,
                      borderRadius: BorderRadius.circular(AppDims.rMd),
                      boxShadow: [
                        BoxShadow(
                          color: context.appColors.primary.withOpacity(0.35),
                          blurRadius: 14,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Text(
                      'View cart',
                      style: TextStyle(
                        fontFamily: 'NunitoSans',
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CartBadge extends StatelessWidget {
  final int count;
  const _CartBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            color: context.appColors.primaryContainer,
            borderRadius: BorderRadius.circular(AppDims.rSm),
          ),
          child: Icon(Icons.shopping_cart_outlined, color: context.appColors.primary),
        ),
        if (count > 0)
          Positioned(
            top: -4, right: -4,
            child: Container(
              constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
              padding: const EdgeInsets.symmetric(horizontal: 5),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: context.appColors.primary,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: context.appColors.surface, width: 2),
              ),
              child: Text(
                '$count',
                style: const TextStyle(
                  fontFamily: 'NunitoSans',
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ─── Expanded cart ────────────────────────────────────────────────────────────

class _ExpandedView extends StatelessWidget {
  final VoidCallback onCollapse;
  final VoidCallback onCharge;
  const _ExpandedView({required this.onCollapse, required this.onCharge});

  @override
  Widget build(BuildContext context) {
    final cartState = context.watch<CartBloc>().state;
    return Column(
      children: [
        _Header(onClose: onCollapse),
        const _CustomerRow(),
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.zero,
            itemCount: cartState.items.length,
            itemBuilder: (_, i) => _CartLine(item: cartState.items[i]),
          ),
        ),
        const _Totals(),
        _PaymentButtons(onCharge: onCharge),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  final VoidCallback onClose;
  const _Header({required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppDims.s4, AppDims.s2, AppDims.s2, AppDims.s3),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Current order',
                  style: TextStyle(
                    fontFamily: 'NunitoSans',
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: context.appColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '#ORD-2451 · Dine in · Table 4',
                  style: TextStyle(
                    fontFamily: 'NunitoSans',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: context.appColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onClose,
            icon: Icon(Icons.close_rounded, color: context.appColors.textPrimary),
          ),
        ],
      ),
    );
  }
}

class _CustomerRow extends StatelessWidget {
  const _CustomerRow();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDims.s4, vertical: AppDims.s3,
      ),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: context.appColors.border),
          bottom: BorderSide(color: context.appColors.border),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              color: context.appColors.surfaceSoft,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.person_outline_rounded,
                size: 18, color: context.appColors.textSecondary),
          ),
          const SizedBox(width: AppDims.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Walk-in customer',
                  style: TextStyle(
                    fontFamily: 'NunitoSans',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: context.appColors.textPrimary,
                  ),
                ),
                Text(
                  'Tap to add · earn loyalty',
                  style: TextStyle(
                    fontFamily: 'NunitoSans',
                    fontSize: 11,
                    color: context.appColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              foregroundColor: context.appColors.primary,
              side: BorderSide(color: context.appColors.border),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              minimumSize: const Size(0, 30),
              textStyle: const TextStyle(
                fontFamily: 'NunitoSans', fontSize: 11, fontWeight: FontWeight.w700,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDims.rXs),
              ),
            ),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}

class _CartLine extends StatelessWidget {
  final CartItem item;
  const _CartLine({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDims.s4, vertical: AppDims.s3,
      ),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: context.appColors.border)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: context.appColors.surfaceSoft,
              borderRadius: BorderRadius.circular(AppDims.rSm),
            ),
            alignment: Alignment.center,
            child: Text(
              AppFormat.initials(item.product.name),
              style: TextStyle(
                fontFamily: 'NunitoSans',
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: context.appColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: AppDims.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.product.name,
                        style: TextStyle(
                          fontFamily: 'NunitoSans',
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: context.appColors.textPrimary,
                          height: 1.3,
                        ),
                      ),
                    ),
                    Material(
                      color: context.appColors.danger,
                      borderRadius: BorderRadius.circular(AppDims.rXs),
                      child: InkWell(
                        onTap: () => context
                            .read<CartBloc>()
                            .add(RemoveProductEvent(productId: item.product.id)),
                        borderRadius: BorderRadius.circular(AppDims.rXs),
                        child: SizedBox(
                          width: 26, height: 26,
                          child: Icon(Icons.delete_outline_rounded,
                              size: 14, color: context.appColors.danger),
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  '${AppFormat.money(item.product.price)} × ${item.qty}',
                  style: TextStyle(
                    fontFamily: 'NunitoSans',
                    fontSize: 11,
                    color: context.appColors.textHint,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _QtyStepper(
                      qty: item.qty,
                      onMinus: () => context
                          .read<CartBloc>()
                          .add(DecrementProductEvent(productId: item.product.id)),
                      onPlus: () => context
                          .read<CartBloc>()
                          .add(IncrementProductEvent(productId: item.product.id)),
                    ),
                    const Spacer(),
                    RichText(
                      text: TextSpan(
                        style: const TextStyle(fontFamily: 'NunitoSans'),
                        children: [
                          TextSpan(
                            text: AppFormat.money(item.lineTotal),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: context.appColors.textPrimary,
                            ),
                          ),
                          TextSpan(
                            text: '  ${AppFormat.currency}',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: context.appColors.textHint,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QtyStepper extends StatelessWidget {
  final int qty;
  final VoidCallback onMinus;
  final VoidCallback onPlus;
  const _QtyStepper({
    required this.qty,
    required this.onMinus,
    required this.onPlus,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.appColors.surfaceSoft,
        borderRadius: BorderRadius.circular(AppDims.rSm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _QtyBtn(icon: Icons.remove_rounded, onTap: onMinus),
          SizedBox(
            width: 28,
            child: Text(
              '$qty',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'NunitoSans',
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: context.appColors.textPrimary,
              ),
            ),
          ),
          _QtyBtn(icon: Icons.add_rounded, onTap: onPlus),
        ],
      ),
    );
  }
}

class _QtyBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _QtyBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        width: 30, height: 30,
        child: Icon(icon, size: 16, color: context.appColors.textPrimary),
      ),
    );
  }
}

class _Totals extends StatelessWidget {
  const _Totals();

  @override
  Widget build(BuildContext context) {
    final cartState = context.watch<CartBloc>().state;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDims.s4, vertical: AppDims.s3,
      ),
      decoration: BoxDecoration(
        color: context.appColors.surfaceSoft,
        border: Border(top: BorderSide(color: context.appColors.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Row(
            label: 'Subtotal',
            value: '${AppFormat.money(cartState.subtotal)} ${AppFormat.currency}',
          ),
          const _DiscountRow(),
          _Row(
            label: 'VAT (10%)',
            value: '${AppFormat.money(cartState.vat)} ${AppFormat.currency}',
            muted: true,
          ),
          const SizedBox(height: AppDims.s2),
          Divider(color: context.appColors.border, height: 1),
          const SizedBox(height: AppDims.s2),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                'Total',
                style: TextStyle(
                  fontFamily: 'NunitoSans',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: context.appColors.textSecondary,
                ),
              ),
              RichText(
                text: TextSpan(
                  style: const TextStyle(fontFamily: 'NunitoSans'),
                  children: [
                    TextSpan(
                      text: AppFormat.money(cartState.total),
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: context.appColors.textPrimary,
                        letterSpacing: -0.4,
                      ),
                    ),
                    TextSpan(
                      text: '  ${AppFormat.currency}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: context.appColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  final bool muted;
  const _Row({required this.label, required this.value, this.muted = false});

  @override
  Widget build(BuildContext context) {
    final color =
    muted ? context.appColors.textSecondary : context.appColors.textPrimary;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                fontFamily: 'NunitoSans',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              )),
          Text(value,
              style: TextStyle(
                fontFamily: 'NunitoSans',
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: color,
              )),
        ],
      ),
    );
  }
}

class _DiscountRow extends StatelessWidget {
  static const _options = <int>[0, 5, 10, 20];
  const _DiscountRow();

  @override
  Widget build(BuildContext context) {
    final cartState = context.watch<CartBloc>().state;
    final amount = cartState.discountAmount;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Discount',
                style: TextStyle(
                  fontFamily: 'NunitoSans',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: context.appColors.textPrimary,
                ),
              ),
              Wrap(
                spacing: 4,
                children: _options.map((v) {
                  final active = cartState.discount.type == DiscountType.percent &&
                      cartState.discount.value == v;
                  return _Pill(
                    label: v == 0 ? 'None' : '$v%',
                    active: active,
                    onTap: () => context
                        .read<CartBloc>()
                        .add(SetDiscountEvent(
                      discount: Discount(type: DiscountType.percent, value: v),
                    )),
                  );
                }).toList(),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '${amount > 0 ? '−' : ''}${AppFormat.money(amount)} ${AppFormat.currency}',
              style: TextStyle(
                fontFamily: 'NunitoSans',
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: amount > 0
                    ? context.appColors.danger
                    : context.appColors.textHint,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _Pill({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: active ? context.appColors.primary : context.appColors.surface,
      shape: StadiumBorder(
        side: BorderSide(
          color: active ? context.appColors.primary : context.appColors.border,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'NunitoSans',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: active
                  ? context.appColors.primary
                  : context.appColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

class _PaymentButtons extends StatelessWidget {
  final VoidCallback onCharge;
  const _PaymentButtons({required this.onCharge});

  @override
  Widget build(BuildContext context) {
    final cartState = context.watch<CartBloc>().state;
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.only(bottom: 4),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppDims.s4, AppDims.s3, AppDims.s4, AppDims.s5,
        ),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _PayBtn(
                    label: 'Cash',
                    sub: 'Drawer',
                    dot: context.appColors.cash,
                  ),
                ),
                const SizedBox(width: AppDims.s2),
                Expanded(
                  child: _PayBtn(
                    label: 'Card',
                    sub: 'POS terminal',
                    dot: context.appColors.card,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDims.s2),
            SizedBox(
              width: double.infinity, height: 54,
              child: ElevatedButton(
                onPressed: cartState.isEmpty ? null : onCharge,
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.appColors.primary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: context.appColors.border,
                  disabledForegroundColor: context.appColors.textHint,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppDims.rMd),
                  ),
                  textStyle: const TextStyle(
                    fontFamily: 'NunitoSans',
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                child: Text(
                  'Charge ${AppFormat.money(cartState.total)} ${AppFormat.currency}',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PayBtn extends StatelessWidget {
  final String label;
  final String sub;
  final Color dot;
  const _PayBtn({required this.label, required this.sub, required this.dot});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: OutlinedButton(
        onPressed: () {},
        style: OutlinedButton.styleFrom(
          backgroundColor: context.appColors.surface,
          side: BorderSide(color: context.appColors.border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDims.rMd),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8, height: 8,
                  decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'NunitoSans',
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: context.appColors.textPrimary,
                  ),
                ),
              ],
            ),
            Text(
              sub,
              style: TextStyle(
                fontFamily: 'NunitoSans',
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: context.appColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}