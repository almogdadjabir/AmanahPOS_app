import 'package:amana_pos/core/responsive/responsive.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:flutter/material.dart';

/// Shows a bottom sheet on mobile and a slide-in end-panel on desktop.
/// RTL-aware: the panel slides from the start side in RTL locales.
Future<T?> showAdaptivePanel<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  double desktopWidth = 480,
  bool isScrollControlled = true,
}) {
  if (context.isDesktop) {
    return showGeneralDialog<T>(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.black54,
      transitionDuration: AppDims.medium,
      pageBuilder: (ctx, _, _) {
        final isRtl = Directionality.of(ctx) == TextDirection.rtl;
        return Align(
          alignment: isRtl ? Alignment.centerLeft : Alignment.centerRight,
          child: Material(
            color: Theme.of(ctx).colorScheme.surface,
            child: SizedBox(
              width: desktopWidth,
              height: double.infinity,
              child: SafeArea(child: builder(ctx)),
            ),
          ),
        );
      },
      transitionBuilder: (ctx, anim, _, child) {
        final isRtl = Directionality.of(ctx) == TextDirection.rtl;
        final begin = Offset(isRtl ? -1 : 1, 0);
        return SlideTransition(
          position: Tween(begin: begin, end: Offset.zero)
              .animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
          child: child,
        );
      },
    );
  }

  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    showDragHandle: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
    ),
    builder: builder,
  );
}
