import 'package:amana_pos/features/business/data/models/responses/business_response_dto.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';

class WorkspaceHeader extends StatelessWidget {
  final BusinessData data;
  final bool isActive;

  const WorkspaceHeader({super.key,
    required this.data,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Business Workspace',
                style: AppTextStyles.lg200(context).copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Manage your POS setup from one place.',
                style: AppTextStyles.bs300(context).copyWith(
                  color: colors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),

        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDims.s2,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: isActive
                ? const Color(0xFF22C55E).withValues(alpha: 0.12)
                : colors.surfaceSoft,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            isActive ? 'Active' : 'Inactive',
            style: AppTextStyles.bs200(context).copyWith(
              color: isActive ? const Color(0xFF16A34A) : colors.textHint,
              fontWeight: FontWeight.w900,
            ),
          ),
        )
      ],
    );
  }


}
