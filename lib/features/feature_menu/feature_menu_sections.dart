import 'package:amana_pos/config/router/route_strings.dart';
import 'package:amana_pos/features/main_screen/data/section.dart';
import 'package:amana_pos/features/main_screen/presentation/bloc/navigation_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

List<Section> buildMenuSections(BuildContext context, int currentIndex) => [
  Section('Sales', [
    SectionItem(
      'pos',
      'POS / Sales',
      'Create sales and checkout',
      Icons.point_of_sale_rounded,
      const Color(0xFF0D9488),
      active: currentIndex == 0,
      onTap: () => _goToTab(context, 0),
    ),
    SectionItem(
      'stock',
      'Stock',
      'Manage quantity and movements',
      Icons.inventory_2_rounded,
      const Color(0xFFEC4899),
      active: currentIndex == 5,
      onTap: () => _goToTab(context, 5),
    ),
  ]),

  Section('Business', [
    SectionItem(
      'customers',
      'Customers',
      'Profiles and loyalty',
      Icons.people_alt_rounded,
      const Color(0xFFEC4899),
      // active: currentIndex == CUSTOMERS_INDEX,
      // onTap: () => _goToTab(context, CUSTOMERS_INDEX),
    ),
    SectionItem(
      'reports',
      'Reports',
      'Sales and performance',
      Icons.show_chart_rounded,
      const Color(0xFF22C55E),
      // active: currentIndex == REPORTS_INDEX,
      // onTap: () => _goToTab(context, REPORTS_INDEX),
    ),
  ]),

  Section('Setup', [
    SectionItem(
      'prod',
      'Products',
      'Items, prices and variants',
      Icons.local_offer_rounded,
      const Color(0xFF0EA5E9),
      active: currentIndex == 4,
      onTap: () => _goToTab(context, 4),
    ),
    SectionItem(
      'cat',
      'Categories',
      'Organize your products',
      Icons.layers_rounded,
      const Color(0xFF8B5CF6),
      active: currentIndex == 3,
      onTap: () => _goToTab(context, 3),
    ),
    SectionItem(
      'business',
      'Business & Shops',
      'Profile and shop locations',
      Icons.store_mall_directory_rounded,
      const Color(0xFF475569),
      active: currentIndex == 1,
      onTap: () => _goToTab(context, 1),
    ),
    SectionItem(
      'cashiers',
      'Cashiers',
      'Staff access and cashier accounts',
      Icons.badge_rounded,
      const Color(0xFFDB2777),
      active: currentIndex == 2,
      onTap: () => _goToTab(context, 2),
    ),
  ]),
];

void _goToTab(BuildContext context, int index) {
  context.read<NavigationBloc>().add(NavigationTabSelected(index));
  context.read<NavigationBloc>().add(const SetMenuOpenEvent(open: false));
}