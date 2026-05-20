import 'package:amana_pos/features/inventory/presentation/bloc/inventory_bloc.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solar_icons/solar_icons.dart';

class InventoryAppBar extends StatelessWidget {
  final VoidCallback onAddStock;
  final Future<void> Function() onRefresh;

  const InventoryAppBar({super.key,
    required this.onAddStock,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return SliverAppBar(
      automaticallyImplyLeading: false,
      pinned: true,
      elevation: 0,
      backgroundColor: colors.background,
      surfaceTintColor: Colors.transparent,
      title: Text(
        'Stock',
        style: AppTextStyles.bs600(context).copyWith(
          fontWeight: FontWeight.w900,
          color: colors.textPrimary,
        ),
      ),
      actions: [
        TextButton.icon(
          onPressed: onAddStock,
          icon: Icon(SolarIconsOutline.addCircle,
              size: 18, color: colors.primary),
          label: Text(
            'Add Stock',
            style: AppTextStyles.bs300(context).copyWith(
              fontWeight: FontWeight.w800,
              color: colors.primary,
            ),
          ),
        ),
        const SizedBox(width: AppDims.s1),
      ],
    );
  }
}
