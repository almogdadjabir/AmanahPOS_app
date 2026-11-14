import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';
import 'package:amana_pos/theme/phosphor_icons.dart';

/// The numeric pad. Keys are quiet — borderless, transparent — so the only
/// colour on the screen is the emerald that fills the dots above. Emerald
/// shows only as the press ripple.
class PinKeypad extends StatelessWidget {
  const PinKeypad({
    super.key,
    required this.onDigit,
    required this.onBackspace,
    this.enabled = true,
  });

  final ValueChanged<String> onDigit;
  final VoidCallback onBackspace;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    const rows = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['', '0', '<'],
    ];

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 320),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final row in rows)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  for (final key in row) _key(context, key),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _key(BuildContext context, String key) {
    if (key.isEmpty) return const SizedBox(width: 76, height: 76);

    final colors = context.appColors;
    final isBackspace = key == '<';
    final onTap = !enabled
        ? null
        : isBackspace
            ? onBackspace
            : () => onDigit(key);

    return SizedBox(
      width: 76,
      height: 76,
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          splashColor: colors.primary.withValues(alpha: 0.18),
          highlightColor: colors.primary.withValues(alpha: 0.08),
          child: Center(
            child: isBackspace
                ? Icon(
                    PhosphorIconsRegular.backspace,
                    size: 26,
                    color: enabled ? colors.textSecondary : colors.disabled,
                  )
                : Text(
                    key,
                    style: AppTextStyles.bs400(
                      context,
                      color: enabled ? colors.textPrimary : colors.disabled,
                    ).copyWith(fontWeight: FontWeight.w500),
                  ),
          ),
        ),
      ),
    );
  }
}
