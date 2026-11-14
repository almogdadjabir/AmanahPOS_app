import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';
import 'package:amana_pos/theme/phosphor_icons.dart';

class PlaceholderImage extends StatelessWidget {
  const PlaceholderImage({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: context.appColors.surfaceSoft,
      child: Center(
        child: Icon(PhosphorIconsRegular.package,
            size: 26, color: context.appColors.textHint),
      ),
    );
  }
}