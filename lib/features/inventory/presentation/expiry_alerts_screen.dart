// lib/features/inventory/presentation/expiry_alerts_screen.dart
//
// Shop only — the route must only be reachable for shop business type.
// The screen shows expired and expiring-soon stock items fetched from
// GET /api/v1/inventory/expiry-alerts/

import 'package:amana_pos/features/inventory/presentation/bloc/expiry_bloc.dart';
import 'package:amana_pos/features/inventory/presentation/widgets/expiry_alert_card.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ExpiryAlertsScreen extends StatefulWidget {
  const ExpiryAlertsScreen({super.key});

  @override
  State<ExpiryAlertsScreen> createState() => _ExpiryAlertsScreenState();
}

class _ExpiryAlertsScreenState extends State<ExpiryAlertsScreen> {
  @override
  void initState() {
    super.initState();
    context.read<ExpiryBloc>().add(const OnExpiryAlertsInitial());
  }

  Future<void> _refresh() async {
    context.read<ExpiryBloc>().add(const OnExpiryAlertsInitial());
    await Future<void>.delayed(const Duration(milliseconds: 350));
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: Icon(Icons.arrow_back_rounded, color: colors.textPrimary),
        ),
        title: Text(
          'Expiry Alerts',
          style: AppTextStyles.bs600(context).copyWith(
            fontWeight: FontWeight.w900,
            color: colors.textPrimary,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0.5),
          child: Divider(height: 0.5, color: colors.border),
        ),
      ),
      body: BlocBuilder<ExpiryBloc, ExpiryState>(
        builder: (context, state) {
          // ── Loading ──────────────────────────────────────────────
          if (state.status == ExpiryStatus.loading ||
              state.status == ExpiryStatus.initial) {
            return _LoadingView();
          }

          // ── Error ────────────────────────────────────────────────
          if (state.status == ExpiryStatus.failure) {
            return _ErrorView(
              message: state.error ?? 'Failed to load expiry alerts.',
              onRetry: () => context
                  .read<ExpiryBloc>()
                  .add(const OnExpiryAlertsInitial()),
            );
          }

          // ── Empty ────────────────────────────────────────────────
          if (state.alerts.isEmpty) {
            return _EmptyView(onRefresh: _refresh);
          }

          // ── List ─────────────────────────────────────────────────
          return RefreshIndicator(
            color: colors.primary,
            onRefresh: _refresh,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              slivers: [
                // Expired section
                if (state.expired.isNotEmpty) ...[
                  _SectionHeader(
                    label: 'Expired',
                    count: state.expired.length,
                    color: const Color(0xFFDC2626),
                    icon: Icons.error_outline_rounded,
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                        AppDims.s4, 0, AppDims.s4, AppDims.s2),
                    sliver: SliverList.separated(
                      itemCount: state.expired.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: AppDims.s3),
                      itemBuilder: (context, i) {
                        return ExpiryAlertCard(item: state.expired[i])
                            .animate(
                              delay: Duration(milliseconds: i < 6 ? i * 40 : 0),
                            )
                            .fadeIn(duration: 220.ms)
                            .slideY(
                              begin: 0.04,
                              end: 0,
                              duration: 220.ms,
                              curve: Curves.easeOut,
                            );
                      },
                    ),
                  ),
                ],

                // Expiring soon section
                if (state.expiringSoon.isNotEmpty) ...[
                  _SectionHeader(
                    label: 'Expiring Soon',
                    count: state.expiringSoon.length,
                    color: const Color(0xFFEA580C),
                    icon: Icons.warning_amber_rounded,
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                        AppDims.s4, 0, AppDims.s4, AppDims.s6),
                    sliver: SliverList.separated(
                      itemCount: state.expiringSoon.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: AppDims.s3),
                      itemBuilder: (context, i) {
                        final offset = state.expired.length + i;
                        return ExpiryAlertCard(item: state.expiringSoon[i])
                            .animate(
                              delay: Duration(
                                  milliseconds: offset < 8 ? offset * 40 : 0),
                            )
                            .fadeIn(duration: 220.ms)
                            .slideY(
                              begin: 0.04,
                              end: 0,
                              duration: 220.ms,
                              curve: Curves.easeOut,
                            );
                      },
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

// ── Section header ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String  label;
  final int     count;
  final Color   color;
  final IconData icon;

  const _SectionHeader({
    required this.label,
    required this.count,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(
          AppDims.s4, AppDims.s4, AppDims.s4, AppDims.s3),
      sliver: SliverToBoxAdapter(
        child: Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: AppDims.s2),
            Text(
              label,
              style: AppTextStyles.bs400(context).copyWith(
                fontWeight: FontWeight.w900,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(width: AppDims.s2),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '$count',
                style: AppTextStyles.sm200(context).copyWith(
                  color: color,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Loading skeleton ──────────────────────────────────────────────────────────

class _LoadingView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return ListView.separated(
      padding: const EdgeInsets.all(AppDims.s4),
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 6,
      separatorBuilder: (_, _) => const SizedBox(height: AppDims.s3),
      itemBuilder: (_, i) => Container(
        height: 90,
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(AppDims.rLg),
          border: Border.all(color: colors.border),
        ),
      ).animate(delay: Duration(milliseconds: i * 40))
          .shimmer(duration: 1200.ms,
              color: colors.border.withValues(alpha: 0.6)),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyView extends StatelessWidget {
  final Future<void> Function() onRefresh;
  const _EmptyView({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return RefreshIndicator(
      color: colors.primary,
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: MediaQuery.sizeOf(context).height * 0.28),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: colors.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.verified_rounded,
                      size: 34, color: colors.primary),
                ),
                const SizedBox(height: AppDims.s4),
                Text(
                  'No expiry alerts',
                  style: AppTextStyles.bs400(context).copyWith(
                    fontWeight: FontWeight.w900,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppDims.s2),
                Text(
                  'All products are within a safe expiry window.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bs200(context).copyWith(
                    color: colors.textSecondary,
                    fontWeight: FontWeight.w500,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 300.ms),
        ],
      ),
    );
  }
}

// ── Error state ───────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final String       message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDims.s5),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off_rounded, size: 44, color: colors.textHint),
            const SizedBox(height: AppDims.s4),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTextStyles.bs200(context).copyWith(
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: AppDims.s4),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Retry'),
              style: OutlinedButton.styleFrom(
                foregroundColor: colors.primary,
                side:
                    BorderSide(color: colors.primary.withValues(alpha: 0.4)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
