import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/features/business/presentation/widgets/home/home_card.dart';
import 'package:amana_pos/features/main_screen/data/app_feature.dart';
import 'package:amana_pos/features/main_screen/presentation/bloc/navigation_bloc.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/widgets/app_button.dart';
import 'package:amana_pos/widgets/shimmer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Skeleton in the final layout while the first summary loads.
class HomeSkeleton extends StatelessWidget {
  const HomeSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    const wide = double.infinity;

    return AppSkeleton(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const HomeCard(
            padding: EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Shimmer(width: 90, height: 16, radius: 8),
                SizedBox(height: 12),
                Shimmer(width: 220, height: 44, radius: 8),
                SizedBox(height: 16),
                Shimmer(width: wide, height: 78, radius: 8),
              ],
            ),
          ),
          const HomeSectionLabel(' '),
          const HomeCard(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                Shimmer(width: wide, height: 10, radius: 99),
                SizedBox(height: 20),
                Shimmer(width: wide, height: 18, radius: 8),
                SizedBox(height: 16),
                Shimmer(width: wide, height: 18, radius: 8),
              ],
            ),
          ),
          const HomeSectionLabel(' '),
          HomeCard(
            child: Column(
              children: [
                for (var i = 0; i < 3; i++) ...[
                  if (i > 0) const HomeHairline(indent: 64),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        Shimmer(width: 36, height: 36, radius: 10),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Shimmer(width: 150, height: 14, radius: 7),
                              SizedBox(height: 6),
                              Shimmer(width: 70, height: 11, radius: 6),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Zero state under the hero card: invites the first sale.
class HomeEmptyCard extends StatelessWidget {
  const HomeEmptyCard({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final text = Theme.of(context).textTheme;
    final tr = context.tr;

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: HomeCard(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
        child: SizedBox(
          width: double.infinity,
          child: Column(
            children: [
              Text(
                tr.homeNoSalesTitle,
                textAlign: TextAlign.center,
                style: text.titleMedium!.copyWith(color: colors.textPrimary),
              ),
              const SizedBox(height: 6),
              Text(
                tr.homeNoSalesBody,
                textAlign: TextAlign.center,
                style: text.bodyMedium!.copyWith(
                  fontSize: 15,
                  color: colors.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              AppButton(
                label: tr.homeStartSelling,
                onPressed: () => context.read<NavigationBloc>().add(
                  const NavigationFeatureSelected(AppFeature.pos),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
