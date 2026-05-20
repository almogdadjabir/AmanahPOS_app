import 'package:amana_pos/config/router/route_strings.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';
import 'package:solar_icons/solar_icons.dart';

class ExpiryAlertRow extends StatelessWidget {
  const ExpiryAlertRow({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () =>
            Navigator.of(context).pushNamed(RouteStrings.expiryAlertsScreen),
        borderRadius: BorderRadius.circular(AppDims.rMd),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDims.s3,
            vertical: AppDims.s2,
          ),
          decoration: BoxDecoration(
            color: colors.danger.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(AppDims.rMd),
            border: Border.all(
              color: colors.danger.withValues(alpha: 0.20),
            ),
          ),
          child: Row(
            children: [
              Icon(
                SolarIconsOutline.dangerTriangle,
                color: colors.danger,
                size: 16,
              ),
              const SizedBox(width: AppDims.s2),
              Expanded(
                child: Text(
                  'Check expiry alerts',
                  style: AppTextStyles.bs300(context).copyWith(
                    color: colors.danger,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: colors.danger,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}