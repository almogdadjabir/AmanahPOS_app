import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Shared layout for the PIN screens: optional header (avatar or mark), title,
/// one line of subtitle that turns into the error message, the dots, and the
/// pad sitting in thumb reach. Hardware-keyboard digits and backspace work too.
class PinScaffold extends StatefulWidget {
  const PinScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.dots,
    required this.keypad,
    required this.onDigit,
    required this.onBackspace,
    this.header,
    this.errorText,
    this.subtitleIsError = false,
    this.footer,
    this.onCancel,
    this.cancelLabel,
  });

  final Widget? header;
  final String title;
  final String subtitle;
  final Widget dots;
  final Widget keypad;
  final ValueChanged<String> onDigit;
  final VoidCallback onBackspace;

  /// Replaces the subtitle, in the error colour, while non-null.
  final String? errorText;

  /// Shows [subtitle] in the error colour (used for the lockout countdown).
  final bool subtitleIsError;
  final Widget? footer;

  /// Shows a Cancel text button at the top for screens opened on top of
  /// another one (change PIN).
  final VoidCallback? onCancel;
  final String? cancelLabel;

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
    if (event.logicalKey == LogicalKeyboardKey.backspace) {
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
    final text = Theme.of(context).textTheme;
    final isError = widget.errorText != null || widget.subtitleIsError;

    return Scaffold(
      backgroundColor: colors.background,
      body: Focus(
        focusNode: _focusNode,
        autofocus: true,
        onKeyEvent: _onKey,
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        if (widget.onCancel != null)
                          Align(
                            alignment: AlignmentDirectional.centerStart,
                            child: TextButton(
                              onPressed: widget.onCancel,
                              child: Text(
                                widget.cancelLabel ?? '',
                                style: text.bodyLarge!.copyWith(
                                  color: colors.primary,
                                ),
                              ),
                            ),
                          ),
                        SizedBox(
                          height: widget.onCancel != null
                              ? 2
                              : widget.header == null
                              ? 46
                              : 34,
                        ),
                        if (widget.header != null) ...[
                          widget.header!,
                          const SizedBox(height: 18),
                        ],
                        Text(
                          widget.title,
                          textAlign: TextAlign.center,
                          style: text.headlineSmall,
                        ),
                        const SizedBox(height: 6),
                        SizedBox(
                          height: 20,
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 150),
                            child: Text(
                              widget.errorText ?? widget.subtitle,
                              key: ValueKey(
                                widget.errorText ?? widget.subtitle,
                              ),
                              textAlign: TextAlign.center,
                              style: text.bodyMedium!.copyWith(
                                fontSize: 15,
                                height: 20 / 15,
                                color: isError
                                    ? colors.danger
                                    : colors.textSecondary,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 30),
                        widget.dots,
                        const Spacer(),
                        widget.keypad,
                        SizedBox(
                          height: 64,
                          child: Center(child: widget.footer),
                        ),
                        const SizedBox(height: 16),
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
}
