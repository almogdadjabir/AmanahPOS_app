import 'dart:async';
import 'dart:developer';

import 'package:amana_pos/config/constants.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/utilities/utils.dart';
import 'package:flutter/material.dart';

enum SnackBarType {
  success,
  error,
  warning,
  info,
}

class GlobalSnackBar {
  static bool _isTest = false;
  static OverlayEntry? _currentOverlay;
  static bool _isAnimating = false;

  static void enableTestMode() => _isTest = true;

  static void showSuccess({
    required String message,
    bool isTop = false,
    bool isAutoDismiss = true,
  }) {
    show(
      message: message,
      type: SnackBarType.success,
      isTop: isTop,
      isAutoDismiss: isAutoDismiss,
    );
  }

  static void showError({
    required String message,
    bool isTop = false,
    bool isAutoDismiss = true,
  }) {
    show(
      message: message,
      type: SnackBarType.error,
      isTop: isTop,
      isAutoDismiss: isAutoDismiss,
    );
  }

  static void showWarning({
    required String message,
    bool isTop = false,
    bool isAutoDismiss = true,
  }) {
    show(
      message: message,
      type: SnackBarType.warning,
      isTop: isTop,
      isAutoDismiss: isAutoDismiss,
    );
  }

  static void showInfo({
    required String message,
    bool isTop = false,
    bool isAutoDismiss = true,
  }) {
    show(
      message: message,
      type: SnackBarType.info,
      isTop: isTop,
      isAutoDismiss: isAutoDismiss,
    );
  }

  static void show({
    required String message,
    SnackBarType type = SnackBarType.success,
    double? customTop,
    bool isTop = false,
    bool isAutoDismiss = true,

    /// Old API compatibility
    bool isError = false,
    bool isWarning = false,
    bool isInfo = false,
    bool showIcon = true,
  }) {
    if (_isTest) return;

    final context = Constants.navigatorKey.currentContext;
    Utils.hideKeyboard(context);

    final resolvedType = _resolveType(
      type: type,
      isError: isError,
      isWarning: isWarning,
      isInfo: isInfo,
    );

    if (_isAnimating) {
      Future<void>.delayed(const Duration(milliseconds: 250), () {
        show(
          message: message,
          type: resolvedType,
          customTop: customTop,
          isTop: isTop,
          isAutoDismiss: isAutoDismiss,
          showIcon: showIcon,
        );
      });
      return;
    }

    final overlayState = Constants.navigatorKey.currentState?.overlay;
    if (overlayState == null || !overlayState.mounted) return;

    dismiss();

    Future<void>.delayed(const Duration(milliseconds: 40), () {
      if (!overlayState.mounted) return;

      final overlay = OverlayEntry(
        builder: (_) {
          return _AppSnackBarOverlay(
            message: message,
            type: resolvedType,
            customTop: customTop,
            isTop: isTop,
            isAutoDismiss: isAutoDismiss,
            showIcon: showIcon,
            onDismissed: () => _removeOverlay(_currentOverlay),
          );
        },
      );

      _currentOverlay = overlay;

      try {
        overlayState.insert(overlay);
      } catch (error, stackTrace) {
        log(
          'Error inserting snackbar',
          error: error,
          stackTrace: stackTrace,
        );
        _currentOverlay = null;
      }
    });
  }

  static SnackBarType _resolveType({
    required SnackBarType type,
    required bool isError,
    required bool isWarning,
    required bool isInfo,
  }) {
    if (isError) return SnackBarType.error;
    if (isWarning) return SnackBarType.warning;
    if (isInfo) return SnackBarType.info;
    return type;
  }

  static void dismiss() {
    final overlay = _currentOverlay;
    if (overlay == null) return;

    _removeOverlay(overlay);
  }

  static void _removeOverlay(OverlayEntry? overlay) {
    if (overlay == null) return;

    _isAnimating = true;

    try {
      if (overlay.mounted) {
        overlay.remove();
      }
    } catch (error, stackTrace) {
      log(
        'Error removing snackbar overlay',
        error: error,
        stackTrace: stackTrace,
      );
    } finally {
      if (overlay == _currentOverlay) {
        _currentOverlay = null;
      }

      Future<void>.delayed(const Duration(milliseconds: 80), () {
        _isAnimating = false;
      });
    }
  }
}

class _AppSnackBarOverlay extends StatefulWidget {
  final String message;
  final SnackBarType type;
  final bool isTop;
  final bool isAutoDismiss;
  final bool showIcon;
  final double? customTop;
  final VoidCallback onDismissed;

  const _AppSnackBarOverlay({
    required this.message,
    required this.type,
    required this.isTop,
    required this.isAutoDismiss,
    required this.showIcon,
    required this.onDismissed,
    this.customTop,
  });

  @override
  State<_AppSnackBarOverlay> createState() => _AppSnackBarOverlayState();
}

