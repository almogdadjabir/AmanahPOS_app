import 'package:amana_pos/features/users/presentation/widgets/add_user_sheet.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';
import 'package:solar_icons/solar_icons.dart';

class UserEmptyView extends StatelessWidget {
  const UserEmptyView({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Center(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(AppDims.s6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 86,
              height: 86,
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.10),
                shape: BoxShape.circle,
                border: Border.all(
                  color: colors.primary.withValues(alpha: 0.18),
                ),
              ),
              child: Icon(
                SolarIconsOutline.usersGroupRounded,
                size: 38,
                color: colors.primary,
              ),
            ),

            const SizedBox(height: AppDims.s4),

            Text(
              'No cashiers yet',
              textAlign: TextAlign.center,
              style: AppTextStyles.bs700(context).copyWith(
                fontWeight: FontWeight.w900,
                color: colors.textPrimary,
                height: 1.1,
              ),
            ),

            const SizedBox(height: AppDims.s2),

            Text(
              'Add your first cashier so your team can start processing sales from the POS.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bs300(context).copyWith(
                fontWeight: FontWeight.w700,
                color: colors.textSecondary,
                height: 1.4,
              ),
            ),

            const SizedBox(height: AppDims.s5),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton.icon(
                onPressed: () => showAddUserSheet(context),
                style: FilledButton.styleFrom(
                  backgroundColor: colors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppDims.rMd),
                  ),
                ),
                icon: const Icon(
                  SolarIconsOutline.userPlus,
                  size: 19,
                  color: Colors.white,
                ),
                label: Text(
                  'Add Cashier',
                  style: AppTextStyles.bs500(context).copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}