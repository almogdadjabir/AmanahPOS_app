import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/theme/app_colors.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';
import 'package:solar_icons/solar_icons.dart';

class SaleFooter extends StatelessWidget {
  const SaleFooter({
    super.key,
    required this.isLoadingMore,
    required this.hasMore,
  });

  final bool isLoadingMore;
  final bool hasMore;

  @override
  Widget build(BuildContext context) {
    if (isLoadingMore) {
      return const _LoadingFooter();
    }

    if (!hasMore) {
      return const _AllLoadedFooter();
    }

    return const SizedBox(height: AppDims.s4);
  }
}

class _LoadingFooter extends StatelessWidget {
  const _LoadingFooter();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsetsDirectional.symmetric(
        vertical: AppDims.s4,
      ),
      child: Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }
}

class _AllLoadedFooter extends StatelessWidget {
  const _AllLoadedFooter();

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Padding(
      padding: const EdgeInsetsDirectional.symmetric(
        vertical: AppDims.s4,
      ),
      child: RepaintBoundary(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              SolarIconsOutline.checkCircle,
              size: 24,
              color: colors.textHint,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                context.tr.allSalesLoaded,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bs400(context).copyWith(
                  color: colors.textHint,
                  fontWeight: FontWeight.w700,
                  height: 1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}