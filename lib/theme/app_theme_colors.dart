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
  final Color surfaceRaised;
  final Color borderStrong;
  final Color primaryStrong;
  final Color digitalTint;
  final Color digitalInk;
  final Color cashTint;
  final Color cashInk;
  final Color premium;
  final Color premiumTint;
  final Color chartTrack;
  final Color heroInk;

  /// Teal hero tile fill. Use once per screen at most.
  final List<Color> heroGradient;

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
    required this.surfaceRaised,
    required this.borderStrong,
    required this.primaryStrong,
    required this.digitalTint,
    required this.digitalInk,
    required this.cashTint,
    required this.cashInk,
    required this.premium,
    required this.premiumTint,
    required this.chartTrack,
    required this.heroInk,
    required this.heroGradient,
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
    Color? surfaceRaised,
    Color? borderStrong,
    Color? primaryStrong,
    Color? digitalTint,
    Color? digitalInk,
    Color? cashTint,
    Color? cashInk,
    Color? premium,
    Color? premiumTint,
    Color? chartTrack,
    Color? heroInk,
    List<Color>? heroGradient,
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
      surfaceRaised: surfaceRaised ?? this.surfaceRaised,
      borderStrong: borderStrong ?? this.borderStrong,
      primaryStrong: primaryStrong ?? this.primaryStrong,
      digitalTint: digitalTint ?? this.digitalTint,
      digitalInk: digitalInk ?? this.digitalInk,
      cashTint: cashTint ?? this.cashTint,
      cashInk: cashInk ?? this.cashInk,
      premium: premium ?? this.premium,
      premiumTint: premiumTint ?? this.premiumTint,
      chartTrack: chartTrack ?? this.chartTrack,
      heroInk: heroInk ?? this.heroInk,
      heroGradient: heroGradient ?? this.heroGradient,
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
      primaryContainer: Color.lerp(
        primaryContainer,
        other.primaryContainer,
        t,
      )!,
      onPrimary: Color.lerp(onPrimary, other.onPrimary, t)!,
      secondary: Color.lerp(secondary, other.secondary, t)!,
      secondaryContainer: Color.lerp(
        secondaryContainer,
        other.secondaryContainer,
        t,
      )!,
      onSecondary: Color.lerp(onSecondary, other.onSecondary, t)!,
      success: Color.lerp(success, other.success, t)!,
      successContainer: Color.lerp(
        successContainer,
        other.successContainer,
        t,
      )!,
      danger: Color.lerp(danger, other.danger, t)!,
      dangerContainer: Color.lerp(dangerContainer, other.dangerContainer, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      warningContainer: Color.lerp(
        warningContainer,
        other.warningContainer,
        t,
      )!,
      info: Color.lerp(info, other.info, t)!,
      infoContainer: Color.lerp(infoContainer, other.infoContainer, t)!,
      sale: Color.lerp(sale, other.sale, t)!,
      refund: Color.lerp(refund, other.refund, t)!,
      cash: Color.lerp(cash, other.cash, t)!,
      card: Color.lerp(card, other.card, t)!,
      stockLow: Color.lerp(stockLow, other.stockLow, t)!,
      profit: Color.lerp(profit, other.profit, t)!,
      shadow: Color.lerp(shadow, other.shadow, t)!,
      surfaceRaised: Color.lerp(surfaceRaised, other.surfaceRaised, t)!,
      borderStrong: Color.lerp(borderStrong, other.borderStrong, t)!,
      primaryStrong: Color.lerp(primaryStrong, other.primaryStrong, t)!,
      digitalTint: Color.lerp(digitalTint, other.digitalTint, t)!,
      digitalInk: Color.lerp(digitalInk, other.digitalInk, t)!,
      cashTint: Color.lerp(cashTint, other.cashTint, t)!,
      cashInk: Color.lerp(cashInk, other.cashInk, t)!,
      premium: Color.lerp(premium, other.premium, t)!,
      premiumTint: Color.lerp(premiumTint, other.premiumTint, t)!,
      chartTrack: Color.lerp(chartTrack, other.chartTrack, t)!,
      heroInk: Color.lerp(heroInk, other.heroInk, t)!,
      heroGradient: [
        for (var i = 0; i < heroGradient.length; i++)
          Color.lerp(heroGradient[i], other.heroGradient[i], t)!,
      ],
    );
  }
}

extension AppThemeColorsX on BuildContext {
  AppThemeColors get appColors {
    final colors = Theme.of(this).extension<AppThemeColors>();
    assert(
      colors != null,
      'AppThemeColors extension is missing from ThemeData.',
    );
    return colors!;
  }
}
