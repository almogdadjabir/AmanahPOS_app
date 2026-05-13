import 'package:amana_pos/common/theme_bloc/theme_bloc.dart';
import 'package:amana_pos/config/enum.dart';
import 'package:amana_pos/features/settings/presentation/widgets/app_bottom_sheet.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ThemePickerSheet extends StatelessWidget {
  const ThemePickerSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBottomSheet(
      title: 'Appearance',
      subtitle: 'Choose how AmanaPOS looks on your device.',
      icon: Icons.palette_outlined,
      child: BlocBuilder<ThemeBloc, ThemeState>(
        builder: (context, state) {
          final current = state.mode ?? ScreenMode.device;

          return Column(
            children: [
              _ThemeOption(
                mode: ScreenMode.light,
                current: current,
                title: 'Light',
                subtitle: 'Clean bright interface. Always on.',
                icon: Icons.wb_sunny_rounded,
                iconColor: const Color(0xFFF59E0B),
                delay: 0,
              ),
              const SizedBox(height: AppDims.s3),
              _ThemeOption(
                mode: ScreenMode.dark,
                current: current,
                title: 'Dark',
                subtitle: 'Easy on the eyes in low light.',
                icon: Icons.nights_stay_rounded,
                iconColor: const Color(0xFF6366F1),
                delay: 55,
              ),
              const SizedBox(height: AppDims.s3),
              _ThemeOption(
                mode: ScreenMode.device,
                current: current,
                title: 'System',
                subtitle: 'Follows your device setting automatically.',
                icon: Icons.phone_android_rounded,
                iconColor: const Color(0xFF0D9488),
                delay: 110,
              ),
              const SizedBox(height: AppDims.s2),
            ],
          );
        },
      ),
    );
  }
}

// ── Single theme option card ──────────────────────────────────────────────────

class _ThemeOption extends StatelessWidget {
  final ScreenMode mode;
  final ScreenMode current;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final int delay;

  const _ThemeOption({
    required this.mode,
    required this.current,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isSelected = mode == current;

    return GestureDetector(
      onTap: () {
        context.read<ThemeBloc>().add(OnThemeChangeEvent(mode: mode));
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
            // ── Icon badge ──────────────────────────────────────────────
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppDims.rMd),
              ),
              child: Icon(icon, size: 22, color: iconColor),
            ),

            const SizedBox(width: AppDims.s3),

            // ── Label ───────────────────────────────────────────────────
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
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: AppDims.s3),

            // ── Selection indicator ─────────────────────────────────────
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
        .slideY(
          begin: 0.06,
          end: 0,
          duration: 240.ms,
          curve: Curves.easeOut,
        );
  }
}
