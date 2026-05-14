import 'package:amana_pos/common/auth_bloc/auth_bloc.dart';
import 'package:amana_pos/core/offline/data/offline_local_cache.dart';
import 'package:amana_pos/features/cart/presentation/cart_panel.dart';
import 'package:amana_pos/features/main_screen/presentation/widgets/bottom_nav.dart';
import 'package:amana_pos/features/pos/presentation/bloc/pos_bloc.dart';
import 'package:amana_pos/utilities/dependencies_provider.dart';
import 'package:amana_pos/utilities/global_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class MainBottomArea extends StatefulWidget {
  const MainBottomArea({super.key});

  @override
  State<MainBottomArea> createState() => _MainBottomAreaState();
}

class _MainBottomAreaState extends State<MainBottomArea> {
  static const double _navBarHeight = 86;
  static const double _fabLift = 26;
  static const double _cartHeight = 78;
  static const double _cartGapAboveNav = 0;

  bool _checkoutResolvingShop = false;

  @override
  Widget build(BuildContext context) {
    final safeBottom = MediaQuery.viewPaddingOf(context).bottom;

    final totalHeight = _navBarHeight +
        _fabLift +
        safeBottom +
        _cartHeight +
        _cartGapAboveNav;

    return SizedBox(
      height: totalHeight,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          Positioned(
            left: 0,
            right: 0,
            bottom: _navBarHeight + safeBottom + _cartGapAboveNav,
            child: BlocBuilder<PosBloc, PosState>(
              buildWhen: (prev, curr) =>
              prev.items != curr.items ||
                  prev.submitStatus != curr.submitStatus ||
                  prev.paymentMethod != curr.paymentMethod,
              builder: (context, state) {
                if (state.items.isEmpty) {
                  return const SizedBox.shrink();
                }

                return CartPanel(
                  state: state,
                  onCheckout: _handleCheckout,
                );
              },
            ),
          ),

          const Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: BottomNav(),
          ),
        ],
      ),
    );
  }

  Future<void> _handleCheckout() async {
    if (_checkoutResolvingShop) return;

    _checkoutResolvingShop = true;

    try {
      final posState = context.read<PosBloc>().state;

      if (posState.paymentMethod == 'bankak') {
        String? bankakAccount;

        try {
          bankakAccount = context
              .read<AuthBloc>()
              .state
              .profile
              ?.bankakAccount
              ?.accountNumber
              ?.trim();
        } catch (_) {}

        if (bankakAccount == null || bankakAccount.isEmpty) {
          GlobalSnackBar.show(
            message:
            'Bankak account is not set up. Go to Settings and add your account number first.',
            isError: true,
            isAutoDismiss: false,
          );
          return;
        }
      }

      final shopId = posState.selectedShopId;

      if (shopId != null && shopId.isNotEmpty) {
        context.read<PosBloc>().add(
          PosCheckoutSubmitted(shopId: shopId),
        );
        return;
      }

      final fallbackShopId = await _shopFromCache();

      if (!mounted) return;

      if (fallbackShopId == null || fallbackShopId.isEmpty) {
        final permissions = context.read<AuthBloc>().state.permissions;

        GlobalSnackBar.show(
          message: permissions.isCashier
              ? 'You are not assigned to a shop. Contact your manager.'
              : 'No shop found. Please refresh and try again.',
          isError: true,
          isAutoDismiss: false,
        );
        return;
      }

      context.read<PosBloc>().add(
        PosShopSelected(
          shopId: fallbackShopId,
          shopName: 'Shop',
        ),
      );

      context.read<PosBloc>().add(
        PosCheckoutSubmitted(shopId: fallbackShopId),
      );
    } finally {
      _checkoutResolvingShop = false;
    }
  }

  Future<String?> _shopFromCache() async {
    try {
      final cache = getIt<OfflineLocalCache>();
      final cachedShops = await cache.getShops();

      if (cachedShops.isNotEmpty) {
        final id = cachedShops.first.id;
        if (id != null && id.isNotEmpty) return id;
      }
    } catch (_) {}

    return null;
  }
}