import 'package:amana_pos/common/auth_bloc/auth_bloc.dart';
import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/common/widgets/app_progress_line.dart';
import 'package:amana_pos/core/offline/presentation/bloc/offline_status_bloc.dart';
import 'package:amana_pos/core/responsive/adaptive_sheet.dart';
import 'package:amana_pos/features/business/data/models/responses/business_response_dto.dart';
import 'package:amana_pos/features/main_screen/data/app_feature.dart';
import 'package:amana_pos/features/main_screen/presentation/bloc/navigation_bloc.dart';
import 'package:amana_pos/features/main_screen/presentation/widgets/location_switcher_sheet.dart';
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

/// Desktop-only top bar. Hamburger + screen title (leading), context
/// strip (trailing). PosAppBar (mobile) is not touched.
class DesktopTopBar extends StatelessWidget {
  const DesktopTopBar({
    super.key,
    required this.railExtended,
    required this.onMenuTap,
  });

  /// Whether the [DesktopNavigationRail] is currently expanded.
  /// Reflected in the hamburger button's pressed state.
  final bool railExtended;

  /// Toggles the nav rail's expanded/collapsed state.
  final VoidCallback onMenuTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(
                AppDims.s5, 0, AppDims.s5, 0),
            child: Row(
              children: [
                // ── Hamburger toggle ──────────────────────────────────────
                _HamburgerButton(active: railExtended, onTap: onMenuTap),

                const SizedBox(width: AppDims.s4),

                // ── Screen title ───────────────────────────────────────────
                Expanded(
                  child: BlocSelector<NavigationBloc, NavigationState,
                      AppFeature>(
                    selector: (s) => s.currentFeature,
                    builder: (context, feature) => Text(
                      _screenTitle(context, feature),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bs300(context).copyWith(
                        color: context.appColors.textPrimary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),

                // ── Desktop location chip (fit-content) ──────────────────
                BlocBuilder<AuthBloc, AuthState>(
                  buildWhen: (p, c) =>
                  p.defaultBusiness != c.defaultBusiness ||
                      p.businessStatus != c.businessStatus,
                  builder: (context, authState) =>
                      BlocBuilder<PosBloc, PosState>(
                        buildWhen: (p, c) =>
                        p.selectedShopId != c.selectedShopId ||
                            p.selectedShopName != c.selectedShopName,
                        builder: (context, posState) => _DesktopLocationChip(
                          business: authState.defaultBusiness,
                          selectedShopId: posState.selectedShopId,
                        ),
                      ),
                ),

                const SizedBox(width: AppDims.s3),

                // ── Sync status ──────────────────────────────────────────
                BlocBuilder<OfflineStatusBloc, OfflineStatusState>(
                  bloc: getIt<OfflineStatusBloc>(),
                  buildWhen: (p, c) =>
                  p.connectionStatus != c.connectionStatus ||
                      p.bootstrapStatus != c.bootstrapStatus ||
                      p.salesSyncStatus != c.salesSyncStatus ||
                      p.pendingSalesCount != c.pendingSalesCount,
                  builder: (context, state) => SyncPill(state: state),
                ),

                const SizedBox(width: AppDims.s2),

                // ── Notifications (owner only) ────────────────────────────
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

        _GradientRule(),
      ],
    );
  }
}

// ── Screen title ───────────────────────────────────────────────────────────────

String _screenTitle(BuildContext context, AppFeature feature) {
  final tr = context.tr;
  switch (feature) {
    case AppFeature.pos:
      return tr.navSell;
    case AppFeature.business:
      return tr.navHome;
    case AppFeature.products:
      return tr.navProducts;
    case AppFeature.inventory:
      return tr.navInventory;
    case AppFeature.categories:
      return tr.settingsCategories;
    case AppFeature.customers:
      return tr.settingsCustomers;
    case AppFeature.users:
      return tr.navCashiers;
    case AppFeature.salesHistory:
      return tr.settingsSalesHistory;
  }
}

// ── Hamburger toggle ──────────────────────────────────────────────────────────

class _HamburgerButton extends StatelessWidget {
  const _HamburgerButton({required this.active, required this.onTap});

  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppDims.rMd),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDims.rMd),
        child: Container(
          width: 38,
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppDims.rMd),
            color: active
                ? colors.primary.withValues(alpha: 0.10)
                : colors.surfaceSoft.withValues(alpha: 0.55),
            border: Border.all(
              color: active
                  ? colors.primary.withValues(alpha: 0.30)
                  : colors.border.withValues(alpha: 0.70),
            ),
          ),
          child: Icon(
            SolarIconsOutline.hamburgerMenu,
            size: 18,
            color: active ? colors.primary : colors.textSecondary,
          ),
        ),
      ),
    );
  }
}

// ── Desktop location chip ─────────────────────────────────────────────────────
//
// Compact, fit-content. Single row: pin icon + "Branch · Biz" + chevron.
// No address row, no fixed width — sizes itself to its text content.

class _DesktopLocationChip extends StatelessWidget {
  final BusinessData? business;
  final String? selectedShopId;

  const _DesktopLocationChip({
    required this.business,
    required this.selectedShopId,
  });

  ShopData? _selectedShop() {
    final shops = business?.shops ?? const <ShopData>[];
    if (selectedShopId != null && selectedShopId!.isNotEmpty) {
      for (final shop in shops) {
        if (shop.id == selectedShopId) return shop;
      }
    }
    final active = shops.where((s) => s.id != null && (s.isActive ?? true));
    return active.isEmpty ? null : active.first;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final hasMultiple = (business?.shopCount ?? 0) > 1;
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    final bizName = business?.name?.trim().isNotEmpty == true
        ? business!.name!.trim()
        : 'Workspace';

    final shop = _selectedShop();
    final branchName = shop?.name?.trim().isNotEmpty == true
        ? shop!.name!.trim()
        : 'Select branch';

    return GestureDetector(
      onTap: hasMultiple
          ? () => showAdaptivePanel(
        context,
        desktopWidth: 360,
        builder: (_) => BlocProvider.value(
          value: context.read<PosBloc>(),
          child: LocationSwitcherSheet(
            business: business!,
            selectedShopId: selectedShopId,
          ),
        ),
      )
          : null,
      behavior: HitTestBehavior.opaque,
      child: Container(
        constraints: const BoxConstraints(minHeight: 38, maxHeight: 42),
        padding: const EdgeInsetsDirectional.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: colors.surfaceSoft.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: colors.border.withValues(alpha: 0.70),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              SolarIconsOutline.mapPoint,
              size: 14,
              color: colors.primary.withValues(alpha: 0.80),
            ),
            const SizedBox(width: 7),

            // Branch name (primary) + separator + Biz name (secondary)
            Text.rich(
              textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
              TextSpan(children: [
                TextSpan(
                  text: branchName,
                  style: AppTextStyles.bs200(context).copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w800,
                    height: 1,
                  ),
                ),
                TextSpan(
                  text: '  ·  $bizName',
                  style: AppTextStyles.bs100(context).copyWith(
                    color: colors.textSecondary,
                    fontWeight: FontWeight.w600,
                    height: 1,
                    letterSpacing: 0.3,
                  ),
                ),
              ]),
            ),

            if (hasMultiple) ...[
              const SizedBox(width: 7),
              Icon(
                SolarIconsOutline.altArrowDown,
                size: 12,
                color: colors.textHint,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Gradient rule ─────────────────────────────────────────────────────────────

class _GradientRule extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const AppProgressLine();
  }
}