import 'package:amana_pos/features/main_screen/data/app_feature.dart';
import 'package:flutter/material.dart';
import 'package:solar_icons/solar_icons.dart';

class FeatureConfig {
  final AppFeature feature;
  final String label;
  final String subtitle;
  final IconData icon;
  final Color color;

  const FeatureConfig({
    required this.feature,
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.color,
  });
}

const kFeatureConfigs = <AppFeature, FeatureConfig>{
  AppFeature.categories: FeatureConfig(
    feature: AppFeature.categories,
    label: 'Categories',
    subtitle: 'Organize your products',
    icon: SolarIconsBold.layers,
    color: Color(0xFF8B5CF6),
  ),

  AppFeature.inventory: FeatureConfig(
    feature: AppFeature.inventory,
    label: 'Stock',
    subtitle: 'Manage inventory levels',
    icon: SolarIconsBold.box,
    color: Color(0xFFEC4899),
  ),

  AppFeature.users: FeatureConfig(
    feature: AppFeature.users,
    label: 'Cashiers',
    subtitle: 'Staff access & accounts',
    icon: SolarIconsBold.userPlus,
    color: Color(0xFF0D9488),
  ),

  AppFeature.customers: FeatureConfig(
    feature: AppFeature.customers,
    label: 'Customers',
    subtitle: 'Profiles and loyalty',
    icon: SolarIconsBold.usersGroupRounded,
    color: Color(0xFF0EA5E9),
  ),
};