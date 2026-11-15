import 'dart:async';
import 'dart:developer';

import 'package:amana_pos/config/constants.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/utilities/utils.dart';
import 'package:flutter/material.dart';

/// Ported from Baraka's GlobalSnackBar: a banner docked to the top edge that
/// slides down, runs under the status bar, has 32pt bottom corners and a solid
/// tone colour with white centred text. Tap to dismiss.
class GlobalSnackBar {
  GlobalSnackBar._();

  static bool _isTest = false;
  static OverlayEntry? _entry;
  static Timer? _dismissTimer;

  static void enableTestMode() => _isTest = true;

  /// Hard cap so a persistent (error) toast can never brick the UI.
  static const Duration _autoDismissDuration = Duration(seconds: 3);
  static const Duration _persistentMaxDuration = Duration(seconds: 8);

  static void showSuccess({
    required String message,
    bool isAutoDismiss = true,
  }) => show(message: message, isAutoDismiss: isAutoDismiss);

  static void showError({required String message, bool isAutoDismiss = true}) =>
      show(message: message, isError: true, isAutoDismiss: isAutoDismiss);

  static void showWarning({
    required String message,
    bool isAutoDismiss = true,
  }) => show(message: message, isWarning: true, isAutoDismiss: isAutoDismiss);

  static void showInfo({required String message, bool isAutoDismiss = true}) =>
      show(message: message, isInfo: true, isAutoDismiss: isAutoDismiss);

  static void show({
    required String message,
    double? customTop,
    bool isError = false,
    bool isTop = false,
    bool isWarning = false,
    bool isInfo = false,
    bool isAutoDismiss = true,
    bool showIcon = true,
  }) {
    if (_isTest) return;

    Utils.hideKeyboard(Constants.navigatorKey.currentContext);

    final overlayState = Constants.navigatorKey.currentState?.overlay;
    if (overlayState == null || !overlayState.mounted) return;

    _hardRemove();

    final entry = OverlayEntry(
      builder: (context) => _SnackbarWidget(
        message: message,
        isError: isError,
        isInfo: isInfo,
        isWarning: isWarning,
        onDismissed: dismiss,
      ),
    );

    _entry = entry;

    try {
      overlayState.insert(entry);
    } catch (e) {
      log('Error inserting snackbar: $e');
      _entry = null;
      return;
    }

    final ttl = isAutoDismiss ? _autoDismissDuration : _persistentMaxDuration;
    _dismissTimer = Timer(ttl, _hardRemove);
  }

  static void dismiss() => _hardRemove();

  static void _hardRemove() {
    _dismissTimer?.cancel();
    _dismissTimer = null;

    final entry = _entry;
    _entry = null;
    if (entry == null) return;

    try {
      entry.remove();
    } catch (e) {
      log('Error removing snackbar: $e');
    }
  }
}

enum _Tone { negative, positive, warning, info }

class _SnackbarWidget extends StatefulWidget {
  const _SnackbarWidget({
    required this.message,
    required this.isError,
    required this.isWarning,
    required this.isInfo,
    required this.onDismissed,
  });

  final String message;
  final bool isError;
  final bool isWarning;
  final bool isInfo;
  final VoidCallback onDismissed;

  @override
  State<_SnackbarWidget> createState() => _SnackbarWidgetState();
}

class _SnackbarWidgetState extends State<_SnackbarWidget>
    with SingleTickerProviderStateMixin {
  static const Duration _enter = Duration(milliseconds: 300);

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: _enter,
  );
  late final Animation<double> _progress = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOutCubic,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 1;
    } else if (_controller.isDismissed) {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  _Tone get _tone {
    if (widget.isError) return _Tone.negative;
    if (widget.isWarning) return _Tone.warning;
    if (widget.isInfo) return _Tone.info;
    return _Tone.positive;
  }

  // Baraka design-system values: 600 tones on light, 500 on dark.
  Color _background(bool dark) => switch (_tone) {
    _Tone.negative => dark ? const Color(0xFFF43F5E) : const Color(0xFFE11D48),
    _Tone.positive => dark ? const Color(0xFF22C55E) : const Color(0xFF16A34A),
    _Tone.warning => dark ? const Color(0xFFF97316) : const Color(0xFFEA580C),
    _Tone.info => dark ? const Color(0xFF3B82F6) : const Color(0xFF2563EB),
  };

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final top = MediaQuery.paddingOf(context).top;
    final topPadding = top + 8 > 72 ? top + 8 : 72.0;

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: AnimatedBuilder(
        animation: _progress,
        builder: (context, child) => FractionalTranslation(
          translation: Offset(0, _progress.value - 1),
          child: child,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(32),
            ),
            boxShadow: [
              BoxShadow(
                color: dark ? const Color(0x33000000) : const Color(0x33999999),
                offset: const Offset(0, 6),
                blurRadius: 16,
                spreadRadius: -4,
              ),
            ],
          ),
          child: Material(
            type: MaterialType.transparency,
            child: Semantics(
              container: true,
              liveRegion: true,
              child: GestureDetector(
                onTap: widget.onDismissed,
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.fromLTRB(24, topPadding, 24, 16),
                  decoration: BoxDecoration(
                    color: _background(dark),
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(32),
                    ),
                  ),
                  child: Text(
                    widget.message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontFamilyFallback: AppTextStyles.fontFallback,
                      fontSize: 17,
                      height: 20 / 17,
                      letterSpacing: -0.41,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
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
}
