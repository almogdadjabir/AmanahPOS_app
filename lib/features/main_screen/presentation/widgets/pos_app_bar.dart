import 'package:amana_pos/common/auth_bloc/auth_bloc.dart';
import 'package:amana_pos/config/router/route_strings.dart';
import 'package:amana_pos/features/business/data/models/responses/business_response_dto.dart';
import 'package:amana_pos/features/main_screen/presentation/bloc/navigation_bloc.dart';
import 'package:amana_pos/features/main_screen/presentation/widgets/animated_menu_icon.dart';
import 'package:amana_pos/features/main_screen/presentation/widgets/brand_logo.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class PosAppBar extends StatelessWidget {
  final VoidCallback onMenuTap;
  final VoidCallback? onNotifTap;
  final bool hasNotifications;

  const PosAppBar({
    super.key,
    required this.onMenuTap,
    this.onNotifTap,
    this.hasNotifications = true,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        BlocSelector<NavigationBloc, NavigationState, bool>(
          selector: (state) => state.menuOpen,
          builder: (context, menuOpen) {
            return GestureDetector(
              onTap: onMenuTap,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: menuOpen
                      ? const Color(0xFF0D9488).withValues(alpha: 0.08)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppDims.rSm),
                ),
                child: Center(
                  child: AnimatedMenuIcon(isOpen: menuOpen),
                ),
              ),
            );
          },
        ),

        const SizedBox(width: AppDims.s2),
        const BrandLogo(),
        const SizedBox(width: AppDims.s3),

        Expanded(
          child: BlocBuilder<AuthBloc, AuthState>(
            buildWhen: (prev, curr) =>
            prev.businessStatus != curr.businessStatus ||
                prev.defaultBusiness != curr.defaultBusiness,
            builder: (context, s) {
              return switch (s.businessStatus) {
                BusinessStatus.loading ||
                BusinessStatus.initial =>
                const _BusinessSkeleton(),

                BusinessStatus.success =>
                    _BusinessInfo(business: s.defaultBusiness),

                BusinessStatus.failure =>
                const _BusinessInfo(business: null),
              };
            },
          ),
        ),

        IconButton(
          onPressed: onNotifTap,
          icon: hasNotifications
              ? Badge(
            backgroundColor: context.appColors.danger,
            child: Icon(
              Icons.notifications_outlined,
              size: 22,
              color: context.appColors.textPrimary,
            ),
          )
              : Icon(
            Icons.notifications_outlined,
            size: 22,
            color: context.appColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _BusinessInfo extends StatelessWidget {
  final BusinessData? business;

  const _BusinessInfo({
    this.business,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: business == null
          ? null
          : () {
        context
            .read<NavigationBloc>()
            .add(const SetMenuOpenEvent(open: false));
        Navigator.of(context).pushNamed(RouteStrings.settingsScreen);
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            business?.name ?? 'AmanaPOS',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bs400(context).copyWith(
              fontWeight: FontWeight.w800,
              color: context.appColors.textPrimary,
              letterSpacing: -0.2,
            ),
          ),
          Text(
            business?.address ?? 'Preparing your workspace...',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bs100(context).copyWith(
              fontWeight: FontWeight.w600,
              color: context.appColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _BusinessSkeleton extends StatefulWidget {
  const _BusinessSkeleton();

  @override
  State<_BusinessSkeleton> createState() => _BusinessSkeletonState();
}

class _BusinessSkeletonState extends State<_BusinessSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, _) {
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ShimmerBar(width: 110, height: 13, opacity: _anim.value),
            const SizedBox(height: 5),
            _ShimmerBar(width: 72, height: 10, opacity: _anim.value),
          ],
        );
      },
    );
  }
}

class _ShimmerBar extends StatelessWidget {
  final double width;
  final double height;
  final double opacity;

  const _ShimmerBar({
    required this.width,
    required this.height,
    required this.opacity,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: context.appColors.border,
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }
}