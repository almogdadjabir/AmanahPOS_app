import 'package:amana_pos/common/auth_bloc/auth_bloc.dart';
import 'package:amana_pos/common/localization/app_localizations_extension.dart';
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
        alignment: AlignmentDirectional.bottomCenter,
        children: [
          PositionedDirectional(
            start: 0,
            end: 0,
            bottom: _navBarHeight + safeBottom + _cartGapAboveNav,
            child: BlocSelector<PosBloc, PosState, _CartPeekStateView>(
              selector: (state) => _CartPeekStateView(
                itemsHash: Object.hashAll(state.items),
                hasItems: state.items.isNotEmpty,
                submitStatus: state.submitStatus,
                paymentMethod: state.paymentMethod,
                state: state,
              ),
              builder: (context, view) {
                if (!view.hasItems) {
                  return const SizedBox.shrink();
                }

                return CartPanel(
                  state: view.state,
                  onCheckout: _handleCheckout,
                );
              },
            ),
          ),
          const PositionedDirectional(
            start: 0,
            end: 0,
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

    final posBloc = context.read<PosBloc>();
    final authBloc = context.read<AuthBloc>();
    final tr = context.tr;

    try {
      final posState = posBloc.state;

      if (posState.paymentMethod == 'bankak') {
        final bankakAccount =
        authBloc.state.profile?.bankakAccount?.accountNumber?.trim();

        if (bankakAccount == null || bankakAccount.isEmpty) {
          GlobalSnackBar.show(
            message: tr.bankakAccountNotSetUpMessage,
            isError: true,
            isAutoDismiss: false,
          );
          return;
        }
      }

      final selectedShopId = posState.selectedShopId?.trim();

      if (selectedShopId != null && selectedShopId.isNotEmpty) {
        posBloc.add(PosCheckoutSubmitted(shopId: selectedShopId));
        return;
      }

      final fallbackShopId = await _shopFromCache();

      if (!mounted) return;

      final resolvedShopId = fallbackShopId?.trim();

      if (resolvedShopId == null || resolvedShopId.isEmpty) {
        final permissions = authBloc.state.permissions;

        GlobalSnackBar.show(
          message: permissions.isCashier
              ? tr.cashierNotAssignedToShopMessage
              : tr.noShopFoundRefreshMessage,
          isError: true,
          isAutoDismiss: false,
        );
        return;
      }

      posBloc
        ..add(
          PosShopSelected(
            shopId: resolvedShopId,
            shopName: tr.shop,
          ),
        )
        ..add(
          PosCheckoutSubmitted(shopId: resolvedShopId),
        );
    } finally {
      _checkoutResolvingShop = false;
    }
  }

  Future<String?> _shopFromCache() async {
    try {
      final cache = getIt<OfflineLocalCache>();
      final cachedShops = await cache.getShops();

      for (final shop in cachedShops) {
        final id = shop.id?.trim();
        if (id != null && id.isNotEmpty) return id;
      }
    } catch (_) {
      return null;
    }

    return null;
  }
}

class _CartPeekStateView {
  const _CartPeekStateView({
    required this.itemsHash,
    required this.hasItems,
    required this.submitStatus,
    required this.paymentMethod,
    required this.state,
  });

  final int itemsHash;
  final bool hasItems;
  final PosSubmitStatus submitStatus;
  final String paymentMethod;
  final PosState state;

  @override
  bool operator ==(Object other) {
    return other is _CartPeekStateView &&
        other.itemsHash == itemsHash &&
        other.hasItems == hasItems &&
        other.submitStatus == submitStatus &&
        other.paymentMethod == paymentMethod;
  }

  @override
  int get hashCode => Object.hash(
    itemsHash,
    hasItems,
    submitStatus,
    paymentMethod,
  );
}