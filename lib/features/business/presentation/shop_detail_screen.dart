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
  final Shops shop;

  const ShopDetailScreen({
    super.key,
    required this.businessId,
    required this.shop,
  });

  @override
  Widget build(BuildContext context) {
    return BlocSelector<BusinessBloc, BusinessState, Shops?>(
      selector: (state) => state.businessList
          ?.firstWhere((b) => b.id == businessId,
          orElse: () => BusinessData())
          .shops
          ?.firstWhere((s) => s.id == shop.id, orElse: () => shop),
      builder: (context, data) {
        final s = data ?? shop;
        return Scaffold(
          backgroundColor: context.appColors.background,
          body: CustomScrollView(
            slivers: [
              ShopAppBar(businessId: businessId, shop: s),
              SliverPadding(
                padding: const EdgeInsets.all(AppDims.s4),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    ShopInfoSection(shop: s),
                    const SizedBox(height: AppDims.s6),
                  ]),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}