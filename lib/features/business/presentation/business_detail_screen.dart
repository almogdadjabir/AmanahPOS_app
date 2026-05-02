import 'package:amana_pos/features/business/data/models/responses/business_response_dto.dart';
import 'package:amana_pos/features/business/presentation/bloc/business_bloc.dart';
import 'package:amana_pos/features/business/presentation/widgets/detail_app_bar.dart';
import 'package:amana_pos/features/business/presentation/widgets/info_section.dart';
import 'package:amana_pos/features/business/presentation/widgets/shops_section.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/utilities/extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class BusinessDetailScreen extends StatelessWidget {
  final BusinessData business;

  const BusinessDetailScreen({
    super.key,
    required this.business,
  });

  @override
  Widget build(BuildContext context) {
    return BlocSelector<BusinessBloc, BusinessState, BusinessData?>(
      selector: (state) => state.businessList?.firstWhere(
            (b) => b.id == business.id,
        orElse: () => business,
      ),
      builder: (context, data) {
        final b = data ?? business;

        return Scaffold(
          body: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              DetailAppBar(business: b),

              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  AppDims.s4,
                  AppDims.s4,
                  AppDims.s4,
                  0,
                ),
                sliver: SliverToBoxAdapter(
                  child: _BusinessProfileCard(business: b)
                      .animate()
                      .fadeIn(duration: 320.ms)
                      .slideY(
                    begin: 0.06,
                    end: 0,
                    curve: Curves.easeOutCubic,
                  ),
                ),
              ),

              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  AppDims.s4,
                  AppDims.s4,
                  AppDims.s4,
                  0,
                ),
                sliver: SliverToBoxAdapter(
                  child: _SectionTitle(
                    title: 'Business Information',
                    subtitle: 'Basic profile and contact details',
                  ),
                ),
              ),

              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  AppDims.s4,
                  AppDims.s2,
                  AppDims.s4,
                  0,
                ),
                sliver: SliverToBoxAdapter(
                  child: InfoSection(business: b)
                      .animate()
                      .fadeIn(delay: 80.ms, duration: 320.ms)
                      .slideY(
                    begin: 0.06,
                    end: 0,
                    curve: Curves.easeOutCubic,
                  ),
                ),
              ),

              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  AppDims.s4,
                  AppDims.s5,
                  AppDims.s4,
                  0,
                ),
                sliver: SliverToBoxAdapter(
                  child: ShopsSection(
                    shops: b.shops ?? const [],
                    businessId: b.id,
                  )
                      .animate()
                      .fadeIn(delay: 140.ms, duration: 320.ms)
                      .slideY(
                    begin: 0.06,
                    end: 0,
                    curve: Curves.easeOutCubic,
                  ),
                ),
              ),

              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  AppDims.s4,
                  AppDims.s5,
                  AppDims.s4,
                  AppDims.s6,
                ),
                sliver: SliverToBoxAdapter(
                  child: _BusinessSettingsCard()
                      .animate()
                      .fadeIn(delay: 200.ms, duration: 320.ms)
                      .slideY(
                    begin: 0.06,
                    end: 0,
                    curve: Curves.easeOutCubic,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _BusinessProfileCard extends StatelessWidget {
  final BusinessData business;

  const _BusinessProfileCard({
    required this.business,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isActive = business.isActive ?? false;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDims.s4),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppDims.rLg),
        border: Border.all(color: colors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          _BusinessAvatar(business: business),
          const SizedBox(width: AppDims.s3),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  business.name ?? 'Business',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bs600(context).copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  business.address?.isNotEmpty == true
                      ? business.address!
                      : 'No address added yet',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bs300(context).copyWith(
                    color: colors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppDims.s2),
                Row(
                  children: [
                    _SmallInfoChip(
                      icon: Icons.store_outlined,
                      label: '${business.shopCount ?? 0} shops',
                    ),
                    const SizedBox(width: AppDims.s2),
                    _StatusChip(active: isActive),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BusinessAvatar extends StatelessWidget {
  final BusinessData business;

  const _BusinessAvatar({
    required this.business,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
      width: 68,
      height: 68,
      decoration: BoxDecoration(
        color: colors.primaryContainer,
        borderRadius: BorderRadius.circular(AppDims.rLg),
      ),
      alignment: Alignment.center,
      child: business.logo != null
          ? ClipRRect(
        borderRadius: BorderRadius.circular(AppDims.rLg),
        child: Image.network(
          business.logo!,
          width: 68,
          height: 68,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _Initials(business: business),
        ),
      )
          : _Initials(business: business),
    );
  }
}

class _Initials extends StatelessWidget {
  final BusinessData business;

  const _Initials({
    required this.business,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      business.name?.initials ?? '?',
      style: AppTextStyles.bs600(context).copyWith(
        color: context.appColors.primary,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionTitle({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTextStyles.bs600(context).copyWith(
            color: colors.textPrimary,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: AppTextStyles.bs200(context).copyWith(
            color: colors.textHint,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _SmallInfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _SmallInfoChip({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDims.s2,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: colors.surfaceSoft,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: colors.textSecondary),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTextStyles.bs100(context).copyWith(
              color: colors.textSecondary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final bool active;

  const _StatusChip({
    required this.active,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDims.s2,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: active
            ? const Color(0xFF22C55E).withValues(alpha: 0.12)
            : colors.surfaceSoft,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        active ? 'Active' : 'Inactive',
        style: AppTextStyles.bs100(context).copyWith(
          color: active ? const Color(0xFF16A34A) : colors.textHint,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _BusinessSettingsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDims.s3),
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(AppDims.rMd),
        border: Border.all(
          color: colors.primary.withValues(alpha: 0.12),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.lock_outline_rounded,
            color: colors.primary,
            size: 20,
          ),
          const SizedBox(width: AppDims.s2),
          Expanded(
            child: Text(
              'For this MVP, each owner has one business workspace. Multi-business management can be enabled later.',
              style: AppTextStyles.bs200(context).copyWith(
                color: colors.textSecondary,
                fontWeight: FontWeight.w700,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}