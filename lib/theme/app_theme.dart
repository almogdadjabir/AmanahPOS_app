import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_text_styles.dart';
import 'app_theme_colors.dart';

abstract final class AppTheme {
  AppTheme._();

  static ThemeData get light =>
      _buildTheme(brightness: Brightness.light, colors: _lightColors);

  static ThemeData get dark =>
      _buildTheme(brightness: Brightness.dark, colors: _darkColors);

  static const AppThemeColors _lightColors = AppThemeColors(
    background: AppColors.lightBackground,
    surface: AppColors.lightSurface,
    surfaceSoft: AppColors.lightSurfaceSoft,
    border: AppColors.lightBorder,
    textPrimary: AppColors.lightTextPrimary,
    textSecondary: AppColors.lightTextSecondary,
    textHint: AppColors.lightTextHint,
    disabled: AppColors.lightDisabled,
    primary: AppColors.primary,
    primaryContainer: AppColors.primaryLight,
    onPrimary: AppColors.white,
    secondary: AppColors.cash,
    secondaryContainer: AppColors.lightCashTint,
    onSecondary: AppColors.lightCashInk,
    success: AppColors.success,
    successContainer: AppColors.successLight,
    danger: AppColors.danger,
    dangerContainer: AppColors.dangerLight,
    warning: AppColors.warning,
    warningContainer: AppColors.warningLight,
    info: AppColors.info,
    infoContainer: AppColors.infoLight,
    sale: AppColors.sale,
    refund: AppColors.refund,
    cash: AppColors.cash,
    card: AppColors.card,
    stockLow: AppColors.stockLow,
    profit: AppColors.profit,
    shadow: AppColors.lightShadow,
    surfaceRaised: AppColors.lightSurfaceRaised,
    borderStrong: AppColors.lightBorderStrong,
    primaryStrong: AppColors.lightPrimaryStrong,
    digitalTint: AppColors.lightDigitalTint,
    digitalInk: AppColors.lightDigitalInk,
    cashTint: AppColors.lightCashTint,
    cashInk: AppColors.lightCashInk,
    premium: AppColors.lightPremium,
    premiumTint: AppColors.lightPremiumTint,
    chartTrack: AppColors.lightChartTrack,
    heroInk: AppColors.white,
    heroGradient: AppColors.lightHeroGradient,
  );

  static const AppThemeColors _darkColors = AppThemeColors(
    background: AppColors.darkBackground,
    surface: AppColors.darkSurface,
    surfaceSoft: AppColors.darkSurfaceSoft,
    border: AppColors.darkBorder,
    textPrimary: AppColors.darkTextPrimary,
    textSecondary: AppColors.darkTextSecondary,
    textHint: AppColors.darkTextHint,
    disabled: AppColors.darkDisabled,
    primary: AppColors.darkPrimary,
    primaryContainer: AppColors.darkPrimaryContainer,
    onPrimary: AppColors.darkOnPrimary,
    secondary: AppColors.darkCash,
    secondaryContainer: AppColors.darkCashTint,
    onSecondary: AppColors.darkCashInk,
    success: AppColors.darkSuccess,
    successContainer: AppColors.darkSuccessContainer,
    danger: AppColors.darkDanger,
    dangerContainer: AppColors.darkDangerContainer,
    warning: AppColors.darkWarning,
    warningContainer: AppColors.darkWarningContainer,
    info: AppColors.darkInfo,
    infoContainer: AppColors.darkInfoContainer,
    sale: AppColors.darkPrimary,
    refund: AppColors.darkDanger,
    cash: AppColors.darkCash,
    card: AppColors.darkDigital,
    stockLow: AppColors.darkWarning,
    profit: AppColors.darkSuccess,
    shadow: AppColors.darkShadow,
    surfaceRaised: AppColors.darkSurfaceRaised,
    borderStrong: AppColors.darkBorderStrong,
    primaryStrong: AppColors.darkPrimaryStrong,
    digitalTint: AppColors.darkDigitalTint,
    digitalInk: AppColors.darkDigitalInk,
    cashTint: AppColors.darkCashTint,
    cashInk: AppColors.darkCashInk,
    premium: AppColors.darkPremium,
    premiumTint: AppColors.darkPremiumTint,
    chartTrack: AppColors.darkChartTrack,
    heroInk: AppColors.darkTextPrimary,
    heroGradient: AppColors.darkHeroGradient,
  );

