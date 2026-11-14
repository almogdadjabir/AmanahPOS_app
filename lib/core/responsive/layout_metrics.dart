import 'package:amana_pos/theme/app_spacing.dart';
import 'package:flutter/widgets.dart';

extension LayoutMetrics on BuildContext {
  EdgeInsets get pagePadding => EdgeInsets.all(
    MediaQuery.sizeOf(this).width >= 600 ? AppDims.s6 : AppDims.s4,
  );

  double get maxContentWidth => 720;

  int gridColumnsFor(double maxWidth, {double tile = 180}) =>
      (maxWidth / tile).floor().clamp(2, 8);
}
