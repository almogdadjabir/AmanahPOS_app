import 'package:amana_pos/features/login/presentation/widgets/desktop_login_brand_panel.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:amana_pos/common/motion/motion_animate.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Shared layout for both PIN screens. Phone = a single centred column with the
/// keypad in thumb reach; desktop (>= 900) = the emerald brand panel beside a
/// centred card. Physical-keyboard digits and backspace are wired here so both
/// layouts accept typing on desktop.
class PinScaffold extends StatefulWidget {
  const PinScaffold({
    super.key,
    required this.brand,
    required this.title,
    required this.subtitle,
    required this.dots,
    required this.keypad,
    required this.onDigit,
    required this.onBackspace,
    this.errorText,
    this.footer,
  });

  final Widget brand;
  final String title;
  final String subtitle;
  final Widget dots;
  final Widget keypad;
  final ValueChanged<String> onDigit;
  final VoidCallback onBackspace;
  final String? errorText;
  final Widget? footer;

  @override
  State<PinScaffold> createState() => _PinScaffoldState();
}

class _PinScaffoldState extends State<PinScaffold> {
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.backspace) {
      widget.onBackspace();
      return KeyEventResult.handled;
    }
    final label = event.character;
    if (label != null && label.length == 1 && '0123456789'.contains(label)) {
      widget.onDigit(label);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Scaffold(
      backgroundColor: colors.background,
      body: Focus(
        focusNode: _focusNode,
        autofocus: true,
        onKeyEvent: _onKey,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth >= 900;
            if (!isDesktop) {
              return SafeArea(child: _content(context));
            }
            return Row(
              children: [
                const Expanded(flex: 5, child: DesktopLoginBrandPanel()),
                Expanded(
                  flex: 6,
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 460),
                      child: _content(context),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _content(BuildContext context) {
    final colors = context.appColors;

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 28, vertical: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    widget.brand,
                    const SizedBox(height: 28),
                    Text(
                      widget.title,
                      textAlign: TextAlign.center,
                      style:
                          AppTextStyles.bs700(context, color: colors.textPrimary)
                              .copyWith(fontWeight: FontWeight.w700),
                    ).mAnimate(delay: 80.ms).fadeIn(duration: 320.ms),
                    const SizedBox(height: 8),
                    Text(
                      widget.subtitle,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.sm300(context,
                          color: colors.textSecondary),
                    ).mAnimate(delay: 140.ms).fadeIn(duration: 320.ms),
                    const SizedBox(height: 36),
                    widget.dots,
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 20,
                      child: AnimatedOpacity(
                        opacity: widget.errorText == null ? 0 : 1,
                        duration: const Duration(milliseconds: 180),
                        child: Text(
                          widget.errorText ?? '',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.sm200(context,
                              color: colors.danger),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    widget.keypad,
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 44,
                      child: widget.footer ?? const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
