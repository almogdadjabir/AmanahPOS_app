import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/core/offline/presentation/widgets/offline_cached_image.dart';
import 'package:amana_pos/utilities/content_direction.dart';
import 'package:amana_pos/features/products/data/model/response/category_products_response_dto.dart';
import 'package:amana_pos/features/products/presentation/utils/product_image_url.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/widgets/directional_icon.dart';
import 'package:flutter/material.dart';
import 'package:solar_icons/solar_icons.dart';

class ProductDetailAppBarView extends StatelessWidget {
  final ProductData product;

  const ProductDetailAppBarView({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final tr = context.tr;

    final imageUrl = product.detailImageUrl;

    final rawProductName = product.name?.trim();
    final productName = rawProductName?.isNotEmpty == true
        ? rawProductName!
        : tr.product;

    final rawCategoryName = product.categoryName?.trim();
    final categoryName = rawCategoryName?.isNotEmpty == true
        ? rawCategoryName!
        : tr.noCategory;

    final isInactive = product.isActive == false;

    return SliverAppBar(
      pinned: true,
      stretch: true,
      expandedHeight: 292,
      elevation: 0,
      backgroundColor: colors.background,
      surfaceTintColor: Colors.transparent,
      automaticallyImplyLeading: false,
      titleSpacing: 0,
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [
          StretchMode.zoomBackground,
          StretchMode.blurBackground,
        ],
        background: Stack(
          fit: StackFit.expand,
          children: [
            RepaintBoundary(
              child: OfflineCachedImage(imageUrl: imageUrl, fit: BoxFit.cover),
            ),

            const _HeaderGradientOverlay(),

            const PositionedDirectional(
              start: AppDims.s4,
              end: AppDims.s4,
              top: 0,
              child: _BackButtonArea(),
            ),

            PositionedDirectional(
              start: AppDims.s4,
              end: AppDims.s4,
              bottom: AppDims.s4,
              child: _ProductHeaderInfo(
                productName: productName,
                categoryName: categoryName,
                isInactive: isInactive,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BackButtonArea extends StatelessWidget {
  const _BackButtonArea();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.only(top: AppDims.s2),
        child: Row(
          children: [
            _HeroIconButton(
              icon: SolarIconsOutline.altArrowLeft,
              onTap: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductHeaderInfo extends StatelessWidget {
  final String productName;
  final String categoryName;
  final bool isInactive;

  const _ProductHeaderInfo({
    required this.productName,
    required this.categoryName,
    required this.isInactive,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: AppDims.s2,
          runSpacing: AppDims.s2,
          children: [
            _CategoryPill(label: categoryName),
            if (isInactive) const _InactivePill(),
          ],
        ),

        const SizedBox(height: AppDims.s3),

        // Full width so a single-line RTL name aligns to the right
        // instead of shrink-wrapping at the left edge.
        SizedBox(
          width: double.infinity,
          child: Text(
            productName,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textDirection: productName.contentDirection,
            style: AppTextStyles.lg200(context).copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              height: 1.05,
              letterSpacing: -0.5,
              shadows: [
                Shadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _HeaderGradientOverlay extends StatelessWidget {
  const _HeaderGradientOverlay();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withValues(alpha: 0.18),
              Colors.black.withValues(alpha: 0.18),
              Colors.black.withValues(alpha: 0.72),
            ],
            stops: const [0.0, 0.42, 1.0],
          ),
        ),
      ),
    );
  }
}

class _HeroIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _HeroIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.38),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
          ),
          child: const SizedBox(
            width: 46,
            height: 46,
            child: Center(
              child: DirectionalIcon(
                icon: SolarIconsOutline.altArrowLeft,
                color: Colors.white,
                size: 23,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryPill extends StatelessWidget {
  final String label;

  const _CategoryPill({required this.label});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDims.s3,
          vertical: 7,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              SolarIconsOutline.tag,
              color: Colors.white.withValues(alpha: 0.92),
              size: 14,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bs200(context).copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
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

class _InactivePill extends StatelessWidget {
  const _InactivePill();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFDC2626).withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: const Color(0xFFDC2626).withValues(alpha: 0.38),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDims.s3,
          vertical: 7,
        ),
        child: Text(
          context.tr.inactive,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.bs200(context).copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            height: 1,
          ),
        ),
      ),
    );
  }
}
