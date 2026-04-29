import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';


class LoadMoreIndicator extends StatelessWidget {
  const LoadMoreIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppDims.s4),
      child: Center(
        child: SizedBox(
          width: 22, height: 22,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            color: context.appColors.primary,
          ),
        ),
      ),
    );
  }
}