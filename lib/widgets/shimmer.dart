import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';

class Shimmer extends StatelessWidget {
  final double width;
  final double height;
  final double radius;

  const Shimmer({super.key,
    required this.width,
    required this.height,
    required this.radius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: context.appColors.border,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}
