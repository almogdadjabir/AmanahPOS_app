import 'package:amana_pos/features/inventory/presentation/bloc/inventory_bloc.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class InventoryAppBar extends StatelessWidget {
  const InventoryAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      automaticallyImplyLeading: false,
      pinned: true,
      elevation: 0,
      backgroundColor: context.appColors.background,
      surfaceTintColor: Colors.transparent,
      title: Text(
        'Stock Management',
        style: AppTextStyles.bs600(context).copyWith(
          fontWeight: FontWeight.w900,
          color: context.appColors.textPrimary,
        ),
      ),
      actions: [
        IconButton(
          tooltip: 'Refresh stock',
          onPressed: () {
            context.read<InventoryBloc>().add(const OnInventoryInitial());
          },
          icon: Icon(
            Icons.refresh_rounded,
            color: context.appColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
