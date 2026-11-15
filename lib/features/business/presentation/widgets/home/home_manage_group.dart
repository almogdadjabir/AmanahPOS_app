import 'package:amana_pos/theme/app_colors.dart';
import 'package:amana_pos/common/auth_bloc/auth_bloc.dart';
import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/config/router/route_strings.dart';
import 'package:amana_pos/features/business/data/models/responses/business_response_dto.dart';
import 'package:amana_pos/features/business/presentation/widgets/home/home_card.dart';
import 'package:amana_pos/features/products/presentation/bloc/product_bloc.dart';
import 'package:amana_pos/features/users/presentation/bloc/users_bloc.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/theme/phosphor_icons.dart';
import 'package:amana_pos/widgets/directional_icon.dart';
import 'package:amana_pos/widgets/pressable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Shops, Products, Cashiers, Sales history, Reports as an iOS grouped list.
class HomeManageGroup extends StatelessWidget {
  final BusinessData data;

  const HomeManageGroup({super.key, required this.data});

  // Fixed tile fills: white glyphs stay readable in light and dark.
  static const _teal = AppColors.primary;
  static const _indigo = AppColors.card;
  static const _amber = AppColors.manageAmber;
  static const _slate = AppColors.slate600;

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    final counts = data.counts;
    // Server counts when present; loaded lists only as a fallback.
    final loadedProducts = context.select(
      (ProductBloc b) => b.state.products.length,
    );
    final loadedUsers = context.select((UserBloc b) => b.state.userList.length);
    final shops = counts?.shopsActive ?? data.shopCount ?? 0;
    final products = counts?.productsActive ?? loadedProducts;
    final users = counts?.usersActive ?? loadedUsers;
    final nav = Navigator.of(context);
    final canSeeReports = context.select<AuthBloc, bool>(
      (b) => b.state.permissions.canAccessReports,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HomeSectionLabel(tr.homeManage),
        HomeCard(
          child: Column(
            children: [
              _ManageRow(
                icon: PhosphorIconsRegular.storefront,
                fill: _teal,
                title: tr.bizShopsTitle,
                value: tr.homeShopsCount(shops),
                onTap: () => nav.pushNamed(
                  RouteStrings.shopManagementScreen,
                  arguments: {'businessData': data},
                ),
              ),
              const HomeHairline(indent: 60),
              _ManageRow(
                icon: PhosphorIconsRegular.package,
                fill: _indigo,
                title: tr.navProducts,
                value: tr.homeProductsCount(products),
                onTap: () => nav.pushNamed(RouteStrings.productScreen),
              ),
              const HomeHairline(indent: 60),
              _ManageRow(
                icon: PhosphorIconsRegular.users,
                fill: _amber,
                title: tr.settingsCashiers,
                value: tr.homeUsersCount(users),
                onTap: () => nav.pushNamed(RouteStrings.cashiersScreen),
              ),
              const HomeHairline(indent: 60),
              _ManageRow(
                icon: PhosphorIconsRegular.receipt,
                fill: _slate,
                title: tr.homeSalesHistory,
                value: tr.homeSalesHint,
                onTap: () => nav.pushNamed(RouteStrings.salesHistoryScreen),
              ),
              if (canSeeReports) ...[
                const HomeHairline(indent: 60),
                _ManageRow(
                  icon: PhosphorIconsRegular.chartBar,
                  fill: _teal,
                  title: tr.navReports,
                  value: tr.homeReportsPerformance,
                  onTap: () => nav.pushNamed(RouteStrings.reportsScreen),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _ManageRow extends StatelessWidget {
  final IconData icon;
  final Color fill;
  final String title;
  final String value;
  final VoidCallback onTap;

  const _ManageRow({
    required this.icon,
    required this.fill,
    required this.title,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final text = Theme.of(context).textTheme;

    return Pressable(
      onTap: onTap,
      scale: 1,
      haptic: true,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 60),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: fill,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, size: 19, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: text.bodyLarge!.copyWith(
                  fontSize: 17,
                  fontWeight: FontWeight.w500,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                  style: text.bodyLarge!.copyWith(
                    fontSize: 15,
                    color: colors.textHint,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              DirectionalIcon(
                icon: PhosphorIconsRegular.caretRight,
                size: 16,
                color: colors.disabled,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
