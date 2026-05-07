import 'package:amana_pos/features/main_screen/presentation/bloc/navigation_bloc.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:flutter/material.dart';

import '../feature_menu_sections.dart';
import 'section_grid.dart';
import 'section_label.dart';

class MenuSections extends StatelessWidget {
  final NavigationState state;
  const MenuSections({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final sections = buildMenuSections(context, state);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < sections.length; i++) ...[
          SectionLabel(label: sections[i].title),
          const SizedBox(height: AppDims.s2),
          SectionGrid(
            items: sections[i].items,
            onPick: (_) {},
          ),
          if (i < sections.length - 1)
            const SizedBox(height: AppDims.s5),
        ],
      ],
    );
  }
}