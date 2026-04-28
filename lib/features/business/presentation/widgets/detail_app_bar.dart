import 'package:amana_pos/features/business/data/models/responses/business_response_dto.dart';
import 'package:amana_pos/features/business/presentation/widgets/deactivate_business_sheet.dart';
import 'package:amana_pos/features/business/presentation/widgets/edit_business_sheet.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/utilities/extension.dart';
import 'package:flutter/material.dart';

class DetailAppBar extends StatelessWidget {
  final BusinessData business;
  const DetailAppBar({super.key, required this.business});

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 160,
      pinned: true,
      backgroundColor: context.appColors.surface,
      leading: IconButton(
        onPressed: () => Navigator.of(context).pop(),
        icon: Icon(Icons.arrow_back_rounded,
            color: context.appColors.textPrimary),
      ),
      actions: [
        IconButton(
          onPressed: () => showEditBusinessSheet(context, business),
          icon: Icon(Icons.edit_outlined,
              color: context.appColors.textPrimary, size: 20),
          tooltip: 'Edit name',
        ),
        if (business.isActive ?? false)
          IconButton(
            onPressed: () => showDeactivateSheet(context, business),
            icon: Icon(Icons.block_rounded,
                color: context.appColors.danger, size: 20),
            tooltip: 'Deactivate',
          ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          color: context.appColors.surface,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 48),
              Container(
                width: 72, height: 72,
                decoration: BoxDecoration(
                  color: context.appColors.primaryContainer,
                  borderRadius: BorderRadius.circular(AppDims.rMd),
                ),
                alignment: Alignment.center,
                child: business.logo != null
                    ? ClipRRect(
                  borderRadius: BorderRadius.circular(AppDims.rMd),
                  child: Image.network(business.logo!,
                      width: 72, height: 72, fit: BoxFit.cover),
                )
                    : Text(
                  business.name?.initials ?? '?',
                  style: AppTextStyles.lg100(context).copyWith(
                  fontWeight: FontWeight.w800,
                    color: context.appColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: AppDims.s2),
              Text(
                business.name ?? '—',
                style: AppTextStyles.bs500(context).copyWith(
                fontWeight: FontWeight.w800,
                  color: context.appColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
