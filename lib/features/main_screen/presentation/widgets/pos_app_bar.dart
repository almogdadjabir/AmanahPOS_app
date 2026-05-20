import 'dart:ui';

import 'package:amana_pos/common/auth_bloc/auth_bloc.dart';
import 'package:amana_pos/config/app_assets.dart';
import 'package:amana_pos/config/router/route_strings.dart';
import 'package:amana_pos/core/offline/presentation/bloc/offline_status_bloc.dart';
import 'package:amana_pos/features/business/data/models/responses/business_response_dto.dart';
import 'package:amana_pos/features/main_screen/presentation/widgets/location_switcher_sheet.dart';
import 'package:amana_pos/features/notification/presentation/bloc/notification_bloc.dart';
import 'package:amana_pos/features/pos/presentation/bloc/pos_bloc.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/utilities/dependencies_provider.dart';
import 'package:amana_pos/widgets/amana_logo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:solar_icons/solar_icons.dart';

class PosAppBar extends StatelessWidget {

  const PosAppBar({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppDims.s4,
        AppDims.s2,
        AppDims.s4,
        0,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Row(
            spacing: AppDims.s3,
            children: [
              Expanded(
                child: BlocBuilder<AuthBloc, AuthState>(
                  buildWhen: (prev, curr) =>
                  prev.defaultBusiness != curr.defaultBusiness ||
                      prev.businessStatus != curr.businessStatus,
                  builder: (context, authState) {
                    return BlocBuilder<PosBloc, PosState>(
                      buildWhen: (prev, curr) =>
                      prev.selectedShopId != curr.selectedShopId ||
                          prev.selectedShopName != curr.selectedShopName,
                      builder: (context, posState) {
                        return LocationChip(
                          business: authState.defaultBusiness,
                          selectedShopId: posState.selectedShopId,
                        );
                      },
                    );
                  },
                ),
              ),
              // Expanded(
              //   child: BlocBuilder<AuthBloc, AuthState>(
              //     buildWhen: (prev, curr) =>
              //     prev.businessStatus != curr.businessStatus ||
              //         prev.defaultBusiness != curr.defaultBusiness,
              //     builder: (context, state) {
              //       return switch (state.businessStatus) {
              //         BusinessStatus.loading ||
              //         BusinessStatus.initial =>
              //         const _BusinessSelectorSkeleton(),
              //
              //         BusinessStatus.success => _BusinessSelector(
              //           business: state.defaultBusiness,
              //           onTap: () {
              //             context.read<NavigationBloc>().add(
              //               const SetMenuOpenEvent(open: false),
              //             );
              //             Navigator.of(context).pushNamed(
              //               RouteStrings.settingsScreen,
              //             );
              //           },
              //         ),
              //
              //         BusinessStatus.failure => _BusinessSelector(
              //           business: null,
              //           onTap: () {},
              //         ),
              //       };
              //     },
              //   ),
              // ),
              BlocBuilder<OfflineStatusBloc, OfflineStatusState>(
                bloc: getIt<OfflineStatusBloc>(),
                buildWhen: (prev, curr) =>
                prev.connectionStatus != curr.connectionStatus ||
                    prev.bootstrapStatus != curr.bootstrapStatus ||
                    prev.salesSyncStatus != curr.salesSyncStatus ||
                    prev.pendingSalesCount != curr.pendingSalesCount,
                builder: (context, state) {
                  return _SyncStatusPill(state: state);
                },
              ),
              const _NotificationButton(),
            ],
          ),

          const SizedBox(height: AppDims.s4),

          Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  Colors.transparent,
                  colors.border.withValues(alpha: 0.16),
                  colors.primary.withValues(alpha: 0.30),
                  colors.border.withValues(alpha: 0.16),
                  Colors.transparent,
                ],
                stops: const [
                  0.00,
                  0.22,
                  0.50,
                  0.78,
                  1.00,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationButton extends StatelessWidget {
  const _NotificationButton();

  @override
  Widget build(BuildContext context) {
    return BlocSelector<AuthBloc, AuthState, bool>(
      selector: (state) => state.permissions.isOwner,
      builder: (context, isOwner) {
        if (!isOwner) {
          return const SizedBox.shrink();
        }

        final colors = context.appColors;

        return GestureDetector(
          onTap: () {
            Navigator.pushNamed(context, RouteStrings.notificationsScreen);
          },
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.only(right: AppDims.s3),
            child: SizedBox(
              width: 58,
              height: 58,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: colors.surfaceSoft.withValues(alpha: 0.68),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: colors.border.withValues(alpha: 0.75),
                        width: 1.2,
                      ),
                    ),
                    child: Center(
                      child: BlocSelector<NotificationBloc, NotificationState, int?>(
                        selector: (state) => state.unreadCount,
                        builder: (context, unreadNotificationCount) {
                          final icon = SvgPicture.asset(
                            AppAssets.icNotification,
                            width: 24,
                            colorFilter: ColorFilter.mode(
                              context.appColors.textPrimary,
                              BlendMode.srcIn,
                            ),
                          );

                          if (unreadNotificationCount == null ||
                              unreadNotificationCount == 0) {
                            return icon;
                          }

                          return Badge.count(
                            count: unreadNotificationCount,
                            backgroundColor: context.appColors.danger,
                            textColor: Colors.white,
                            child: icon,
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SyncStatusPill extends StatelessWidget {
  final OfflineStatusState state;

  const _SyncStatusPill({
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    final model = _SyncStatusViewModel.from(context, state);

    return GestureDetector(
      onTap: state.pendingSalesCount > 0
          ? () => Navigator.of(context).pushNamed(
        RouteStrings.pendingSyncScreen,
      )
          : null,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
        height: 42,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: model.color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(99),
          border: Border.all(
            color: model.color.withValues(alpha: 0.34),
            width: 1.2,
          ),
          boxShadow: [
            if (!state.hasFailure)
              BoxShadow(
                color: model.color.withValues(alpha: 0.08),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (state.isBusy)
              SizedBox(
                width: 9,
                height: 9,
                child: CircularProgressIndicator(
                  strokeWidth: 1.7,
                  color: model.color,
                ),
              )
            else
              AnimatedContainer(
                duration: const Duration(milliseconds: 240),
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: model.color,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: model.color.withValues(alpha: 0.65),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
            const SizedBox(width: 9),
            Text(
              model.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.sm300(context).copyWith(
                color: model.color,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.6,
              ),
            ),
            if (state.pendingSalesCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.34),
                  ),
                ),
                child: Text(
                  '${state.pendingSalesCount}',
                  style: AppTextStyles.sm100(context).copyWith(
                    color: const Color(0xFFF59E0B),
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}


class _BusinessSelectorSkeleton extends StatefulWidget {
  const _BusinessSelectorSkeleton();

  @override
  State<_BusinessSelectorSkeleton> createState() =>
      _BusinessSelectorSkeletonState();
}

class _BusinessSelectorSkeletonState extends State<_BusinessSelectorSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _opacity = Tween<double>(begin: 0.35, end: 0.9).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return AnimatedBuilder(
      animation: _opacity,
      builder: (context, _) {
        return Opacity(
          opacity: _opacity.value,
          child: Container(
            height: 58,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: colors.surfaceSoft.withValues(alpha: 0.66),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: colors.border.withValues(alpha: 0.7),
              ),
            ),
            child: Row(
              children: [
                _ShimmerBar(width: 18, height: 18, radius: 99),
                const SizedBox(width: AppDims.s3),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: const [
                      _ShimmerBar(width: 128, height: 13, radius: 8),
                      SizedBox(height: 7),
                      _ShimmerBar(width: 84, height: 9, radius: 8),
                    ],
                  ),
                ),
                const SizedBox(width: AppDims.s3),
                const _ShimmerBar(width: 44, height: 44, radius: 16),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ShimmerBar extends StatelessWidget {
  final double width;
  final double height;
  final double radius;

  const _ShimmerBar({
    required this.width,
    required this.height,
    required this.radius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: context.appColors.border.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

class _SyncStatusViewModel {
  final String label;
  final Color color;

  const _SyncStatusViewModel({
    required this.label,
    required this.color,
  });

  factory _SyncStatusViewModel.from(
      BuildContext context,
      OfflineStatusState state,
      ) {
    final colors = context.appColors;

    if (state.isOffline && !state.canUseAppOffline) {
      return _SyncStatusViewModel(
        label: 'OFFLINE',
        color: colors.danger,
      );
    }

    if (state.isOffline && state.canUseAppOffline) {
      return const _SyncStatusViewModel(
        label: 'OFFLINE',
        color: Color(0xFFF59E0B),
      );
    }

    if (state.hasFailure) {
      return _SyncStatusViewModel(
        label: 'SYNC ISSUE',
        color: colors.danger,
      );
    }

    if (state.pendingSalesCount > 0) {
      return const _SyncStatusViewModel(
        label: 'PENDING',
        color: Color(0xFFF59E0B),
      );
    }

    if (state.isBusy) {
      return const _SyncStatusViewModel(
        label: 'SYNCING',
        color: Color(0xFF38BDF8),
      );
    }

    return const _SyncStatusViewModel(
      label: 'SYNCED',
      color: Color(0xFF22C55E),
    );
  }
}


class LocationChip extends StatelessWidget {
  const LocationChip({
    super.key,
    required this.business,
    required this.selectedShopId,
  });

  final BusinessData? business;
  final String? selectedShopId;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    final businessName = business?.name?.trim().isNotEmpty == true
        ? business!.name!.trim()
        : 'Workspace';

    final selectedShop = _selectedShop();
    final branchName = selectedShop?.name?.trim().isNotEmpty == true
        ? selectedShop!.name!.trim()
        : 'Select branch';



    final address = business?.address?.trim().isNotEmpty == true
        ? business!.address!.trim()
        : 'Business workspace';

    return GestureDetector(
      onTap: (business?.shopCount ?? 0) > 1
          ? () {
        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          isScrollControlled: true,
          builder: (_) => BlocProvider.value(
            value: context.read<PosBloc>(),
            child: LocationSwitcherSheet(
              business: business!,
              selectedShopId: selectedShopId,
            ),
          ),
        );
      }
          : null,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 58,
        constraints: const BoxConstraints(minWidth: 0),
        padding: const EdgeInsetsDirectional.fromSTEB(14, 7, 8, 7),
        decoration: BoxDecoration(
          color: colors.surfaceSoft.withValues(alpha: 0.66),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: colors.border.withValues(alpha: 0.78),
            width: 1.2,
          ),
        ),
        child: Row(
          children: [
            AmanaPosLogoMark(isInAppBar: true),
            const SizedBox(width: AppDims.s2),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: businessName,
                          style: AppTextStyles.bs200(context).copyWith(
                            color: colors.textPrimary,
                            fontWeight: FontWeight.w900,
                            height: 1,
                          ),
                        ),
                        TextSpan(
                          text: '  ·  ',
                          style: AppTextStyles.bs100(context).copyWith(
                            color: colors.textHint,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        TextSpan(
                          text: branchName,
                          style: AppTextStyles.bs100(context).copyWith(
                            color: colors.textSecondary,
                            fontWeight: FontWeight.w800,
                            height: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    address,
                    maxLines: 1,
                    textAlign: TextAlign.end,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.sm100(context).copyWith(
                      fontWeight: FontWeight.w700,
                      color: colors.textSecondary,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ),

            if ((business?.shopCount ?? 0) > 1) ...[
              const SizedBox(width: 6),
              Icon(
                SolarIconsOutline.altArrowDown,
                size: 17,
                color: colors.textHint,
              ),
            ],
          ],
        ),
      ),
    );
  }

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
}