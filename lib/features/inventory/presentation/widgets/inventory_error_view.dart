import 'package:amana_pos/features/inventory/presentation/bloc/inventory_bloc.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class InventoryErrorView extends StatelessWidget {
  final String? message;

  const InventoryErrorView({super.key,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDims.s5),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off_rounded,
              size: 48,
              color: context.appColors.textHint,
            ),
            const SizedBox(height: AppDims.s3),
            Text(
              'Something went wrong',
              style: AppTextStyles.bs500(context).copyWith(
                fontWeight: FontWeight.w800,
                color: context.appColors.textPrimary,
              ),
            ),
            if (message != null) ...[
              const SizedBox(height: AppDims.s2),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: AppTextStyles.bs200(context).copyWith(
                  color: context.appColors.textSecondary,
                ),
              ),
            ],
            const SizedBox(height: AppDims.s4),
            OutlinedButton.icon(
              onPressed: () {
                context.read<InventoryBloc>().add(const OnInventoryInitial());
              },
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
