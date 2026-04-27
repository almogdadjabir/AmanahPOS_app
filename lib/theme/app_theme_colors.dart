import 'package:flutter/material.dart';

@immutable
class AppThemeColors extends ThemeExtension<AppThemeColors> {
  final Color background;
  final Color surface;
  final Color surfaceSoft;
  final Color border;

  final Color textPrimary;
  final Color textSecondary;
  final Color textHint;
  final Color disabled;

  final Color primary;
  final Color primaryContainer;
  final Color onPrimary;

  final Color secondary;
  final Color secondaryContainer;
  final Color onSecondary;

  final Color success;
  final Color successContainer;
  final Color danger;
  final Color dangerContainer;
  final Color warning;
  final Color warningContainer;
  final Color info;
  final Color infoContainer;

  final Color sale;
  final Color refund;
  final Color cash;
  final Color card;
  final Color stockLow;
  final Color profit;

  final Color shadow;

  const AppThemeColors({
    required this.background,
    required this.surface,
    required this.surfaceSoft,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
    required this.textHint,
    required this.disabled,
    required this.primary,
    required this.primaryContainer,
    required this.onPrimary,
    required this.secondary,
    required this.secondaryContainer,
    required this.onSecondary,
    required this.success,
    required this.successContainer,
    required this.danger,
    required this.dangerContainer,
    required this.warning,
    required this.warningContainer,
    required this.info,
    required this.infoContainer,
    required this.sale,
    required this.refund,
    required this.cash,
    required this.card,
    required this.stockLow,
    required this.profit,
    required this.shadow,
  });

  @override
  AppThemeColors copyWith({
    Color? background,
    Color? surface,
    Color? surfaceSoft,
    Color? border,
    Color? textPrimary,
    Color? textSecondary,
    Color? textHint,
    Color? disabled,
    Color? primary,
    Color? primaryContainer,
    Color? onPrimary,
    Color? secondary,
    Color? secondaryContainer,
    Color? onSecondary,
    Color? success,
    Color? successContainer,
    Color? danger,
    Color? dangerContainer,
    Color? warning,
    Color? warningContainer,
    Color? info,
    Color? infoContainer,
    Color? sale,
    Color? refund,
    Color? cash,
    Color? card,
    Color? stockLow,
    Color? profit,
    Color? shadow,
  }) {
    return AppThemeColors(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceSoft: surfaceSoft ?? this.surfaceSoft,
      border: border ?? this.border,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textHint: textHint ?? this.textHint,
      disabled: disabled ?? this.disabled,
      primary: primary ?? this.primary,
      primaryContainer: primaryContainer ?? this.primaryContainer,
      onPrimary: onPrimary ?? this.onPrimary,
      secondary: secondary ?? this.secondary,
      secondaryContainer: secondaryContainer ?? this.secondaryContainer,
      onSecondary: onSecondary ?? this.onSecondary,
      success: success ?? this.success,
      successContainer: successContainer ?? this.successContainer,
      danger: danger ?? this.danger,
      dangerContainer: dangerContainer ?? this.dangerContainer,
      warning: warning ?? this.warning,
      warningContainer: warningContainer ?? this.warningContainer,
      info: info ?? this.info,
      infoContainer: infoContainer ?? this.infoContainer,
      sale: sale ?? this.sale,
      refund: refund ?? this.refund,
      cash: cash ?? this.cash,
      card: card ?? this.card,
      stockLow: stockLow ?? this.stockLow,
      profit: profit ?? this.profit,
      shadow: shadow ?? this.shadow,
    );
  }

  @override
  AppThemeColors lerp(ThemeExtension<AppThemeColors>? other, double t) {
    if (other is! AppThemeColors) return this;

    return AppThemeColors(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceSoft: Color.lerp(surfaceSoft, other.surfaceSoft, t)!,
      border: Color.lerp(border, other.border, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textHint: Color.lerp(textHint, other.textHint, t)!,
      disabled: Color.lerp(disabled, other.disabled, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      primaryContainer: Color.lerp(primaryContainer, other.primaryContainer, t)!,
      onPrimary: Color.lerp(onPrimary, other.onPrimary, t)!,
      secondary: Color.lerp(secondary, other.secondary, t)!,
      secondaryContainer: Color.lerp(secondaryContainer, other.secondaryContainer, t)!,
      onSecondary: Color.lerp(onSecondary, other.onSecondary, t)!,
      success: Color.lerp(success, other.success, t)!,
      successContainer: Color.lerp(successContainer, other.successContainer, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      dangerContainer: Color.lerp(dangerContainer, other.dangerContainer, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      warningContainer: Color.lerp(warningContainer, other.warningContainer, t)!,
      info: Color.lerp(info, other.info, t)!,
      infoContainer: Color.lerp(infoContainer, other.infoContainer, t)!,
      sale: Color.lerp(sale, other.sale, t)!,
      refund: Color.lerp(refund, other.refund, t)!,
      cash: Color.lerp(cash, other.cash, t)!,
      card: Color.lerp(card, other.card, t)!,
      stockLow: Color.lerp(stockLow, other.stockLow, t)!,
      profit: Color.lerp(profit, other.profit, t)!,
      shadow: Color.lerp(shadow, other.shadow, t)!,
    );
  }
}

extension AppThemeColorsX on BuildContext {
  AppThemeColors get appColors {
    final colors = Theme.of(this).extension<AppThemeColors>();
    assert(colors != null, 'AppThemeColors extension is missing from ThemeData.');
    return colors!;
  }
}