  static ThemeData _buildTheme({
    required Brightness brightness,
    required AppThemeColors colors,
  }) {
    final bool isDark = brightness == Brightness.dark;

    final ColorScheme colorScheme = ColorScheme(
      brightness: brightness,
      primary: colors.primary,
      onPrimary: colors.onPrimary,
      primaryContainer: colors.primaryContainer,
      onPrimaryContainer: colors.textPrimary,
      secondary: colors.secondary,
      onSecondary: colors.onSecondary,
      secondaryContainer: colors.secondaryContainer,
      onSecondaryContainer: colors.textPrimary,
      error: colors.danger,
      onError: isDark ? AppColors.darkOnPrimary : AppColors.white,
      errorContainer: colors.dangerContainer,
      onErrorContainer: colors.textPrimary,
      surface: colors.surface,
      onSurface: colors.textPrimary,
      outline: colors.border,
      outlineVariant: colors.border,
      shadow: colors.shadow,
      scrim: AppColors.black,
      inverseSurface: colors.textPrimary,
      onInverseSurface: colors.background,
      inversePrimary: colors.primaryStrong,
      surfaceTint: Colors.transparent,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      fontFamily: AppTextStyles.fontFamily,
      fontFamilyFallback: AppTextStyles.fontFallback,
      colorScheme: colorScheme,
      splashColor: colors.primary.withValues(alpha: 0.06),
      highlightColor: Colors.transparent,
      hoverColor: colors.primary.withValues(alpha: 0.04),
      scaffoldBackgroundColor: colors.background,
      canvasColor: colors.background,
      dividerColor: colors.border,
      disabledColor: colors.disabled,
      textTheme: AppTextStyles.buildTextTheme(colors.textPrimary),
      extensions: <ThemeExtension<dynamic>>[colors],

      appBarTheme: _appBarTheme(colors),
      cardTheme: _cardTheme(colors),
      elevatedButtonTheme: _elevatedButtonTheme(colors),
      outlinedButtonTheme: _outlinedButtonTheme(colors),
      textButtonTheme: _textButtonTheme(colors),
      inputDecorationTheme: _inputDecorationTheme(colors),
      bottomNavigationBarTheme: _bottomNavigationBarTheme(colors),
      navigationBarTheme: _navigationBarTheme(colors),
      floatingActionButtonTheme: _floatingActionButtonTheme(colors),
      checkboxTheme: _checkboxTheme(colors),
      switchTheme: _switchTheme(colors),
      bottomSheetTheme: _bottomSheetTheme(colors),
      dialogTheme: _dialogTheme(colors),
      snackBarTheme: _snackBarTheme(colors),
      chipTheme: _chipTheme(colors),
      popupMenuTheme: _popupMenuTheme(colors),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colors.primary,
        linearTrackColor: colors.surfaceSoft,
        circularTrackColor: colors.surfaceSoft,
      ),
    );
  }

  static AppBarTheme _appBarTheme(AppThemeColors colors) {
    return AppBarTheme(
      backgroundColor: colors.background,
      foregroundColor: colors.textPrimary,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontFamily: AppTextStyles.fontFamily,
        fontSize: 20,
        fontWeight: AppTextStyles.semibold,
        color: colors.textPrimary,
      ),
      iconTheme: IconThemeData(color: colors.textPrimary, size: 24),
      actionsIconTheme: IconThemeData(color: colors.textPrimary, size: 24),
    );
  }

  static CardThemeData _cardTheme(AppThemeColors colors) {
    return CardThemeData(
      color: colors.surface,
      surfaceTintColor: Colors.transparent,
      shadowColor: colors.shadow,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: AppDims.borderLg,
        side: BorderSide(color: colors.border, width: 1),
      ),
    );
  }

  static ElevatedButtonThemeData _elevatedButtonTheme(AppThemeColors colors) {
    return ElevatedButtonThemeData(
      style: ButtonStyle(
        minimumSize: const WidgetStatePropertyAll(Size.fromHeight(52)),
        elevation: const WidgetStatePropertyAll(0),
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return colors.disabled;
          }
          return colors.primary;
        }),
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return colors.textHint;
          }
          return colors.onPrimary;
        }),
        splashFactory: NoSplash.splashFactory,
        overlayColor: const WidgetStatePropertyAll(Colors.transparent),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: AppDims.borderMd),
        ),
        textStyle: const WidgetStatePropertyAll(
          TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            fontSize: 15,
            fontWeight: AppTextStyles.semibold,
          ),
        ),
      ),
    );
  }

  static OutlinedButtonThemeData _outlinedButtonTheme(AppThemeColors colors) {
    return OutlinedButtonThemeData(
      style: ButtonStyle(
        minimumSize: const WidgetStatePropertyAll(Size.fromHeight(52)),
        foregroundColor: WidgetStatePropertyAll(colors.primary),
        overlayColor: WidgetStatePropertyAll(
          colors.primary.withValues(alpha: 0.08),
        ),
        side: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return BorderSide(color: colors.disabled);
          }
          return BorderSide(color: colors.border);
        }),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: AppDims.borderMd),
        ),
        textStyle: const WidgetStatePropertyAll(
          TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            fontSize: 15,
            fontWeight: AppTextStyles.semibold,
          ),
        ),
      ),
    );
  }

  static TextButtonThemeData _textButtonTheme(AppThemeColors colors) {
    return TextButtonThemeData(
      style: ButtonStyle(
        foregroundColor: WidgetStatePropertyAll(colors.primary),
        overlayColor: WidgetStatePropertyAll(
          colors.primary.withValues(alpha: 0.08),
        ),
        textStyle: const WidgetStatePropertyAll(
          TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            fontSize: 15,
            fontWeight: AppTextStyles.semibold,
          ),
        ),
      ),
    );
  }

  static InputDecorationTheme _inputDecorationTheme(AppThemeColors colors) {
    OutlineInputBorder border(Color color) {
      return OutlineInputBorder(
        borderRadius: AppDims.borderMd,
        borderSide: BorderSide(color: color, width: 1),
      );
    }

    return InputDecorationTheme(
      filled: true,
      fillColor: colors.surface,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppDims.s4,
        vertical: AppDims.s4,
      ),
      hintStyle: TextStyle(
        color: colors.textHint,
        fontSize: 14,
        fontWeight: AppTextStyles.regular,
      ),
      labelStyle: TextStyle(
        color: colors.textSecondary,
        fontSize: 14,
        fontWeight: AppTextStyles.medium,
      ),
      errorStyle: TextStyle(
        color: colors.danger,
        fontSize: 12,
        fontWeight: AppTextStyles.medium,
      ),
      border: border(colors.border),
      enabledBorder: border(colors.border),
      disabledBorder: border(colors.disabled),
      focusedBorder: border(colors.primary),
      errorBorder: border(colors.danger),
      focusedErrorBorder: border(colors.danger),
    );
  }

  static BottomNavigationBarThemeData _bottomNavigationBarTheme(
    AppThemeColors colors,
  ) {
    return BottomNavigationBarThemeData(
      backgroundColor: colors.surface,
      selectedItemColor: colors.primary,
      unselectedItemColor: colors.textHint,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
      selectedLabelStyle: const TextStyle(
        fontFamily: AppTextStyles.fontFamily,
        fontSize: 12,
        fontWeight: AppTextStyles.bold,
      ),
      unselectedLabelStyle: const TextStyle(
        fontFamily: AppTextStyles.fontFamily,
        fontSize: 12,
        fontWeight: AppTextStyles.medium,
      ),
    );
  }

  static NavigationBarThemeData _navigationBarTheme(AppThemeColors colors) {
    return NavigationBarThemeData(
      height: 72,
      backgroundColor: colors.surface,
      surfaceTintColor: Colors.transparent,
      indicatorColor: colors.primaryContainer,
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final bool selected = states.contains(WidgetState.selected);

        return TextStyle(
          fontFamily: AppTextStyles.fontFamily,
          fontSize: 12,
          fontWeight: selected ? AppTextStyles.bold : AppTextStyles.medium,
          color: selected ? colors.primary : colors.textHint,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final bool selected = states.contains(WidgetState.selected);

        return IconThemeData(
          color: selected ? colors.primary : colors.textHint,
          size: 24,
        );
      }),
    );
  }

  static FloatingActionButtonThemeData _floatingActionButtonTheme(
    AppThemeColors colors,
  ) {
    return FloatingActionButtonThemeData(
      backgroundColor: colors.primary,
      foregroundColor: colors.onPrimary,
      elevation: 0,
      focusElevation: 0,
      hoverElevation: 0,
      highlightElevation: 0,
      shape: RoundedRectangleBorder(borderRadius: AppDims.borderLg),
    );
  }

  static CheckboxThemeData _checkboxTheme(AppThemeColors colors) {
    return CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) return colors.disabled;
        if (states.contains(WidgetState.selected)) return colors.primary;
        return Colors.transparent;
      }),
      checkColor: WidgetStatePropertyAll(colors.onPrimary),
      side: WidgetStateBorderSide.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return BorderSide.none;

        return BorderSide(color: colors.border, width: 1.4);
      }),
      shape: RoundedRectangleBorder(borderRadius: AppDims.borderXs),
    );
  }

  static SwitchThemeData _switchTheme(AppThemeColors colors) {
    return SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) return colors.disabled;
        if (states.contains(WidgetState.selected)) return colors.primary;
        return colors.textHint;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return colors.disabled.withValues(alpha: 0.35);
        }
        if (states.contains(WidgetState.selected)) {
          return colors.primaryContainer;
        }
        return colors.surfaceSoft;
      }),
      trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      overlayColor: const WidgetStatePropertyAll(Colors.transparent),
    );
  }

  static BottomSheetThemeData _bottomSheetTheme(AppThemeColors colors) {
    return BottomSheetThemeData(
      backgroundColor: colors.surface,
      surfaceTintColor: Colors.transparent,
      modalBackgroundColor: colors.surface,
      modalBarrierColor: AppColors.black.withValues(alpha: 0.45),
      dragHandleColor: colors.border,
      dragHandleSize: const Size(48, 5),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppDims.rXl)),
      ),
    );
  }

  static DialogThemeData _dialogTheme(AppThemeColors colors) {
    return DialogThemeData(
      backgroundColor: colors.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: AppDims.borderXl,
        side: BorderSide(color: colors.border, width: 1),
      ),
      titleTextStyle: TextStyle(
        fontFamily: AppTextStyles.fontFamily,
        fontSize: 20,
        fontWeight: AppTextStyles.bold,
        color: colors.textPrimary,
      ),
      contentTextStyle: TextStyle(
        fontFamily: AppTextStyles.fontFamily,
        fontSize: 14,
        fontWeight: AppTextStyles.regular,
        color: colors.textSecondary,
      ),
    );
  }

  static SnackBarThemeData _snackBarTheme(AppThemeColors colors) {
    return SnackBarThemeData(
      backgroundColor: colors.textPrimary,
      contentTextStyle: TextStyle(
        fontFamily: AppTextStyles.fontFamily,
        fontSize: 14,
        fontWeight: AppTextStyles.medium,
        color: colors.background,
      ),
      behavior: SnackBarBehavior.floating,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: AppDims.borderMd),
    );
  }

  static ChipThemeData _chipTheme(AppThemeColors colors) {
    return ChipThemeData(
      backgroundColor: colors.surfaceSoft,
      selectedColor: colors.primaryContainer,
      disabledColor: colors.disabled,
      side: BorderSide(color: colors.border),
      labelStyle: TextStyle(
        fontFamily: AppTextStyles.fontFamily,
        color: colors.textPrimary,
        fontSize: 13,
        fontWeight: AppTextStyles.medium,
      ),
      secondaryLabelStyle: TextStyle(
        fontFamily: AppTextStyles.fontFamily,
        color: colors.primary,
        fontSize: 13,
        fontWeight: AppTextStyles.bold,
      ),
      shape: RoundedRectangleBorder(borderRadius: AppDims.borderPill),
    );
  }

  static PopupMenuThemeData _popupMenuTheme(AppThemeColors colors) {
    return PopupMenuThemeData(
      color: colors.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 4,
      shadowColor: colors.shadow,
      shape: RoundedRectangleBorder(
        borderRadius: AppDims.borderMd,
        side: BorderSide(color: colors.border),
      ),
      textStyle: TextStyle(
        fontFamily: AppTextStyles.fontFamily,
        fontSize: 14,
        fontWeight: AppTextStyles.medium,
        color: colors.textPrimary,
      ),
    );
  }
}
