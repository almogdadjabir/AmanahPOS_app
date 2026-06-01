import 'package:amana_pos/common/localization/app_localizations_extension.dart';
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
    final tr = context.tr;

    return Center(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsetsDirectional.all(AppDims.s6),
        child: RepaintBoundary(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _EmptyIcon(colors: colors),
              const SizedBox(height: AppDims.s4),
              _EmptyTitle(title: tr.noCashiersYet),
              const SizedBox(height: AppDims.s2),
              _EmptyDescription(description: tr.noCashiersYetDescription),
              const SizedBox(height: AppDims.s5),
              _AddCashierButton(onPressed: () => showAddUserSheet(context)),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyIcon extends StatelessWidget {
  const _EmptyIcon({required this.colors});

  final AppThemeColors colors;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: 0.10),
        shape: BoxShape.circle,
        border: Border.all(
          color: colors.primary.withValues(alpha: 0.18),
        ),
      ),
      child: SizedBox(
        width: 86,
        height: 86,
        child: Icon(
          SolarIconsOutline.usersGroupRounded,
          size: 38,
          color: colors.primary,
        ),
      ),
    );
  }
}

class _EmptyTitle extends StatelessWidget {
  const _EmptyTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Text(
      title,
      textAlign: TextAlign.center,
      style: AppTextStyles.bs700(context).copyWith(
        fontWeight: FontWeight.w900,
        color: colors.textPrimary,
        height: 1.1,
      ),
    );
  }
}

class _EmptyDescription extends StatelessWidget {
  const _EmptyDescription({required this.description});

  final String description;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Text(
      description,
      textAlign: TextAlign.center,
      style: AppTextStyles.bs300(context).copyWith(
        fontWeight: FontWeight.w700,
        color: colors.textSecondary,
        height: 1.4,
      ),
    );
  }
}

class _AddCashierButton extends StatelessWidget {
  const _AddCashierButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final tr = context.tr;

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: FilledButton.icon(
        onPressed: onPressed,
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
          tr.addCashier,
          style: AppTextStyles.bs500(context).copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}