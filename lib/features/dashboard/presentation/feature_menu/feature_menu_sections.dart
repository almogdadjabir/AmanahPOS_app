import 'package:amana_pos/features/dashboard/data/models/section.dart';
import 'package:amana_pos/features/main_screen/presentation/bloc/navigation_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

List<Section> buildMenuSections(BuildContext context, int currentIndex) => [
  Section('Operations', [
    SectionItem('pos', 'POS / Sales', 'New sale & checkout',
        Icons.point_of_sale_rounded, const Color(0xFF0D9488),
        active: currentIndex == 0,
        onTap: () {
          context.read<NavigationBloc>().add(const NavigationTabSelected(0));
          context.read<NavigationBloc>().add(const SetMenuOpenEvent(open: false));
        }),
    SectionItem('orders', 'Orders', 'History & refunds',
        Icons.receipt_long_rounded, const Color(0xFF0EA5E9)),
    SectionItem('cust', 'Customers', 'CRM & loyalty',
        Icons.people_alt_rounded, const Color(0xFFEC4899)),
  ]),
  Section('Inventory', [
    SectionItem('prod', 'Products', 'Catalog & variants',
        Icons.local_offer_rounded, const Color(0xFF0EA5E9)),
    SectionItem('cat', 'Categories', 'Menu structure',
        Icons.layers_rounded, const Color(0xFF8B5CF6)),
    SectionItem('stock', 'Stock Control', 'Levels & transfers',
        Icons.inventory_2_rounded, const Color(0xFFEC4899)),
    SectionItem('po', 'Purchase Orders', 'Suppliers & deliveries',
        Icons.local_shipping_rounded, const Color(0xFF0891B2)),
  ]),
  Section('Insights', [
    SectionItem('rep', 'Reports', 'Sales & tax reports',
        Icons.show_chart_rounded, const Color(0xFF22C55E)),
    SectionItem('shift', 'Shifts & Drawers', 'Open / close cashflow',
        Icons.schedule_rounded, const Color(0xFFEA580C)),
  ]),
  Section('Admin', [
    SectionItem('team', 'User Management', 'Staff, roles, PINs',
        Icons.badge_rounded, const Color(0xFFDB2777)),
    SectionItem('business', 'Branches & Devices', 'Locations',
        Icons.store_mall_directory_rounded, const Color(0xFF475569),
        active: currentIndex == 1,
        onTap: () {
          context.read<NavigationBloc>().add(const NavigationTabSelected(1));
          context.read<NavigationBloc>().add(const SetMenuOpenEvent(open: false));
        }),
    SectionItem('set', 'Settings', 'Tax, currency, payments',
        Icons.settings_rounded, const Color(0xFF475569)),
  ]),
];