import 'package:amana_pos/features/business/data/models/responses/business_response_dto.dart';
import 'package:amana_pos/features/business/presentation/bloc/business_bloc.dart';
import 'package:amana_pos/features/business/presentation/widgets/business_card_skeleton.dart';
import 'package:amana_pos/features/business/presentation/widgets/business_empty_view.dart';
import 'package:amana_pos/features/business/presentation/widgets/business_error_view.dart';
import 'package:amana_pos/features/business/presentation/widgets/workspace/single_business_workspace.dart';
import 'package:amana_pos/features/dashboard/presentation/bloc/dashboard_summary_bloc.dart';
import 'package:amana_pos/features/pos/presentation/bloc/pos_bloc.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class BusinessScreen extends StatefulWidget {
  const BusinessScreen({super.key});

  @override
  State<BusinessScreen> createState() => _BusinessScreenState();
}

class _BusinessScreenState extends State<BusinessScreen> {
  String? _lastDashboardScopeKey;

  @override
  void initState() {
    super.initState();

    context.read<BusinessBloc>().add(OnBusinessInitial());

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _tryLoadDashboardFromCurrentBusinessState();
    });
  }

  void _tryLoadDashboardFromCurrentBusinessState() {
    final businessState = context.read<BusinessBloc>().state;
    final businesses = businessState.businessList ?? [];

    if (businesses.isEmpty) return;

    _loadDashboardForBusiness(businesses.first);
  }

  void _loadDashboardForBusiness(BusinessData business) {
    if (!mounted) return;

    final businessId = business.id;
    final shop = _resolveDashboardShop(business);
    final shopId = shop?.id;

    if (businessId == null || businessId.isEmpty) return;
    if (shopId == null || shopId.isEmpty) return;

    final scopeKey = '$businessId|$shopId|10';
    if (_lastDashboardScopeKey == scopeKey) return;

    _lastDashboardScopeKey = scopeKey;

    final currentShopId = context.read<PosBloc>().state.selectedShopId;

    if (currentShopId != shopId) {
      context.read<PosBloc>().add(
        PosShopSelected(
          shopId: shopId,
          shopName: shop?.name ?? 'Shop',
        ),
      );
    }

    context.read<DashboardSummaryBloc>().add(
      OnDashboardSummaryStarted(
        businessId: businessId,
        shopId: shopId,
        topSellersLimit: 10,
      ),
    );
  }

  ShopData? _resolveDashboardShop(BusinessData business) {
    final selectedShopId = context.read<PosBloc>().state.selectedShopId;

    final activeShops = business.shops
        ?.where((shop) => shop.id != null && (shop.isActive ?? true))
        .toList() ??
        [];

    if (activeShops.isEmpty) return null;

    if (selectedShopId != null && selectedShopId.isNotEmpty) {
      for (final shop in activeShops) {
        if (shop.id == selectedShopId) return shop;
      }
    }

    return activeShops.first;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocConsumer<BusinessBloc, BusinessState>(
        listenWhen: (prev, curr) =>
        prev.businessStatus != curr.businessStatus ||
            prev.businessList != curr.businessList,
        listener: (context, state) {
          final businesses = state.businessList ?? [];

          if (state.businessStatus == BusinessStatus.success &&
              businesses.isNotEmpty) {
            _loadDashboardForBusiness(businesses.first);
          }
        },
        buildWhen: (prev, curr) =>
        prev.businessStatus != curr.businessStatus ||
            prev.businessList != curr.businessList ||
            prev.responseError != curr.responseError,
        builder: (context, state) {
          final businesses = state.businessList ?? [];

          if (state.businessStatus == BusinessStatus.loading ||
              (state.businessStatus == BusinessStatus.initial &&
                  state.businessList == null)) {
            return const _LoadingView();
          }

          if (state.businessStatus == BusinessStatus.failure) {
            return BusinessErrorView(
              message: state.responseError,
            );
          }

          if (businesses.isEmpty) {
            return const BusinessEmptyView();
          }

          return SingleBusinessWorkspace(
            data: businesses.first,
          );
        },
      ),
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(AppDims.s4),
      itemCount: 4,
      separatorBuilder: (_, _) => const SizedBox(height: AppDims.s3),
      itemBuilder: (_, _) => const BusinessCardSkeleton(),
    );
  }
}