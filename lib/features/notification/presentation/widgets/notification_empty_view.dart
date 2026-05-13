import 'package:amana_pos/config/app_assets.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_svg/svg.dart';

class NotificationEmptyView extends StatelessWidget {
  const NotificationEmptyView({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: colors.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: SvgPicture.asset(
                AppAssets.icNotification,
                width: 42,
                colorFilter: ColorFilter.mode(
                    context.appColors.primary,
                    BlendMode.srcIn
                ),
              ),
            )
          ),
          const SizedBox(height: AppDims.s4),
          Text(
            'No notifications yet',
            style: AppTextStyles.bs400(context).copyWith(
              fontWeight: FontWeight.w900,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: AppDims.s2),
          Text(
            "You're all caught up. New notifications will appear here.",
            textAlign: TextAlign.center,
            style: AppTextStyles.bs100(context).copyWith(
              color: colors.textSecondary,
              fontWeight: FontWeight.w500,
              height: 1.5,
            ),
          ),
        ],
      ).animate().fadeIn(duration: 300.ms).scale(
        begin: const Offset(0.95, 0.95),
        duration: 300.ms,
        curve: Curves.easeOut,
      ),
    );
  }
}
