import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/core/offline/presentation/widgets/offline_cached_image.dart';
import 'package:amana_pos/features/business/presentation/widgets/home/home_card.dart';
import 'package:amana_pos/features/business/presentation/widgets/home/home_format.dart';
import 'package:amana_pos/features/dashboard/domain/entities/dashboard_summary.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';

/// Best products of the day: initial tile, name, quantity, amount.
class HomeTopSellers extends StatelessWidget {
  final List<TopSeller> sellers;

  const HomeTopSellers({super.key, required this.sellers});

  @override
  Widget build(BuildContext context) {
    if (sellers.isEmpty) return const SizedBox.shrink();
    final tr = context.tr;
    final shown = sellers.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HomeSectionLabel(tr.homeTopSellers),
        HomeCard(
          child: Column(
            children: [
              for (var i = 0; i < shown.length; i++) ...[
                if (i > 0) const HomeHairline(indent: 64),
                _SellerRow(seller: shown[i]),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _SellerRow extends StatelessWidget {
  final TopSeller seller;

  const _SellerRow({required this.seller});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final text = Theme.of(context).textTheme;
    final name = seller.name.trim();
    final initial = name.isEmpty ? '' : String.fromCharCode(name.runes.first);

    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 60),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            _Thumb(seller: seller, initial: initial),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.bodyLarge!.copyWith(
                      fontSize: 17,
                      fontWeight: FontWeight.w500,
                      color: colors.textPrimary,
                    ),
                  ),
                  Directionality(
                    textDirection: Directionality.of(context),
                    child: Text(
                      context.tr.homeSoldQty(homeQty(seller.quantitySold)),
                      style: text.bodySmall!.copyWith(
                        fontSize: 13,
                        color: colors.textHint,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Directionality(
              textDirection: TextDirection.ltr,
              child: Text(
                homeMoney(seller.grossAmount),
                style: text.titleMedium!
                    .copyWith(color: colors.textPrimary)
                    .tabular,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 36px tile: product photo when there is one, else the initial.
class _Thumb extends StatelessWidget {
  final TopSeller seller;
  final String initial;

  const _Thumb({required this.seller, required this.initial});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final text = Theme.of(context).textTheme;

    final fallback = Center(
      child: Text(
        initial,
        style: text.titleSmall!.copyWith(color: colors.textSecondary),
      ),
    );
    final url = seller.thumbnailUrl;

    return Container(
      width: 36,
      height: 36,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: colors.surfaceSoft,
        borderRadius: BorderRadius.circular(10),
      ),
      child: url == null || url.trim().isEmpty
          ? fallback
          : OfflineCachedImage(
              imageUrl: url,
              placeholder: fallback,
              errorWidget: fallback,
            ),
    );
  }
}
