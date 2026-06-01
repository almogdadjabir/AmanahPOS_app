import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';
import 'package:solar_icons/solar_icons.dart';

class ProductsEmpty extends StatelessWidget {
  const ProductsEmpty({
    super.key,
    required this.query,
  });

  final String query;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final trimmedQuery = query.trim();
    final hasQuery = trimmedQuery.isNotEmpty;

    return Center(
      child: Padding(
        padding: const EdgeInsetsDirectional.all(AppDims.s5),
        child: RepaintBoundary(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                SolarIconsOutline.inboxArchive,
                size: 46,
                color: colors.textHint,
              ),
              const SizedBox(height: AppDims.s3),
              Text(
                context.tr.noProductsFound,
                textAlign: TextAlign.center,
                style: AppTextStyles.bs500(context).copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: AppDims.s1),
              Text(
                hasQuery
                    ? context.tr.nothingMatchesQuery(trimmedQuery)
                    : context.tr.tryAnotherCategoryOrAddProducts,
                textAlign: TextAlign.center,
                style: AppTextStyles.bs200(context).copyWith(
                  color: colors.textSecondary,
                  fontWeight: FontWeight.w600,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}