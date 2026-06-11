import 'package:amana_pos/config/router/route_strings.dart';
import 'package:amana_pos/core/responsive/responsive.dart';
import 'package:amana_pos/features/business/data/models/responses/business_response_dto.dart';
import 'package:amana_pos/features/business/presentation/widgets/workspace/subscription_plan_card.dart';
import 'package:amana_pos/features/business/presentation/widgets/workspace/workspace_action_card.dart';
import 'package:amana_pos/features/dashboard/presentation/bloc/dashboard_summary_bloc.dart';
import 'package:amana_pos/features/main_screen/presentation/widgets/today_cards.dart';
import 'package:amana_pos/features/products/presentation/bloc/product_bloc.dart';
import 'package:amana_pos/features/users/presentation/bloc/users_bloc.dart';
import 'package:amana_pos/theme/app_colors.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/widgets/workspace_section_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:solar_icons/solar_icons.dart';

class SingleBusinessWorkspace extends StatelessWidget {
  final BusinessData data;

  const SingleBusinessWorkspace({
    super.key,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    if (context.isDesktop) {
      return _DesktopWorkspace(data: data);
    }
    return _MobileWorkspace(data: data);
  }
}


class _DesktopWorkspace extends StatelessWidget {
  final BusinessData data;
  const _DesktopWorkspace({required this.data});

  @override
  Widget build(BuildContext context) {
    final shopCount = data.shopCount ?? 0;
    final productCount = context.read<ProductBloc>().state.products.length;
    final cashierCount = context.read<UserBloc>().state.userList.length;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(0, AppDims.s4, 0, AppDims.s4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: BlocBuilder<DashboardSummaryBloc, DashboardSummaryState>(
                buildWhen: (prev, curr) =>
                    prev.status != curr.status || prev.summary != curr.summary,
                builder: (context, state) {
                  final summary = state.summary;
                  final todayCard = summary == null
                      ? OwnerTodayHeroCard(
                          amount: 0,
                          salesCount: 0,
                          sparkline: const [0, 0],
                          liveLabel: state.isLoading ? '…' : 'NO DATA',
                        )
                      : OwnerTodayHeroCard(
                          amount: summary.today.grossSalesAmount,
                          salesCount: summary.today.salesCount,
                          sparkline: summary.sparklineAmounts.isEmpty
                              ? const [0, 0]
                              : summary.sparklineAmounts,
                          dateLabel:
                              _dashboardDateLabel(context, summary.today.date),
                          liveLabel: summary.liveLabel,
                          currencyLabel: summary.currency,
                        );

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        flex: 10,
                        child: todayCard
                            .animate()
                            .fadeIn(duration: 350.ms)
                            .slideY(
                              begin: 0.08,
                              end: 0,
                              curve: Curves.easeOutCubic,
                            ),
                      ),
                      const SizedBox(width: AppDims.s3),
                      Expanded(
                        flex: 9,
                        child: _DesktopModuleGrid(
                          shopCount: shopCount,
                          productCount: productCount,
                          cashierCount: cashierCount,
                          data: data,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: AppDims.s3),
            _DesktopSubscriptionStrip(data: data)
                .animate()
                .fadeIn(duration: 350.ms, delay: 200.ms)
                .slideY(
                  begin: 0.05,
                  end: 0,
                  curve: Curves.easeOutCubic,
                ),
          ],
        ),
      ),
    );
  }
}

// ── Desktop 2×2 module grid ───────────────────────────────────────────────────

class _DesktopModuleGrid extends StatelessWidget {
  final int shopCount;
  final int productCount;
  final int cashierCount;
  final BusinessData data;

