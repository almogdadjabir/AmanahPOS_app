import 'package:amana_pos/features/main_screen/data/app_feature.dart';
import 'package:flutter/material.dart';

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