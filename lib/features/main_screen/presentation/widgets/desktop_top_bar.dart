import 'package:amana_pos/common/auth_bloc/auth_bloc.dart';
import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/core/offline/presentation/bloc/offline_status_bloc.dart';
import 'package:amana_pos/features/main_screen/data/app_feature.dart';
import 'package:amana_pos/features/main_screen/presentation/bloc/navigation_bloc.dart';
import 'package:amana_pos/features/main_screen/presentation/widgets/location_chip.dart';
import 'package:amana_pos/features/main_screen/presentation/widgets/notification_button.dart';
import 'package:amana_pos/features/main_screen/presentation/widgets/sync_pill.dart';
import 'package:amana_pos/features/pos/presentation/bloc/pos_bloc.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/utilities/dependencies_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solar_icons/solar_icons.dart';

/// Desktop top bar that replaces PosAppBar inside DesktopShell.
/// Displays the animated current-section title on the left, location
/// chip in the middle, and sync + notifications on the right.
/// PosAppBar (mobile) is not touched.
class DesktopTopBar extends StatelessWidget {
  const DesktopTopBar({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(
              AppDims.s6, 0, AppDims.s5, 0,
            ),
            child: Row(
              spacing: AppDims.s3,
              children: [
                // ── Animated section title + icon ──────────────────────────
                BlocBuilder<NavigationBloc, NavigationState>(
                  buildWhen: (prev, curr) =>
                      prev.currentFeature != curr.currentFeature,
                  builder: (context, state) {
                    final label = _featureLabel(context, state.currentFeature);
                    final icon = _featureIcon(state.currentFeature);

                    return AnimatedSwitcher(
                      duration: const Duration(milliseconds: 260),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      transitionBuilder: (child, animation) =>
                          FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, 0.18),
                            end: Offset.zero,
                          ).animate(CurvedAnimation(
                            parent: animation,
                            curve: Curves.easeOutCubic,
                          )),
                          child: child,
                        ),
                      ),
                      child: _SectionTitle(
                        key: ValueKey(state.currentFeature),
                        label: label,
                        icon: icon,
                      ),
                    );
                  },
                ),

                // ── Divider ────────────────────────────────────────────────
                Container(
                  width: 1,
                  height: 24,
                  color: colors.border,
                ),

                // ── Location chip (takes remaining space) ──────────────────
                Expanded(
                  child: BlocBuilder<AuthBloc, AuthState>(
                    buildWhen: (p, c) =>
                        p.defaultBusiness != c.defaultBusiness ||
                        p.businessStatus != c.businessStatus,
                    builder: (context, authState) =>
                        BlocBuilder<PosBloc, PosState>(
                      buildWhen: (p, c) =>
                          p.selectedShopId != c.selectedShopId ||
                          p.selectedShopName != c.selectedShopName,
                      builder: (context, posState) => LocationChip(
                        business: authState.defaultBusiness,
                        selectedShopId: posState.selectedShopId,
                      ),
                    ),
                  ),
                ),

                // ── Sync status ────────────────────────────────────────────
                BlocBuilder<OfflineStatusBloc, OfflineStatusState>(
                  bloc: getIt<OfflineStatusBloc>(),
                  buildWhen: (p, c) =>
                      p.connectionStatus != c.connectionStatus ||
                      p.bootstrapStatus != c.bootstrapStatus ||
                      p.salesSyncStatus != c.salesSyncStatus ||
                      p.pendingSalesCount != c.pendingSalesCount,
                  builder: (context, state) => SyncPill(state: state),
                ),

                // ── Notifications (owner only) ─────────────────────────────
                BlocSelector<AuthBloc, AuthState, bool>(
                  selector: (s) => s.permissions.isOwner,
                  builder: (context, isOwner) {
                    if (!isOwner) return const SizedBox.shrink();
                    return const NotificationButton();
                  },
                ),
              ],
            ),
          ),
        ),

        // ── Bottom gradient rule (matches mobile aesthetic) ────────────────
        _GradientRule(),
      ],
    );
  }

  String _featureLabel(BuildContext context, AppFeature feature) {
    final tr = context.tr;
    return switch (feature) {
      AppFeature.pos        => tr.navSell,
      AppFeature.business   => tr.navHome,
      AppFeature.products   => tr.navProducts,
      AppFeature.inventory  => tr.navInventory,
      AppFeature.categories => tr.settingsCategories,
      AppFeature.customers  => tr.settingsCustomers,
      AppFeature.users      => tr.navCashiers,
    };
  }

  IconData _featureIcon(AppFeature feature) {
    return switch (feature) {
      AppFeature.pos        => SolarIconsOutline.cartLarge_4,
      AppFeature.business   => SolarIconsBold.shop,
      AppFeature.products   => SolarIconsOutline.bag5,
      AppFeature.inventory  => SolarIconsOutline.boxMinimalistic,
      AppFeature.categories => SolarIconsOutline.layers,
      AppFeature.customers  => SolarIconsOutline.usersGroupRounded,
      AppFeature.users      => SolarIconsOutline.userPlus,
    };
  }
}

// ── Section title widget (icon + label) ──────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String label;
  final IconData icon;

  const _SectionTitle({super.key, required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: colors.primary.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(AppDims.rSm),
            border: Border.all(
              color: colors.primary.withValues(alpha: 0.20),
              width: 1,
            ),
          ),
          child: Icon(icon, size: 16, color: colors.primary),
        ),
        const SizedBox(width: AppDims.s3),
        Text(
          label,
          style: AppTextStyles.bs700(context).copyWith(
            fontWeight: FontWeight.w800,
            color: colors.textPrimary,
            letterSpacing: -0.4,
            height: 1,
          ),
        ),
      ],
    );
  }
}

// ── Gradient rule (bottom border) ────────────────────────────────────────────

class _GradientRule extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      height: 1,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.transparent,
            colors.border.withValues(alpha: 0.16),
            colors.primary.withValues(alpha: 0.30),
            colors.border.withValues(alpha: 0.16),
            Colors.transparent,
          ],
          stops: const [0.00, 0.22, 0.50, 0.78, 1.00],
        ),
      ),
    );
  }
}
