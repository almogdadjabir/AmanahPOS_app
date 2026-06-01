import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/features/category/data/models/responses/category_response_dto.dart';
import 'package:amana_pos/features/category/presentation/bloc/category_bloc.dart';
import 'package:amana_pos/features/category/presentation/category_detail_screen.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/widgets/directional_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solar_icons/solar_icons.dart';

class CategoryCard extends StatelessWidget {
  final CategoryData category;

  const CategoryCard({
    super.key,
    required this.category,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final tr = context.tr;

    final name = category.name?.trim();
    final description = category.description?.trim();
    final isActive = category.isActive ?? false;

    final displayName = name?.isNotEmpty == true ? name! : tr.category;
    final displayDescription = description?.isNotEmpty == true
        ? description!
        : tr.noDescriptionAdded;

    return RepaintBoundary(
      child: Material(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppDims.rLg),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _openDetails(context),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppDims.rLg),
              border: Border.all(color: colors.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.025),
                  blurRadius: 14,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(
                AppDims.s3,
                AppDims.s3,
                AppDims.s3,
                AppDims.s3,
              ),
              child: Row(
                children: [
                  _CategoryIcon(isActive: isActive),

                  const SizedBox(width: AppDims.s3),

                  Expanded(
                    child: _CategoryTextBlock(
                      name: displayName,
                      description: displayDescription,
                      isActive: isActive,
                    ),
                  ),

                  const SizedBox(width: AppDims.s2),

                  _ChevronButton(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _openDetails(BuildContext context) {
    final categoryBloc = context.read<CategoryBloc>();

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) {
          return BlocProvider.value(
            value: categoryBloc,
            child: CategoryDetailScreen(category: category),
          );
        },
      ),
    );
  }
}

class _CategoryIcon extends StatelessWidget {
  final bool isActive;

  const _CategoryIcon({
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final iconColor = isActive ? colors.primary : colors.textHint;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: iconColor.withValues(alpha: isActive ? 0.10 : 0.08),
        borderRadius: BorderRadius.circular(AppDims.rMd),
        border: Border.all(
          color: iconColor.withValues(alpha: isActive ? 0.16 : 0.12),
        ),
      ),
      child: SizedBox(
        width: 52,
        height: 52,
        child: Icon(
          SolarIconsOutline.layersMinimalistic,
          size: 25,
          color: iconColor,
        ),
      ),
    );
  }
}

class _CategoryTextBlock extends StatelessWidget {
  final String name;
  final String description;
  final bool isActive;

  const _CategoryTextBlock({
    required this.name,
    required this.description,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bs500(context).copyWith(
                  fontWeight: FontWeight.w900,
                  color: colors.textPrimary,
                  height: 1.1,
                ),
              ),
            ),

            if (!isActive) ...[
              const SizedBox(width: AppDims.s2),
              const _InactiveDot(),
            ],
          ],
        ),

        const SizedBox(height: 6),

        Text(
          description,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.bs200(context).copyWith(
            fontWeight: FontWeight.w600,
            color: colors.textSecondary,
            height: 1.3,
          ),
        ),
      ],
    );
  }
}

class _InactiveDot extends StatelessWidget {
  const _InactiveDot();

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Tooltip(
      message: context.tr.inactive,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.textHint.withValues(alpha: 0.12),
          shape: BoxShape.circle,
          border: Border.all(
            color: colors.textHint.withValues(alpha: 0.18),
          ),
        ),
        child: SizedBox(
          width: 22,
          height: 22,
          child: Icon(
            SolarIconsOutline.pauseCircle,
            size: 14,
            color: colors.textHint,
          ),
        ),
      ),
    );
  }
}

class _ChevronButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceSoft,
        borderRadius: BorderRadius.circular(999),
      ),
      child: SizedBox(
        width: 32,
        height: 32,
        child: Center(
          child: DirectionalIcon(
            icon: SolarIconsOutline.altArrowRight,
            color: colors.textHint,
            size: 17,
          ),
        ),
      ),
    );
  }
}