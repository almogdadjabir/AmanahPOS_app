import 'package:amana_pos/common/locale_bloc/locale_bloc.dart';
import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/features/settings/presentation/widgets/app_bottom_sheet.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solar_icons/solar_icons.dart';

class LanguagePickerSheet extends StatelessWidget {
  const LanguagePickerSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    return AppBottomSheet(
      title: tr.languagePickerTitle,
      subtitle: tr.languagePickerSubtitle,
      icon: SolarIconsOutline.global,
      child: BlocBuilder<LocaleBloc, LocaleState>(
        builder: (context, state) {
          final current = state.locale.languageCode;
          return Column(
            children: [
              _LangOption(
                languageCode: 'en',
                current: current,
                title: tr.languageEnglish,
                subtitle: tr.languageEnglishNative,
                delay: 0,
              ),
              const SizedBox(height: AppDims.s3),
              _LangOption(
                languageCode: 'ar',
                current: current,
                title: tr.languageArabic,
                subtitle: tr.languageArabicNative,
                delay: 55,
              ),
              const SizedBox(height: AppDims.s2),
            ],
          );
        },
      ),
    );
  }
}

class _LangOption extends StatelessWidget {
  final String languageCode;
  final String current;
  final String title;
  final String subtitle;
  final int delay;

  const _LangOption({
    required this.languageCode,
    required this.current,
    required this.title,
    required this.subtitle,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isSelected = languageCode == current;

    return GestureDetector(
      onTap: () {
        context
            .read<LocaleBloc>()
            .add(OnLocaleChanged(languageCode: languageCode));
        Navigator.of(context).pop();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: const EdgeInsets.all(AppDims.s4),
        decoration: BoxDecoration(
          color: isSelected
              ? colors.primaryContainer.withValues(alpha: 0.15)
              : colors.surface,
          borderRadius: BorderRadius.circular(AppDims.rLg),
          border: Border.all(
            color: isSelected
                ? colors.primary.withValues(alpha: 0.35)
                : colors.border,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(AppDims.rMd),
              ),
              child: Center(
                child: Text(
                  languageCode == 'ar' ? 'ع' : 'A',
                  style: AppTextStyles.bs500(context).copyWith(
                    color: colors.primary,
                    fontWeight: FontWeight.w900,
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
                    title,
                    style: AppTextStyles.bs400(context).copyWith(
                      fontWeight: FontWeight.w900,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: AppTextStyles.bs200(context).copyWith(
                      color: colors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppDims.s3),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? colors.primary : Colors.transparent,
                border: Border.all(
                  color: isSelected ? colors.primary : colors.border,
                  width: isSelected ? 0 : 2,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check_rounded, size: 13, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    )
        .animate(delay: Duration(milliseconds: delay))
        .fadeIn(duration: 240.ms)
        .slideY(begin: 0.06, end: 0, duration: 240.ms, curve: Curves.easeOut);
  }
}
