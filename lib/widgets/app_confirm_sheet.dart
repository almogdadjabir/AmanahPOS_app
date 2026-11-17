import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// iOS style action sheet for destructive confirmations: a title and message
/// card with one destructive action, and a separate Cancel card below.
/// Resolves to true when the destructive action is chosen.
Future<bool> showAppConfirmSheet(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
}) async =>
    await showAppConfirmSheetChoice(
      context,
      title: title,
      message: message,
      confirmLabel: confirmLabel,
    ) ==
    AppConfirmChoice.confirm;

/// What the user picked in [showAppConfirmSheetChoice].
enum AppConfirmChoice { confirm, alternative, cancel }

/// [showAppConfirmSheet] with an optional non-destructive [alternativeLabel]
/// action shown above the destructive one (e.g. "Send now" next to
/// "Discard"). Dismissing the sheet is [AppConfirmChoice.cancel].
Future<AppConfirmChoice> showAppConfirmSheetChoice(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  String? alternativeLabel,
}) async {
  final result = await showModalBottomSheet<AppConfirmChoice>(
    context: context,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.4),
    elevation: 0,
    useSafeArea: true,
    // Long messages (e.g. the merge breakdown) get the room they need and
    // scroll inside the card instead of overflowing.
    isScrollControlled: true,
    builder: (_) => _ConfirmSheet(
      title: title,
      message: message,
      confirmLabel: confirmLabel,
      alternativeLabel: alternativeLabel,
    ),
  );
  return result ?? AppConfirmChoice.cancel;
}

class _ConfirmSheet extends StatelessWidget {
  final String title;
  final String message;
  final String confirmLabel;
  final String? alternativeLabel;

  const _ConfirmSheet({
    required this.title,
    required this.message,
    required this.confirmLabel,
    this.alternativeLabel,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final card = isDark ? colors.surfaceRaised : colors.surface;

    Widget group(List<Widget> children) => DecoratedBox(
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(14),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Column(mainAxisSize: MainAxisSize.min, children: children),
      ),
    );

    Widget action(
      String label, {
      required bool destructive,
      required AppConfirmChoice choice,
      bool bold = false,
    }) {
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          if (destructive) HapticFeedback.mediumImpact();
          Navigator.of(context).pop(choice);
        },
        child: SizedBox(
          height: 57,
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 20,
                fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
                color: destructive ? colors.danger : colors.primary,
              ),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: group([
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  child: Column(
                    children: [
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: colors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        message,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.4,
                          color: colors.textHint,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (alternativeLabel != null) ...[
                Divider(height: 0.5, thickness: 0.5, color: colors.border),
                action(
                  alternativeLabel!,
                  destructive: false,
                  choice: AppConfirmChoice.alternative,
                ),
              ],
              Divider(height: 0.5, thickness: 0.5, color: colors.border),
              action(
                confirmLabel,
                destructive: true,
                choice: AppConfirmChoice.confirm,
              ),
            ]),
          ),
          const SizedBox(height: 8),
          group([
            action(
              context.tr.cancel,
              destructive: false,
              choice: AppConfirmChoice.cancel,
              bold: true,
            ),
          ]),
        ],
      ),
    );
  }
}
