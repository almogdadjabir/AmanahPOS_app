import 'package:amana_pos/features/sales_history/presentation/bloc/sales_history_bloc.dart';
import 'package:amana_pos/theme/app_colors.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SaleAppBar extends StatelessWidget implements PreferredSizeWidget {
  const SaleAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return AppBar(
      backgroundColor: colors.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      titleSpacing: AppDims.s4,
      title: Row(
        children: [
          Container(
            width: 34, height: 34,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
                Icons.receipt_long_rounded, size: 18, color: Colors.white),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('AMANAPOS',
                  style: AppTextStyles.sm100(context).copyWith(
                    color: AppColors.primary, fontSize: 10,
                    letterSpacing: 1.0, fontWeight: FontWeight.w700, height: 1,
                  )),
              Text('Sales history',
                  style: AppTextStyles.bs200(context).copyWith(
                    fontWeight: FontWeight.w700, fontSize: 17, height: 1.3,
                  )),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh_rounded),
          color: colors.textSecondary,
          tooltip: 'Refresh',
          onPressed: () => context
              .read<SalesHistoryBloc>()
              .add(const SalesHistoryRefreshed()),
        ),
      ],
    );
  }
}