  const _DesktopModuleGrid({
    required this.shopCount,
    required this.productCount,
    required this.cashierCount,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _DesktopModuleCard(
                  icon: const Icon(SolarIconsOutline.shop),
                  title: context.tr.bizShopsTitle,
                  value: shopCount.toString(),
                  subtitle: shopCount == 1
                      ? context.tr.bizActiveBranch
                      : context.tr.bizActiveBranches,
                  accentColor: AppColors.primary,
                  animDelay: 60,
                  onTap: () => Navigator.of(context).pushNamed(
                    RouteStrings.shopManagementScreen,
                    arguments: {'businessData': data},
                  ),
                ),
              ),
              const SizedBox(width: AppDims.s3),
              Expanded(
                child: _DesktopModuleCard(
                  icon: const Icon(SolarIconsOutline.box),
                  title: context.tr.productsManagement,
                  value: productCount.toString(),
                  subtitle: productCount == 1
                      ? context.tr.bizProductsItem
                      : context.tr.bizProductsItems,
                  accentColor: AppColors.info,
                  animDelay: 120,
                  onTap: () =>
                      Navigator.of(context).pushNamed(RouteStrings.productScreen),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppDims.s3),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _DesktopModuleCard(
                  icon: const Icon(SolarIconsOutline.usersGroupRounded),
                  title: context.tr.settingsCashiers,
                  value: cashierCount.toString(),
                  subtitle: cashierCount == 1
                      ? context.tr.bizUserSingular
                      : context.tr.bizUserPlural,
                  accentColor: AppColors.secondary,
                  animDelay: 180,
                  onTap: () =>
                      Navigator.of(context).pushNamed(RouteStrings.cashiersScreen),
                ),
              ),
              const SizedBox(width: AppDims.s3),
              Expanded(
                child: _DesktopModuleCard(
                  icon: const Icon(SolarIconsOutline.notebook),
                  title: context.tr.navReports,
                  subtitle: context.tr.bizReportSubtitle,
                  accentColor: AppColors.success,
                  animDelay: 240,
                  onTap: () => Navigator.of(context)
                      .pushNamed(RouteStrings.salesHistoryScreen),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Desktop module card (hover-aware) ─────────────────────────────────────────

class _DesktopModuleCard extends StatefulWidget {
  final Widget icon;
  final String title;
  final String? value;
  final String subtitle;
  final Color accentColor;
  final int animDelay;
  final VoidCallback onTap;

  const _DesktopModuleCard({
    required this.icon,
    required this.title,
    this.value,
    required this.subtitle,
    required this.accentColor,
    this.animDelay = 0,
    required this.onTap,
  });

  @override
  State<_DesktopModuleCard> createState() => _DesktopModuleCardState();
}

class _DesktopModuleCardState extends State<_DesktopModuleCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final accent = widget.accentColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppDims.rXl),
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(AppDims.rXl),
          splashColor: accent.withValues(alpha: 0.08),
          highlightColor: accent.withValues(alpha: 0.04),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOut,
            padding: const EdgeInsets.all(AppDims.s4),
            decoration: BoxDecoration(
              color: _hovered
                  ? accent.withValues(alpha: isDark ? 0.10 : 0.06)
                  : colors.surface.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(AppDims.rXl),
              border: Border.all(
                color: _hovered
                    ? accent.withValues(alpha: 0.58)
                    : colors.border.withValues(alpha: 0.75),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon badge
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: isDark ? 0.18 : 0.12),
                    borderRadius: BorderRadius.circular(AppDims.rMd),
                    border: Border.all(
                      color: accent.withValues(alpha: 0.28),
                    ),
                  ),
                  child: Center(
                    child: IconTheme(
                      data: IconThemeData(color: accent, size: 20),
                      child: widget.icon,
                    ),
                  ),
                ),
                const Spacer(),
                // Count
                if (widget.value != null) ...[
                  Text(
                    widget.value!,
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      color: colors.textPrimary,
                      height: 1,
                      letterSpacing: -1.0,
                    ),
                  ),
                  const SizedBox(height: AppDims.s1),
                ],
                // Label
                Text(
                  widget.title,
                  style: AppTextStyles.bs300(context).copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: AppDims.s2),
                // Subtitle + arrow
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        widget.subtitle,
                        style: AppTextStyles.sm300(context).copyWith(
                          color: colors.textSecondary,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Icon(
                      SolarIconsOutline.arrowRight,
                      size: 13,
                      color: _hovered ? accent : colors.textHint,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(
          duration: 320.ms,
          delay: Duration(milliseconds: widget.animDelay),
        )
        .slideY(
          begin: 0.08,
          end: 0,
          curve: Curves.easeOutCubic,
        );
  }
}

// ── Desktop subscription strip ────────────────────────────────────────────────

class _DesktopSubscriptionStrip extends StatelessWidget {
  final BusinessData data;

  const _DesktopSubscriptionStrip({required this.data});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final sub = data.activeSubscription;

    final isFree = sub?.isFree ?? true;
    final daysLeft = sub?.daysRemaining ?? 0;
    final isExpired = sub != null && !isFree && daysLeft <= 0;
    final isExpiringSoon =
        sub != null && !isFree && daysLeft > 0 && daysLeft <= 7;

