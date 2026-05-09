import 'package:amana_pos/features/feature_menu/widgets/feature_list_item.dart';
import 'package:amana_pos/features/main_screen/data/section.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';

class SectionGrid extends StatelessWidget {
  final List<SectionItem> items;
  final VoidCallback onPick;

  const SectionGrid({
    super.key,
    required this.items,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Column(
      children: [
        for (int i = 0; i < items.length; i++) ...[
          FeatureListItem(item: items[i], onPick: onPick),
          if (i < items.length - 1)
            Padding(
              padding: const EdgeInsets.only(left: 74),
              child: Divider(
                height: 1,
                thickness: 0.5,
                color: colors.border,
              ),
            ),
        ],
      ],
    );
  }
}