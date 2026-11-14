import 'package:amana_pos/common/motion/motion.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:flutter/material.dart';

/// Shows the app's modal bottom sheet (Apple sheet curve, radius 24).
Future<T?> showAdaptivePanel<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  bool isScrollControlled = true,
  bool showDragHandle = true,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    showDragHandle: showDragHandle,
    backgroundColor: Theme.of(context).colorScheme.surface,
    sheetAnimationStyle: AnimationStyle(
      duration: Motion.duration(AppDims.sheet),
      reverseDuration: Motion.duration(AppDims.sheet),
      curve: AppDims.sheetCurve,
      reverseCurve: AppDims.sheetCurve,
    ),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppDims.rXl)),
    ),
    builder: builder,
  );
}