class _AppSnackBarOverlayState extends State<_AppSnackBarOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;

  Timer? _dismissTimer;
  bool _isDismissed = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 360),
      reverseDuration: const Duration(milliseconds: 220),
    );

    _slideAnimation = Tween<Offset>(
      begin: Offset(widget.isTop ? 0 : 0, widget.isTop ? -0.45 : 0.45),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      ),
    );

    _fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
        reverseCurve: Curves.easeIn,
      ),
    );

    _scaleAnimation = Tween<double>(
      begin: 0.96,
      end: 1,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutBack,
        reverseCurve: Curves.easeIn,
      ),
    );

    _controller.forward();

    if (widget.isAutoDismiss) {
      _dismissTimer = Timer(const Duration(seconds: 3), _dismiss);
    }
  }

  Future<void> _dismiss() async {
    if (_isDismissed || !mounted) return;

    _isDismissed = true;
    _dismissTimer?.cancel();

    try {
      await _controller.reverse();
      if (mounted) {
        widget.onDismissed();
      }
    } catch (error, stackTrace) {
      log(
        'Error dismissing snackbar',
        error: error,
        stackTrace: stackTrace,
      );
      widget.onDismissed();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final config = _SnackBarStyleConfig.fromType(colors, widget.type);

    final mediaQuery = MediaQuery.of(context);
    final double topPosition = widget.customTop ??
        (widget.isTop
            ? mediaQuery.padding.top + 16
            : 0);

    final double bottomPosition = mediaQuery.padding.bottom + 24;

    return Positioned(
      top: widget.isTop ? topPosition : null,
      bottom: widget.isTop ? null : bottomPosition,
      left: AppSpacing.md,
      right: AppSpacing.md,
      child: SafeArea(
        top: false,
        bottom: false,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Material(
                color: Colors.transparent,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _dismiss,
                  child: Container(
                    constraints: const BoxConstraints(
                      minHeight: 58,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: config.backgroundColor,
                      borderRadius: AppRadius.borderLg,
                      border: Border.all(
                        color: config.borderColor,
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: colors.shadow,
                          blurRadius: 26,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        if (widget.showIcon) ...[
                          _SnackBarIcon(config: config),
                          AppGap.horizontalSm,
                        ],
                        Expanded(
                          child: Text(
                            widget.message,
                            maxLines: 4,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: AppTextStyles.fontFamily,
                              color: config.textColor,
                              fontSize: 14,
                              height: 1.35,
                              fontWeight: AppTextStyles.semibold,
                            ),
                          ),
                        ),
                        if (!widget.isAutoDismiss) ...[
                          AppGap.horizontalSm,
                          InkWell(
                            onTap: _dismiss,
                            borderRadius: AppRadius.borderXxl,
                            child: Padding(
                              padding: const EdgeInsets.all(4),
                              child: Icon(
                                Icons.close_rounded,
                                color: config.textColor,
                                size: 20,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }
}

class _SnackBarIcon extends StatelessWidget {
  final _SnackBarStyleConfig config;

  const _SnackBarIcon({
    required this.config,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: config.iconBackgroundColor,
        shape: BoxShape.circle,
      ),
      child: Icon(
        config.icon,
        color: config.iconColor,
        size: 19,
      ),
    );
  }
}

class _SnackBarStyleConfig {
  final Color backgroundColor;
  final Color borderColor;
  final Color textColor;
  final Color iconBackgroundColor;
  final Color iconColor;
  final IconData icon;

  const _SnackBarStyleConfig({
    required this.backgroundColor,
    required this.borderColor,
    required this.textColor,
    required this.iconBackgroundColor,
    required this.iconColor,
    required this.icon,
  });

  factory _SnackBarStyleConfig.fromType(
      AppThemeColors colors,
      SnackBarType type,
      ) {
    switch (type) {
      case SnackBarType.success:
        return _SnackBarStyleConfig(
          backgroundColor: colors.successContainer,
          borderColor: colors.success.withValues(alpha: 0.35),
          textColor: colors.success,
          iconBackgroundColor: colors.success.withValues(alpha: 0.14),
          iconColor: colors.success,
          icon: Icons.check_circle_rounded,
        );

      case SnackBarType.error:
        return _SnackBarStyleConfig(
          backgroundColor: colors.dangerContainer,
          borderColor: colors.danger.withValues(alpha: 0.35),
          textColor: colors.danger,
          iconBackgroundColor: colors.danger.withValues(alpha: 0.14),
          iconColor: colors.danger,
          icon: Icons.error_rounded,
        );

      case SnackBarType.warning:
        return _SnackBarStyleConfig(
          backgroundColor: colors.warningContainer,
          borderColor: colors.warning.withValues(alpha: 0.40),
          textColor: colors.warning,
          iconBackgroundColor: colors.warning.withValues(alpha: 0.16),
          iconColor: colors.warning,
          icon: Icons.warning_amber_rounded,
        );

      case SnackBarType.info:
        return _SnackBarStyleConfig(
          backgroundColor: colors.infoContainer,
          borderColor: colors.info.withValues(alpha: 0.35),
          textColor: colors.info,
          iconBackgroundColor: colors.info.withValues(alpha: 0.14),
          iconColor: colors.info,
          icon: Icons.info_rounded,
        );
    }
  }
}