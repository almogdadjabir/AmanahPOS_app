import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';
import 'package:solar_icons/solar_icons.dart';

class BackButton extends StatelessWidget {

  const BackButton({super.key,});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.appColors.surface,
      borderRadius: BorderRadius.circular(15),
      child: InkWell(
        onTap: () => Navigator.of(context).pop(),
        borderRadius: BorderRadius.circular(15),
        child: Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: context.appColors.border.withValues(alpha: 0.76),
            ),
          ),
          child: Icon(
            SolarIconsOutline.altArrowLeft,
            color: context.appColors.textPrimary,
            size: 25,
          ),
        ),
      ),
    );
  }
}
