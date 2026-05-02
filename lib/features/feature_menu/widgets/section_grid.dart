import 'package:amana_pos/features/main_screen/data/section.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:flutter/material.dart';
import 'feature_tile.dart';

class SectionGrid extends StatelessWidget {
  final List<SectionItem> items;
  final ValueChanged<SectionItem> onPick;
  const SectionGrid({super.key, required this.items, required this.onPick});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: AppDims.s3,
      crossAxisSpacing: AppDims.s3,
      childAspectRatio: 2.15,
      children: items
          .map((it) => FeatureTile(
        item: it,
        onTap: () => onPick(it),
      ))
          .toList(),
    );
  }
}