import 'package:amana_pos/features/main_screen/data/app_feature.dart';
import 'package:flutter/material.dart';

class NavTab {
  final AppFeature? feature;
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isMore;

  const NavTab({
    this.feature,
    required this.icon,
    required this.activeIcon,
    required this.label,
    this.isMore = false,
  });
}
