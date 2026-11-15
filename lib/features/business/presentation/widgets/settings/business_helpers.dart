import 'package:amana_pos/common/auth_bloc/auth_bloc.dart' hide BusinessStatus;
import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/common/motion/motion_route.dart';
import 'package:amana_pos/features/business/data/models/responses/business_response_dto.dart';
import 'package:amana_pos/features/business/presentation/bloc/business_bloc.dart';
import 'package:amana_pos/features/business/presentation/shop_form_screen.dart';
import 'package:amana_pos/utilities/global_snackbar.dart';
import 'package:amana_pos/widgets/app_confirm_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The business this owner works on: the loaded list first, then the default
/// business kept by the auth bloc (one business per owner today).
BusinessData? currentBusiness(BusinessState state, BusinessData? fallback) {
  final list = state.businessList;
  if (list != null && list.isNotEmpty) return list.first;
  return fallback;
}

/// Waits for the next finished submit on [bloc] (success or failure).
Future<BusinessState> nextBusinessSubmit(BusinessBloc bloc) {
  return bloc.stream.firstWhere(
    (s) =>
        s.submitStatus == BusinessSubmitStatus.success ||
        s.submitStatus == BusinessSubmitStatus.failure,
  );
}

/// Opens the new / edit shop screen. [shop] null = new shop.
Future<void> openShopForm(
  BuildContext context, {
  required String businessId,
  ShopData? shop,
}) {
  final bloc = context.read<BusinessBloc>();
  final auth = context.read<AuthBloc>();

  return Navigator.of(context).push(
    motionPageRoute(
      MultiBlocProvider(
        providers: [
          BlocProvider.value(value: bloc),
          BlocProvider.value(value: auth),
        ],
        child: ShopFormScreen(businessId: businessId, shop: shop),
      ),
    ),
  );
}

/// Deactivates (after a confirm sheet) or reactivates [shop].
/// Resolves to true when the change went through.
Future<bool> setShopActive(
  BuildContext context, {
  required String businessId,
  required ShopData shop,
  required bool active,
}) async {
  final tr = context.tr;
  final bloc = context.read<BusinessBloc>();
  final id = shop.id?.trim();
  if (id == null || id.isEmpty) return false;
  final name = shop.name?.trim().isNotEmpty == true
      ? shop.name!.trim()
      : tr.shop;

  if (!active) {
    final confirmed = await showAppConfirmSheet(
      context,
      title: tr.shDeactivateTitle(name),
      message: tr.shDeactivateBody,
      confirmLabel: tr.shDeactivateAction,
    );
    if (!confirmed) return false;
  }

  final result = nextBusinessSubmit(bloc);
  bloc.add(
    OnEditShop(
      businessId: businessId,
      shopId: id,
      name: shop.name ?? '',
      address: shop.address,
      phone: shop.phone,
      isActive: active,
    ),
  );
  final state = await result;

  if (state.submitStatus == BusinessSubmitStatus.success) {
    GlobalSnackBar.show(message: tr.shSaved, isInfo: true);
    return true;
  }
  GlobalSnackBar.show(
    message: state.submitError ?? tr.somethingWentWrong,
    isError: true,
    isAutoDismiss: false,
  );
  return false;
}
