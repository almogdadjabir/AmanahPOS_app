import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/config/enum.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';

class SettingsThemePicker extends StatelessWidget {
  final ScreenMode selectedMode;
  final ValueChanged<ScreenMode> onModeSelected;

  const SettingsThemePicker({
    super.key,
    required this.selectedMode,
    required this.onModeSelected,
  });

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    final colors = context.appColors;

    return Container(
      padding: const EdgeInsets.all(AppDims.s3),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppDims.rLg),
      ),
      child: Row(
        children: [
          SettingsThemeOption(
            mode: ScreenMode.light,
            label: tr.themeLight,
            selectedMode: selectedMode,
            onTap: () => onModeSelected(ScreenMode.light),
          ),
          const SizedBox(width: AppDims.s2),
          SettingsThemeOption(
            mode: ScreenMode.device,
            label: tr.themeSystem,
            selectedMode: selectedMode,
            onTap: () => onModeSelected(ScreenMode.device),
          ),
          const SizedBox(width: AppDims.s2),
          SettingsThemeOption(
            mode: ScreenMode.dark,
            label: tr.themeDark,
            selectedMode: selectedMode,
            onTap: () => onModeSelected(ScreenMode.dark),
          ),
        ],
      ),
    );
  }
}

class SettingsThemeOption extends StatelessWidget {
  final ScreenMode mode;
  final String label;
  final ScreenMode selectedMode;
  final VoidCallback onTap;

  const SettingsThemeOption({
    super.key,
    required this.mode,
    required this.label,
    required this.selectedMode,
    required this.onTap,
  });

  static Color _backgroundColor(ScreenMode mode) {
    return switch (mode) {
      ScreenMode.light => const Color(0xFFF8FAFC),
      ScreenMode.dark => const Color(0xFF111827),
      ScreenMode.device => const Color(0xFFF8FAFC),
    };
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isSelected = mode == selectedMode;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isSelected
                ? colors.primary.withValues(alpha: 0.10)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(AppDims.rMd),
            border: Border.all(
              color: isSelected ? colors.primary : Colors.transparent,
              width: 1.8,
            ),
          ),
          child: Column(
            children: [
              AspectRatio(
                aspectRatio: 1.16,
                child: Container(
                  decoration: BoxDecoration(
                    color: _backgroundColor(mode),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected
                          ? colors.primary.withValues(alpha: 0.5)
                          : colors.border,
                    ),
                  ),
                  child: mode == ScreenMode.device
                      ? ClipRRect(
                    borderRadius: BorderRadius.circular(9),
                    child: CustomPaint(
                      painter: const _HalfHalfPainter(),
                    ),
                  )
                      : null,
                ),
              ),
              const SizedBox(height: AppDims.s2),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bs200(context).copyWith(
                  color: isSelected ? colors.primary : colors.textSecondary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HalfHalfPainter extends CustomPainter {
  const _HalfHalfPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFFF8FAFC),
    );

    canvas.drawPath(
      Path()
        ..moveTo(size.width, 0)
        ..lineTo(size.width, size.height)
        ..lineTo(0, size.height)
        ..close(),
      Paint()..color = const Color(0xFF111827),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}