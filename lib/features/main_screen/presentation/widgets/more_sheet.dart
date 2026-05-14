import 'package:amana_pos/common/auth_bloc/auth_bloc.dart';
import 'package:amana_pos/config/router/route_strings.dart';
import 'package:amana_pos/core/offline/offline_db.dart';
import 'package:amana_pos/core/offline/presentation/bloc/offline_status_bloc.dart';
import 'package:amana_pos/features/main_screen/data/app_feature.dart';
import 'package:amana_pos/features/main_screen/data/feature_config.dart';
import 'package:amana_pos/features/main_screen/presentation/bloc/navigation_bloc.dart';
import 'package:amana_pos/features/main_screen/presentation/widgets/more_action_row.dart';
import 'package:amana_pos/features/main_screen/presentation/widgets/more_footer.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/utilities/dependencies_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solar_icons/solar_icons.dart';


class MoreSheet extends StatelessWidget {
  final List<FeatureConfig> items;
  final AppFeature currentFeature;
  final String? userName;
  final bool isOwner;
  final String? businessName;

  const MoreSheet({super.key,
    required this.items,
    required this.currentFeature,
    required this.userName,
    required this.isOwner,
    required this.businessName,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [

              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.symmetric(vertical: AppDims.s3),
                  decoration: BoxDecoration(
                    color: colors.border,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),


              _UserHeader(
                userName: userName,
                isOwner: isOwner,
                businessName: businessName,
              ),

              Divider(height: 1, thickness: 0.5, color: colors.border),


              ...List.generate(items.length, (i) {
                final item = items[i];

                return _FeatureRow(
                  config: item,
                  isActive: item.feature == currentFeature,
                  showDivider: true,
                  onTap: () {
                    Navigator.of(context).pop();
                    context.read<NavigationBloc>().add(
                      NavigationFeatureSelected(item.feature),
                    );
                  },
                )
                    .animate(delay: Duration(milliseconds: 60 + i * 55))
                    .fadeIn(duration: 220.ms)
                    .slideX(
                  begin: -0.04,
                  end: 0,
                  duration: 240.ms,
                  curve: Curves.easeOutCubic,
                );
              }),

              MoreActionRow(
                icon: SolarIconsOutline.settings,
                title: 'Settings',
                subtitle: 'Business, account, and app preferences',
                color: colors.primary,
                showDivider: false,
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pushNamed(RouteStrings.settingsScreen);
                },
              ),

              Divider(height: 1, thickness: 0.5, color: colors.border),


              MoreFooter(),
            ],
          ),
        ),
      ),
    );
  }
}


class _UserHeader extends StatelessWidget {
  final String? userName;
  final bool isOwner;
  final String? businessName;

  const _UserHeader({
    required this.userName,
    required this.isOwner,
    required this.businessName,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final initials = _initials(userName);
    final roleLabel = isOwner ? 'Owner' : 'Cashier';
    const roleColor = Color(0xFF0D9488);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppDims.s4, AppDims.s2, AppDims.s4, AppDims.s4),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: colors.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                initials,
                style: AppTextStyles.bs600(context).copyWith(
                  fontWeight: FontWeight.w900,
                  color: colors.primary,
                ),
              ),
            ),
          ),

          const SizedBox(width: AppDims.s3),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userName ?? 'User',
                  style: AppTextStyles.bs600(context).copyWith(
                    fontWeight: FontWeight.w800,
                    color: colors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: roleColor.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: roleColor.withValues(alpha: 0.28),
                        ),
                      ),
                      child: Text(
                        roleLabel,
                        style: AppTextStyles.bs100(context).copyWith(
                          fontWeight: FontWeight.w800,
                          color: roleColor,
                        ),
                      ),
                    ),
                    if (businessName != null) ...[
                      const SizedBox(width: AppDims.s2),
                      Flexible(
                        child: Text(
                          businessName!,
                          style: AppTextStyles.bs100(context).copyWith(
                            fontWeight: FontWeight.w600,
                            color: colors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _initials(String? name) {
    if (name == null || name.trim().isEmpty) return '?';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }
}


class _FeatureRow extends StatelessWidget {
  final FeatureConfig config;
  final bool isActive;
  final bool showDivider;
  final VoidCallback onTap;

  const _FeatureRow({
    required this.config,
    required this.isActive,
    required this.showDivider,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Column(
      children: [
        InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppDims.s4, vertical: 13),
            child: Row(
              children: [
                // Icon badge
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: config.color.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(AppDims.rMd),
                  ),
                  child: Icon(config.icon, size: 22, color: config.color),
                ),

                const SizedBox(width: AppDims.s4),

                // Name + subtitle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        config.label,
                        style: AppTextStyles.bs600(context).copyWith(
                          fontWeight: FontWeight.w700,
                          color: isActive ? config.color : colors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        config.subtitle,
                        style: AppTextStyles.bs400(context).copyWith(
                          fontWeight: FontWeight.w500,
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),

                // Active check or forward arrow
                Icon(
                  isActive
                      ? SolarIconsOutline.checkCircle
                      : SolarIconsOutline.altArrowRight,
                  size: isActive ? 20 : 15,
                  color: isActive ? config.color : colors.textHint,
                ),
              ],
            ),
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            thickness: 0.5,
            indent: AppDims.s4 + 42 + AppDims.s4,
            color: colors.border.withValues(alpha: 0.6),
          ),
      ],
    );
  }
}