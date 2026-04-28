import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';

class SectionLabel extends StatelessWidget {
  final String label;
  const SectionLabel({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: TextStyle(
        fontFamily: 'NunitoSans', fontSize: 10.5,
        fontWeight: FontWeight.w800,
        color: context.appColors.textHint,
        letterSpacing: 1.2,
      ),
    );
  }
}