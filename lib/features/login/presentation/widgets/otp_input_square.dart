import 'dart:math';
import 'package:amana_pos/common/motion/motion.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class OTPInputSquare extends StatefulWidget {
  final String state;
  final bool isOTPMatched;
  final bool isLoading;
  final bool is6Digit;
  final bool hasError;
  final ValueChanged<String> onChanged;
  final VoidCallback? onCompleted;

  const OTPInputSquare({
    super.key,
    required this.state,
    required this.onChanged,
    this.onCompleted,
    this.isOTPMatched = false,
    this.isLoading = false,
    this.is6Digit = true,
    this.hasError = false,
  });

  @override
  State<OTPInputSquare> createState() => _OTPInputSquareState();
}

class _OTPInputSquareState extends State<OTPInputSquare>
    with SingleTickerProviderStateMixin {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  late final AnimationController _shakeController;

  String _lastReported = '';
  bool _completed = false;

  int get _otpLength => widget.is6Digit ? 6 : 4;

  // Horizontal shake offset: sine wave over animation progress
  double get _shakeOffset =>
      sin(_shakeController.value * pi * 5) *
      10 *
      (1 - _shakeController.value); // dampens toward end

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.state);
    _lastReported = widget.state;
    _focusNode = FocusNode();
    _controller.addListener(_onInput);
    _controller.addListener(_rebuild);
    _focusNode.addListener(_rebuild);

    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

  @override
  void didUpdateWidget(OTPInputSquare oldWidget) {
    super.didUpdateWidget(oldWidget);

    // ── Shake only when error first appears, never when clearing ──
    if (!oldWidget.hasError && widget.hasError) {
      HapticFeedback.heavyImpact();
      if (Motion.on) _shakeController.forward(from: 0);
    }
    if (!oldWidget.isOTPMatched && widget.isOTPMatched) {
      HapticFeedback.mediumImpact();
    }

    if (oldWidget.state == widget.state) return;

    _lastReported = widget.state;
    if (widget.state.length < _otpLength) _completed = false;

    if (_controller.text != widget.state) {
      _controller.removeListener(_onInput);
      _controller.value = TextEditingValue(
        text: widget.state,
        selection: TextSelection.collapsed(offset: widget.state.length),
      );
      _controller.addListener(_onInput);
    }

    _maybeComplete(widget.state);

    if (widget.state.isEmpty && oldWidget.state.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _focusNode.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onInput);
    _controller.dispose();
    _focusNode.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  void _onInput() {
    if (!mounted) return;

    final text = _controller.text;
    if (text.length < _otpLength) _completed = false;

    if (text != _lastReported) {
      if (text.length > _lastReported.length) HapticFeedback.selectionClick();
      _lastReported = text;
      widget.onChanged(text);
    }

    _maybeComplete(text);
  }

  void _maybeComplete(String text) {
    if (text.length != _otpLength || _completed) return;
    _completed = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_completed) return;
      FocusScope.of(context).unfocus();
      TextInput.finishAutofillContext();
      widget.onCompleted?.call();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Digits always run left to right, in Arabic too.
    return Directionality(
      textDirection: TextDirection.ltr,
      child: AutofillGroup(
        child: AnimatedBuilder(
          animation: _shakeController,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(_shakeOffset, 0), // horizontal only, never rotates
              child: child,
            );
          },
          child: Stack(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _otpLength,
                  (i) => _buildDigitBox(context, i),
                ),
              ),
              _buildHiddenTextField(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHiddenTextField() {
    return Positioned.fill(
      child: Opacity(
        opacity: 0,
        child: TextField(
          controller: _controller,
          focusNode: _focusNode,
          autofillHints: const [AutofillHints.oneTimeCode],
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.done,
          enableSuggestions: false,
          autocorrect: false,
          enableInteractiveSelection: false,
          maxLength: _otpLength,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration.collapsed(hintText: ''),
        ),
      ),
    );
  }

  Widget _buildDigitBox(BuildContext context, int index) {
    final colors = context.appColors;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final digit = index < _controller.text.length
        ? _controller.text[index]
        : '';
    final isActive =
        _focusNode.hasFocus &&
        !widget.hasError &&
        !widget.isOTPMatched &&
        index == _controller.text.length.clamp(0, _otpLength - 1);

    final Color border = widget.hasError
        ? colors.danger
        : isActive
        ? colors.primary
        : dark
        ? colors.border
        : Colors.transparent;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: widget.is6Digit ? 4 : AppDims.s2,
      ),
      child: AnimatedContainer(
        duration: Motion.duration(AppDims.medium),
        width: widget.is6Digit ? 46 : 56,
        height: 58,
        decoration: BoxDecoration(
          color: _boxColor(colors),
          borderRadius: AppDims.borderMd,
          border: Border.all(color: border, width: 1.5),
        ),
        alignment: Alignment.center,
        child: Text(
          digit,
          style: TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            fontSize: 26,
            height: 1,
            fontWeight: AppTextStyles.semibold,
            fontFeatures: AppTextStyles.tabularFigures,
            color: _textColor(colors),
          ),
        ),
      ),
    );
  }

  Color _boxColor(AppThemeColors colors) {
    if (widget.hasError) return colors.dangerContainer;
    if (widget.isOTPMatched) return colors.successContainer;
    return colors.surface;
  }

  Color _textColor(AppThemeColors colors) {
    if (widget.hasError) return colors.danger;
    if (widget.isOTPMatched) return colors.success;
    return colors.textPrimary;
  }
}
