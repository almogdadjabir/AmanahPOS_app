import 'package:amana_pos/config/router/route_strings.dart';
import 'package:amana_pos/features/business/data/models/responses/business_response_dto.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/utilities/extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class SingleBusinessWorkspace extends StatelessWidget {
  final BusinessData data;

  const SingleBusinessWorkspace({
    super.key,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isActive = data.isActive ?? false;

    return SafeArea(
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppDims.s4,
              AppDims.s4,
              AppDims.s4,
              AppDims.s2,
            ),
            sliver: SliverToBoxAdapter(
              child: _WorkspaceHeader(data: data, isActive: isActive)
                  .animate()
                  .fadeIn(duration: 350.ms)
                  .slideY(begin: 0.08, end: 0, curve: Curves.easeOutCubic),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppDims.s4,
              AppDims.s3,
              AppDims.s4,
              0,
            ),
            sliver: SliverToBoxAdapter(
              child: _BusinessSummaryCard(data: data)
                  .animate()
                  .fadeIn(delay: 90.ms, duration: 350.ms)
                  .slideY(begin: 0.08, end: 0, curve: Curves.easeOutCubic),
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
              child: Text(
                'Workspace',
                style: AppTextStyles.bs600(context).copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppDims.s4,
              AppDims.s3,
              AppDims.s4,
              0,
            ),
            sliver: SliverGrid(
              delegate: SliverChildListDelegate.fixed([
                _WorkspaceActionCard(
                  icon: Icons.store_mall_directory_rounded,
                  title: 'Shops',
                  subtitle: 'Manage locations',
                  onTap: () {
                    Navigator.of(context).pushNamed(
                      RouteStrings.shopManagementScreen,
                      arguments: {'businessData': data},
                    );
                  },
                ),
                _WorkspaceActionCard(
                  icon: Icons.inventory_2_rounded,
                  title: 'Products',
                  subtitle: 'Catalog & stock',
                  onTap: () {
                    // TODO: replace with your products route.
                  },
                ),
                _WorkspaceActionCard(
                  icon: Icons.point_of_sale_rounded,
                  title: 'Cashiers',
                  subtitle: 'Team access',
                  onTap: () {
                    // TODO: replace with your users/cashiers route.
                  },
                ),
                _WorkspaceActionCard(
                  icon: Icons.bar_chart_rounded,
                  title: 'Reports',
                  subtitle: 'Sales insights',
                  onTap: () {
                    // TODO: replace with your reports route.
                  },
                ),
              ]),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: AppDims.s3,
                crossAxisSpacing: AppDims.s3,
                childAspectRatio: 1.28,
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppDims.s4,
              AppDims.s4,
              AppDims.s4,
              AppDims.s5,
            ),
            sliver: SliverToBoxAdapter(
              child: _MvpNotice()
                  .animate()
                  .fadeIn(delay: 180.ms, duration: 350.ms)
                  .slideY(begin: 0.08, end: 0, curve: Curves.easeOutCubic),
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkspaceHeader extends StatelessWidget {
  final BusinessData data;
  final bool isActive;

  const _WorkspaceHeader({
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
        _StatusBadge(active: isActive),
      ],
    );
  }
}

class _BusinessSummaryCard extends StatelessWidget {
  final BusinessData data;

  const _BusinessSummaryCard({
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isActive = data.isActive ?? false;

    return Container(
      padding: const EdgeInsets.all(AppDims.s4),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppDims.rLg),
        border: Border.all(
          color: colors.border,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              _BusinessLogo(data: data),
              const SizedBox(width: AppDims.s3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.name ?? 'Business',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bs600(context).copyWith(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      data.address?.isNotEmpty == true
                          ? data.address!
                          : 'No address added yet',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bs200(context).copyWith(
                        color: colors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: AppDims.s4),

          Row(
            children: [
              Expanded(
                child: _MetricTile(
                  icon: Icons.store_outlined,
                  label: 'Shops',
                  value: '${data.shopCount ?? 0}',
                ),
              ),
              const SizedBox(width: AppDims.s2),
              Expanded(
                child: _MetricTile(
                  icon: isActive
                      ? Icons.check_circle_outline_rounded
                      : Icons.pause_circle_outline_rounded,
                  label: 'Status',
                  value: isActive ? 'Active' : 'Inactive',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BusinessLogo extends StatelessWidget {
  final BusinessData data;

  const _BusinessLogo({
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: colors.primaryContainer,
        borderRadius: BorderRadius.circular(AppDims.rMd),
      ),
      alignment: Alignment.center,
      child: data.logo != null
          ? ClipRRect(
        borderRadius: BorderRadius.circular(AppDims.rMd),
        child: Image.network(
          data.logo!,
          width: 64,
          height: 64,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _Initials(data: data),
        ),
      )
          : _Initials(data: data),
    );
  }
}

class _Initials extends StatelessWidget {
  final BusinessData data;

  const _Initials({
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      data.name?.initials ?? '?',
      style: AppTextStyles.bs600(context).copyWith(
        color: context.appColors.primary,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _MetricTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
      padding: const EdgeInsets.all(AppDims.s3),
      decoration: BoxDecoration(
        color: colors.surfaceSoft,
        borderRadius: BorderRadius.circular(AppDims.rMd),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: colors.primary,
          ),
          const SizedBox(width: AppDims.s2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bs400(context).copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bs100(context).copyWith(
                    color: colors.textHint,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkspaceActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _WorkspaceActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(AppDims.rLg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDims.rLg),
        child: Container(
          padding: const EdgeInsets.all(AppDims.s3),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppDims.rLg),
            border: Border.all(color: colors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(AppDims.rMd),
                ),
                child: Icon(
                  icon,
                  color: colors.primary,
                  size: 23,
                ),
              ),
              const Spacer(),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bs400(context).copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bs100(context).copyWith(
                  color: colors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 300.ms)
        .slideY(begin: 0.08, end: 0, curve: Curves.easeOutCubic);
  }
}

class _MvpNotice extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDims.s3),
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppDims.rMd),
        border: Border.all(
          color: colors.primary.withValues(alpha: 0.12),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: colors.primary,
            size: 20,
          ),
          const SizedBox(width: AppDims.s2),
          Expanded(
            child: Text(
              'For this MVP, AmanaPOS is configured for one business workspace.',
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

class _StatusBadge extends StatelessWidget {
  final bool active;

  const _StatusBadge({
    required this.active,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDims.s2,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: active
            ? const Color(0xFF22C55E).withValues(alpha: 0.12)
            : colors.surfaceSoft,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        active ? 'Active' : 'Inactive',
        style: AppTextStyles.bs200(context).copyWith(
          color: active ? const Color(0xFF16A34A) : colors.textHint,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}