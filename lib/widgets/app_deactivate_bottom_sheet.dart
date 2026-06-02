import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/core/responsive/adaptive_sheet.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';
import 'package:solar_icons/solar_icons.dart';

class AppDeactivateBottomSheet extends StatelessWidget {
  const AppDeactivateBottomSheet({
    super.key,
    required this.title,
    required this.description,
    required this.isLoading,
    required this.onConfirm,
    this.cancelText,
    this.confirmText,
    this.icon = SolarIconsOutline.forbiddenCircle,
    this.confirmIcon,
    this.confirmColor,
  });

  final String title;
  final String description;
  final String? cancelText;
  final String? confirmText;
  final bool isLoading;
  final VoidCallback? onConfirm;
  final IconData icon;
  final IconData? confirmIcon;
  final Color? confirmColor;

  static Future<T?> show<T>({
    required BuildContext context,
    required Widget child,
  }) {
    return showAdaptivePanel<T>(
      context,
      desktopWidth: 360,
      builder: (_) => child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final dangerColor = confirmColor ?? colors.danger;

    final resolvedCancelText = cancelText ?? context.tr.cancel;
    final resolvedConfirmText = confirmText ?? context.tr.deactivate;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SafeArea(
        top: false,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppDims.rXl),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 28,
                offset: const Offset(0, -8),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(
              AppDims.s4,
              AppDims.s3,
              AppDims.s4,
              AppDims.s4,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const _BottomSheetHandle(),
                const SizedBox(height: AppDims.s4),
                _DangerIcon(
                  icon: icon,
                  color: dangerColor,
                ),
                const SizedBox(height: AppDims.s3),
                _Title(title: title),
                const SizedBox(height: AppDims.s2),
                _Description(description: description),
                const SizedBox(height: AppDims.s5),
                _ActionsRow(
                  cancelText: resolvedCancelText,
                  confirmText: resolvedConfirmText,
                  confirmIcon: confirmIcon ?? icon,
                  dangerColor: dangerColor,
                  isLoading: isLoading,
                  onCancel: () => Navigator.of(context).pop(),
                  onConfirm: onConfirm,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BottomSheetHandle extends StatelessWidget {
  const _BottomSheetHandle();

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.border,
        borderRadius: BorderRadius.circular(999),
      ),
      child: const SizedBox(
        width: 38,
        height: 4,
      ),
    );
  }
}

class _DangerIcon extends StatelessWidget {
  const _DangerIcon({
    required this.icon,
    required this.color,
  });

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        shape: BoxShape.circle,
        border: Border.all(
          color: color.withValues(alpha: 0.18),
        ),
      ),
      child: SizedBox(
        width: 70,
        height: 70,
        child: Icon(
          icon,
          size: 32,
          color: color,
        ),
      ),
    );
  }
}

class _Title extends StatelessWidget {
  const _Title({
    required this.title,
  });

  final String title;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Text(
      title,
      textAlign: TextAlign.center,
      style: AppTextStyles.bs700(context).copyWith(
        fontWeight: FontWeight.w900,
        color: colors.textPrimary,
        height: 1.1,
      ),
    );
  }
}

class _Description extends StatelessWidget {
  const _Description({
    required this.description,
  });

  final String description;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Padding(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: AppDims.s3,
      ),
      child: Text(
        description,
        textAlign: TextAlign.center,
        style: AppTextStyles.bs300(context).copyWith(
          fontWeight: FontWeight.w700,
          color: colors.textSecondary,
          height: 1.45,
        ),
      ),
    );
  }
}

class _ActionsRow extends StatelessWidget {
  const _ActionsRow({
    required this.cancelText,
    required this.confirmText,
    required this.confirmIcon,
    required this.dangerColor,
    required this.isLoading,
    required this.onCancel,
    required this.onConfirm,
  });

  final String cancelText;
  final String confirmText;
  final IconData confirmIcon;
  final Color dangerColor;
  final bool isLoading;
  final VoidCallback onCancel;
  final VoidCallback? onConfirm;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _CancelButton(
            text: cancelText,
            isLoading: isLoading,
            onPressed: onCancel,
          ),
        ),
        const SizedBox(width: AppDims.s3),
        Expanded(
          child: _ConfirmButton(
            text: confirmText,
            icon: confirmIcon,
            color: dangerColor,
            isLoading: isLoading,
            onPressed: onConfirm,
          ),
        ),
      ],
    );
  }
}

class _CancelButton extends StatelessWidget {
  const _CancelButton({
    required this.text,
    required this.isLoading,
    required this.onPressed,
  });

  final String text;
  final bool isLoading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return SizedBox(
      height: 52,
      child: OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: colors.textPrimary,
          disabledForegroundColor: colors.textHint,
          side: BorderSide(color: colors.border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDims.rMd),
          ),
        ),
        child: Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.bs400(context).copyWith(
            fontWeight: FontWeight.w900,
            color: isLoading ? colors.textHint : colors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _ConfirmButton extends StatelessWidget {
  const _ConfirmButton({
    required this.text,
    required this.icon,
    required this.color,
    required this.isLoading,
    required this.onPressed,
  });

  final String text;
  final IconData icon;
  final Color color;
  final bool isLoading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return SizedBox(
      height: 52,
      child: FilledButton(
        onPressed: isLoading ? null : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: color,
          disabledBackgroundColor: colors.border,
          foregroundColor: Colors.white,
          disabledForegroundColor: colors.textHint,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDims.rMd),
          ),
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 160),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          child: isLoading
              ? const SizedBox(
            key: ValueKey('loading'),
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: Colors.white,
            ),
          )
              : _ConfirmButtonContent(
            key: const ValueKey('content'),
            text: text,
            icon: icon,
          ),
        ),
      ),
    );
  }
}

class _ConfirmButtonContent extends StatelessWidget {
  const _ConfirmButtonContent({
    super.key,
    required this.text,
    required this.icon,
  });

  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          icon,
          size: 18,
          color: Colors.white,
        ),
        const SizedBox(width: AppDims.s2),
        Flexible(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bs400(context).copyWith(
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}