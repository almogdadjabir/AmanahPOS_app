import 'package:amana_pos/features/business/data/models/responses/business_response_dto.dart';
import 'package:amana_pos/features/business/presentation/bloc/business_bloc.dart';
import 'package:amana_pos/features/business/presentation/widgets/shop/shop_app_bar.dart';
import 'package:amana_pos/features/business/presentation/widgets/shop/shop_info_section.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ShopDetailScreen extends StatelessWidget {
  final String businessId;
  final ShopData shop;

  const ShopDetailScreen({
    super.key,
    required this.businessId,
    required this.shop,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return BlocSelector<BusinessBloc, BusinessState, ShopData?>(
      selector: (state) {
        final businesses = state.businessList;
        if (businesses == null || businesses.isEmpty) return shop;

        for (final business in businesses) {
          if (business.id != businessId) continue;

          final shops = business.shops;
          if (shops == null || shops.isEmpty) return shop;

          for (final item in shops) {
            if (item.id == shop.id) return item;
          }
        }

        return shop;
      },
      builder: (context, data) {
        final currentShop = data ?? shop;

        return Scaffold(
          backgroundColor: colors.background,
          body: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              ShopAppBar(
                businessId: businessId,
                shop: currentShop,
              ),
              SliverPadding(
                padding: const EdgeInsets.all(AppDims.s4),
                sliver: SliverToBoxAdapter(
                  child: ShopInfoSection(shop: currentShop),
                ),
              ),
              const SliverToBoxAdapter(
                child: SizedBox(height: AppDims.s6),
              ),
            ],
          ),
        );
      },
    );
  }
}