    final accentColor = _resolveAccent(
      subExists: sub != null,
      isExpired: isExpired,
      isExpiringSoon: isExpiringSoon,
    );

    final title = sub?.name ?? 'No active subscription';
    final expiryLabel = _expiryLabel(
      isFree: isFree,
      isExpired: isExpired,
      daysLeft: daysLeft,
      hasSubscription: sub != null,
    );
    final progress = _progressValue(
      isFree: isFree,
      isExpired: isExpired,
      daysLeft: daysLeft,
      hasSubscription: sub != null,
    );

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDims.s4,
        vertical: AppDims.s3,
      ),
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(AppDims.rXl),
        border: Border.all(
          color: colors.border.withValues(alpha: 0.75),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Plan icon
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppDims.rMd),
              border: Border.all(color: accentColor.withValues(alpha: 0.28)),
            ),
            child: Center(
              child: Icon(
                isFree
                    ? SolarIconsOutline.gift
                    : SolarIconsOutline.medalRibbon,
                color: accentColor,
                size: 17,
              ),
            ),
          ),
          const SizedBox(width: AppDims.s3),
          // Plan name + expiry badge
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.bs300(context).copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w900,
                  height: 1.1,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 3),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(AppDims.rXs),
                ),
                child: Text(
                  expiryLabel,
                  style: AppTextStyles.sm100(context).copyWith(
                    color: accentColor,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: AppDims.s5),
          // Progress bar + limits
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 5,
                    backgroundColor: colors.border.withValues(alpha: 0.35),
                    valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                  ),
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    _StripLimit(label: 'Shops', value: sub?.maxShops),
                    _StripDot(),
                    _StripLimit(label: 'Products', value: sub?.maxProducts),
                    _StripDot(),
                    _StripLimit(label: 'Users', value: sub?.maxUsers),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: AppDims.s4),
          // Upgrade CTA
          TextButton(
            onPressed: () {},
            style: TextButton.styleFrom(
              foregroundColor: accentColor,
              backgroundColor: accentColor.withValues(alpha: 0.10),
              padding: const EdgeInsets.symmetric(
                horizontal: AppDims.s4,
                vertical: AppDims.s2,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDims.rMd),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  sub == null ? 'Activate' : 'Upgrade',
                  style: AppTextStyles.bs100(context).copyWith(
                    color: accentColor,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(width: AppDims.s1),
                Icon(SolarIconsOutline.arrowRight, size: 14, color: accentColor),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _resolveAccent({
    required bool subExists,
    required bool isExpired,
    required bool isExpiringSoon,
  }) {
    if (!subExists) return const Color(0xFFF59E0B);
    if (isExpired) return const Color(0xFFEF4444);
    if (isExpiringSoon) return const Color(0xFFF59E0B);
    return const Color(0xFF0D9488);
  }

  double _progressValue({
    required bool isFree,
    required bool isExpired,
    required int daysLeft,
    required bool hasSubscription,
  }) {
    if (!hasSubscription) return 0;
    if (isFree) return 1;
    if (isExpired) return 0;
    const assumedBillingCycleDays = 30;
    return (daysLeft / assumedBillingCycleDays).clamp(0.0, 1.0);
  }

  String _expiryLabel({
    required bool isFree,
    required bool isExpired,
    required int daysLeft,
    required bool hasSubscription,
  }) {
    if (!hasSubscription) return 'Inactive';
    if (isFree) return 'No expiry';
    if (isExpired) return 'Expired';
    if (daysLeft == 1) return '1 day';
    return '$daysLeft days';
  }
}

class _StripLimit extends StatelessWidget {
  final String label;
  final int? value;

  const _StripLimit({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final limitText = (value == null || value! <= 0) ? '∞' : '$value';
    return Text(
      '$label $limitText',
      style: AppTextStyles.sm100(context).copyWith(
        color: colors.textSecondary,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _StripDot extends StatelessWidget {
  const _StripDot();

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      width: 3,
      height: 3,
      margin: const EdgeInsets.symmetric(horizontal: AppDims.s2),
      decoration: BoxDecoration(
        color: colors.textHint.withValues(alpha: 0.5),
        shape: BoxShape.circle,
      ),
    );
  }
}


class _MobileWorkspace extends StatelessWidget {
  final BusinessData data;
  const _MobileWorkspace({required this.data});

  @override
  Widget build(BuildContext context) {
    final shopCount = data.shopCount ?? 0;
    final productCount = context.read<ProductBloc>().state.products.length;
    final cashierCount = context.read<UserBloc>().state.userList.length;

    return SafeArea(
      child: CustomScrollView(
        clipBehavior: Clip.none,
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppDims.s4,
              AppDims.s2,
              AppDims.s4,
              0,
            ),
            sliver: SliverToBoxAdapter(
              child: BlocBuilder<DashboardSummaryBloc, DashboardSummaryState>(
                buildWhen: (prev, curr) =>
                    prev.status != curr.status || prev.summary != curr.summary,
                builder: (context, state) {
                  final summary = state.summary;

                  if (state.isLoading && summary == null) {
                    return const SizedBox(
                      height: 170,
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  if (summary == null) {
                    return OwnerTodayCard(
                      amount: 0,
                      salesCount: 0,
                      sparkline: const [0, 0],
                      liveLabel: 'NO DATA',
                    );
                  }

                  return OwnerTodayCard(
                    amount: summary.today.grossSalesAmount,
                    salesCount: summary.today.salesCount,
                    sparkline: summary.sparklineAmounts.isEmpty
                        ? const [0, 0]
                        : summary.sparklineAmounts,
                    dateLabel:
                        _dashboardDateLabel(context, summary.today.date),
                    liveLabel: summary.liveLabel,
                    currencyLabel: summary.currency,
                  );
                },
              )
                  .animate()
                  .fadeIn(duration: 350.ms)
                  .slideY(
                begin: 0.08,
                end: 0,
                curve: Curves.easeOutCubic,
              ),
            ),
          ),

          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              AppDims.s4,
              AppDims.s5,
              AppDims.s4,
              0,
            ),
            sliver: SliverToBoxAdapter(
              child: WorkspaceSectionHeader(title: context.tr.bizManageLabel),
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
              child: GridView.count(
                crossAxisCount: context.isTablet ? 4 : 2,
                shrinkWrap: true,
                clipBehavior: Clip.none,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: AppDims.s3,
                crossAxisSpacing: AppDims.s3,
                childAspectRatio: context.isTablet ? 1.8 : 2.38,
                children: [
                  WorkspaceActionCard(
                    icon: const Icon(SolarIconsOutline.shop),
                    title: context.tr.bizShopsTitle,
                    value: shopCount.toString(),
                    subtitle: shopCount == 1
                        ? context.tr.bizActiveBranch
                        : context.tr.bizActiveBranches,
                    onTap: () => Navigator.of(context).pushNamed(
                      RouteStrings.shopManagementScreen,
                      arguments: {'businessData': data},
                    ),
                  ),
                  WorkspaceActionCard(
                    icon: const Icon(SolarIconsOutline.box),
                    title: context.tr.productsManagement,
                    value: productCount.toString(),
                    subtitle: productCount == 1
                        ? context.tr.bizProductsItem
                        : context.tr.bizProductsItems,
                    onTap: () =>
                        Navigator.of(context).pushNamed(RouteStrings.productScreen),
                  ),
                  WorkspaceActionCard(
                    icon: const Icon(SolarIconsOutline.usersGroupRounded),
                    title: context.tr.settingsCashiers,
                    value: cashierCount.toString(),
                    subtitle: cashierCount == 1
                        ? context.tr.bizUserSingular
                        : context.tr.bizUserPlural,
                    onTap: () =>
                        Navigator.of(context).pushNamed(RouteStrings.cashiersScreen),
                  ),
                  WorkspaceActionCard(
                    icon: const Icon(SolarIconsOutline.notebook),
                    title: context.tr.navReports,
                    subtitle: context.tr.bizReportSubtitle,
                    onTap: () => Navigator.of(context)
                        .pushNamed(RouteStrings.salesHistoryScreen),
                  ),
                ],
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
              child: SubscriptionPlanCard(data: data),
            ),
          ),
        ],
      ),
    );
  }
}

String _dashboardDateLabel(BuildContext context, String value) {
  final parsed = DateTime.tryParse(value);
  final todayLabel = context.tr.today;
  if (parsed == null) return todayLabel;
  final locale = Localizations.localeOf(context).toLanguageTag();
  final formattedDate = DateFormat('dd MMM yyyy', locale).format(parsed);
  return '$todayLabel · $formattedDate';
}
