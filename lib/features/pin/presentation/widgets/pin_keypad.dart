import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/common/motion/motion.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// iOS passcode pad: round keys with a quiet fill, letters under the digits
/// (Latin locales only), a Delete label in the bottom-right slot that appears
/// once a digit is typed, and an optional biometric key bottom-left.
class PinKeypad extends StatelessWidget {
  const PinKeypad({
    super.key,
    required this.onDigit,
    required this.onBackspace,
    this.enabled = true,
    this.showDelete = false,
    this.leading,
    this.onLeading,
    this.leadingLabel,
  });

  final ValueChanged<String> onDigit;
  final VoidCallback onBackspace;
  final bool enabled;
  final bool showDelete;

  /// Glyph for the bottom-left key (Face ID / fingerprint). Null leaves it empty.
  final Widget? leading;
  final VoidCallback? onLeading;
  final String? leadingLabel;

  static const _letters = {
    '2': 'ABC',
    '3': 'DEF',
    '4': 'GHI',
    '5': 'JKL',
    '6': 'MNO',
    '7': 'PQRS',
    '8': 'TUV',
    '9': 'WXYZ',
  };

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).height < 700;
    final size = compact ? 68.0 : 78.0;
    final latin = Localizations.localeOf(context).languageCode != 'ar';
    final colors = context.appColors;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final keyColor = dark ? colors.surfaceSoft : colors.border;

    Widget digit(String d) => _PadKey(
      size: size,
      color: keyColor,
      pressed: colors.primaryContainer,
      onTap: enabled ? () => onDigit(d) : null,
      semanticLabel: d,
      child: _DigitLabel(
        digit: d,
        letters: latin ? _letters[d] : null,
        enabled: enabled,
      ),
    );

    Widget slot(Widget? child) =>
        SizedBox(width: size, height: size, child: child);

    final Widget left = leading != null && onLeading != null && enabled
        ? _PadKey(
            size: size,
            color: Colors.transparent,
            pressed: colors.primaryContainer,
            onTap: onLeading,
            semanticLabel: leadingLabel,
            child: leading!,
          )
        : slot(null);

    final Widget right = AnimatedOpacity(
      opacity: showDelete && enabled ? 1 : 0,
      duration: Motion.duration(AppDims.fast),
      child: IgnorePointer(
        ignoring: !(showDelete && enabled),
        child: _PadKey(
          size: size,
          color: Colors.transparent,
          pressed: colors.primaryContainer,
          onTap: onBackspace,
          haptic: HapticFeedback.selectionClick,
          semanticLabel: context.tr.delete,
          child: Text(
            context.tr.delete,
            style: Theme.of(context).textTheme.titleMedium!.copyWith(
              color: colors.textPrimary,
              fontWeight: AppTextStyles.medium,
            ),
          ),
        ),
      ),
    );

    // The pad is always left to right, like the hardware keypad it mimics.
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final row in const [
            ['1', '2', '3'],
            ['4', '5', '6'],
            ['7', '8', '9'],
          ])
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var i = 0; i < 3; i++) ...[
                    if (i > 0) const SizedBox(width: 24),
                    digit(row[i]),
                  ],
                ],
              ),
            ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              left,
              const SizedBox(width: 24),
              digit('0'),
              const SizedBox(width: 24),
              right,
            ],
          ),
        ],
      ),
    );
  }
}

class _DigitLabel extends StatelessWidget {
  const _DigitLabel({required this.digit, this.letters, required this.enabled});

  final String digit;
  final String? letters;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final ink = enabled ? colors.textPrimary : colors.disabled;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          digit,
          style: TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            fontSize: 32,
            height: 1,
            fontWeight: AppTextStyles.regular,
            color: ink,
          ),
        ),
        SizedBox(
          height: 13,
          child: letters == null
              ? null
              : Padding(
                  padding: const EdgeInsets.only(top: 3),
                  child: Text(
                    letters!,
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 10,
                      height: 1,
                      letterSpacing: 1.6,
                      fontWeight: AppTextStyles.semibold,
                      color: enabled ? colors.textSecondary : colors.disabled,
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}

class _PadKey extends StatefulWidget {
  const _PadKey({
    required this.size,
    required this.color,
    required this.pressed,
    required this.onTap,
    required this.child,
    this.semanticLabel,
    this.haptic,
  });

  final double size;
  final Color color;
  final Color pressed;
  final VoidCallback? onTap;
  final Widget child;
  final String? semanticLabel;
  final Future<void> Function()? haptic;

  @override
  State<_PadKey> createState() => _PadKeyState();
}

class _PadKeyState extends State<_PadKey> {
  bool _down = false;

  void _set(bool v) {
    if (widget.onTap == null || _down == v) return;
    setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    final d = Motion.duration(const Duration(milliseconds: 90));
    return Semantics(
      button: true,
      label: widget.semanticLabel,
      enabled: widget.onTap != null,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _set(true),
        onTapUp: (_) => _set(false),
        onTapCancel: () => _set(false),
        onTap: widget.onTap == null
            ? null
            : () {
                (widget.haptic ?? HapticFeedback.lightImpact).call();
                widget.onTap!();
              },
        child: AnimatedScale(
          scale: _down ? 0.94 : 1,
          duration: d,
          child: AnimatedContainer(
            duration: d,
            width: widget.size,
            height: widget.size,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _down ? widget.pressed : widget.color,
            ),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
