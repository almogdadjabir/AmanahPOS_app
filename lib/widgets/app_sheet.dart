import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/core/responsive/adaptive_sheet.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/widgets/app_button.dart';
import 'package:amana_pos/widgets/pressable.dart';
import 'package:flutter/material.dart';
import 'package:amana_pos/theme/phosphor_icons.dart';

class AppSheetAction {
  final String label;
  final VoidCallback? onTap;
  final bool emphasized;
  final bool destructive;

  const AppSheetAction({
    required this.label,
    required this.onTap,
    this.emphasized = false,
    this.destructive = false,
  });
}

/// The one sheet: grabber, radius 24, title row with optional text actions
/// ("Cancel" / "Done"), keyboard-safe scrolling body, optional sticky footer.
class AppSheet extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final String? logoAsset;
  final Widget child;
  final Widget? footer;
  final AppSheetAction? leadingAction;
  final AppSheetAction? trailingAction;
  final double maxHeightFactor;
  final bool keyboardSafe;
  final bool showGrabber;

  const AppSheet({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.icon,
    this.logoAsset,
    this.footer,
    this.leadingAction,
    this.trailingAction,
    this.maxHeightFactor = 1.0,
    this.keyboardSafe = true,
    this.showGrabber = true,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final bottomInset = keyboardSafe
        ? MediaQuery.viewInsetsOf(context).bottom
        : 0.0;
    final screenHeight = MediaQuery.sizeOf(context).height;
    final hasActions = leadingAction != null || trailingAction != null;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: ConstrainedBox(
        constraints: maxHeightFactor < 1.0
            ? BoxConstraints(maxHeight: screenHeight * maxHeightFactor)
            : const BoxConstraints(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showGrabber)
              Padding(
                padding: const EdgeInsets.only(top: AppDims.s2),
                child: Container(
                  width: 36,
                  height: 5,
                  decoration: BoxDecoration(
                    color: colors.borderStrong.withValues(alpha: 0.5),
                    borderRadius: AppDims.borderPill,
                  ),
                ),
              ),
            _SheetHeader(
              title: title,
              subtitle: subtitle,
              icon: icon,
              logoAsset: logoAsset,
              leadingAction: leadingAction,
              trailingAction: trailingAction,
              showClose: !hasActions,
            ),
            Flexible(
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsetsDirectional.fromSTEB(
                  AppDims.s4,
                  AppDims.s2,
                  AppDims.s4,
                  AppDims.s4,
                ),
                child: child,
              ),
            ),
            if (footer != null)
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(
                  AppDims.s4,
                  AppDims.s2,
                  AppDims.s4,
                  AppDims.s4,
                ),
                child: footer,
              ),
          ],
        ),
      ),
    );
  }
}

class _SheetHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final String? logoAsset;
  final AppSheetAction? leadingAction;
  final AppSheetAction? trailingAction;
  final bool showClose;

  const _SheetHeader({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.logoAsset,
    required this.leadingAction,
    required this.trailingAction,
    required this.showClose,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final text = Theme.of(context).textTheme;
    final subtitleText = subtitle?.trim();
    final hasTextActions = leadingAction != null || trailingAction != null;

    final titleBlock = Column(
      crossAxisAlignment: hasTextActions
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      children: [
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: text.titleMedium!.copyWith(color: colors.textPrimary),
        ),
        if (subtitleText != null && subtitleText.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            subtitleText,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: text.bodySmall!.copyWith(color: colors.textSecondary),
          ),
        ],
      ],
    );

    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppDims.s4,
        AppDims.s3,
        AppDims.s4,
        AppDims.s2,
      ),
      child: Row(
        children: [
          if (leadingAction != null)
            _TextAction(action: leadingAction!)
          else if (hasTextActions)
            const SizedBox(width: 64),
          if (icon != null || logoAsset != null) ...[
            _SheetIcon(icon: icon, logoAsset: logoAsset),
            const SizedBox(width: AppDims.s3),
          ],
          Expanded(child: titleBlock),
          if (trailingAction != null)
            _TextAction(action: trailingAction!)
          else if (hasTextActions)
            const SizedBox(width: 64)
          else if (showClose)
            const _CloseButton(),
        ],
      ),
    );
  }
}

class _TextAction extends StatelessWidget {
  final AppSheetAction action;

  const _TextAction({required this.action});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final enabled = action.onTap != null;

    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 64, minHeight: 44),
      child: Pressable(
        onTap: action.onTap,
        child: Align(
          alignment: AlignmentDirectional.center,
          child: Text(
            action.label,
            style: Theme.of(context).textTheme.titleSmall!.copyWith(
              color: enabled ? colors.primary : colors.disabled,
              fontWeight: action.emphasized ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

class _CloseButton extends StatelessWidget {
  const _CloseButton();

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Pressable(
      onTap: () => Navigator.of(context).pop(),
      semanticLabel: context.tr.close,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: colors.surfaceSoft,
          shape: BoxShape.circle,
        ),
        child: Icon(PhosphorIconsRegular.x, size: 18, color: colors.textSecondary),
      ),
    );
  }
}

class _SheetIcon extends StatelessWidget {
  final IconData? icon;
  final String? logoAsset;

  const _SheetIcon({required this.icon, required this.logoAsset});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
      width: 44,
      height: 44,
      padding: EdgeInsets.all(logoAsset != null ? 7 : 0),
      decoration: BoxDecoration(
        color: logoAsset != null
            ? colors.surfaceRaised
            : colors.primaryContainer,
        borderRadius: AppDims.borderMd,
        border: logoAsset != null ? Border.all(color: colors.border) : null,
      ),
      child: logoAsset != null
          ? Image.asset(
              logoAsset!,
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) =>
                  Icon(icon ?? PhosphorIconsRegular.image, color: colors.primary, size: 22),
            )
          : Icon(icon, color: colors.primary, size: 22),
    );
  }
}

/// Opens [builder] as the shared sheet (Apple sheet curve).
Future<T?> showAppSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  bool isScrollControlled = true,
}) {
  return showAdaptivePanel<T>(
    context,
    builder: builder,
    isScrollControlled: isScrollControlled,
    showDragHandle: false,
  );
}

/// Shared destructive / yes-no confirmation. Resolves to `true` only when
/// the user confirms.
Future<bool> showAppConfirmSheet(
  BuildContext context, {
  required String title,
  String? message,
  required String confirmLabel,
  String? cancelLabel,
  bool destructive = true,
}) async {
  final result = await showAppSheet<bool>(
    context,
    builder: (ctx) {
      final colors = ctx.appColors;
      final text = Theme.of(ctx).textTheme;

      return AppSheet(
        title: title,
        keyboardSafe: false,
        footer: Row(
          children: [
            Expanded(
              child: AppButton(
                label: cancelLabel ?? ctx.tr.cancel,
                variant: AppButtonVariant.secondary,
                onPressed: () => Navigator.of(ctx).pop(false),
              ),
            ),
            const SizedBox(width: AppDims.s3),
            Expanded(
              child: AppButton(
                label: confirmLabel,
                variant: destructive
                    ? AppButtonVariant.danger
                    : AppButtonVariant.primary,
                onPressed: () => Navigator.of(ctx).pop(true),
              ),
            ),
          ],
        ),
        child: message == null
            ? const SizedBox.shrink()
            : Text(
                message,
                style: text.bodyMedium!.copyWith(color: colors.textSecondary),
              ),
      );
    },
  );

  return result ?? false;
}
