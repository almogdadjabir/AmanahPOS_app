import 'package:amana_pos/core/responsive/responsive.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:flutter/widgets.dart';

class AdaptiveFlex extends StatelessWidget {
  const AdaptiveFlex({
    super.key,
    required this.children,
    this.desktopIsRow = true,
    this.spacing = AppSpacing.md,
    this.crossAxis = CrossAxisAlignment.start,
  });

  final List<Widget> children;
  final bool desktopIsRow;
  final double spacing;
  final CrossAxisAlignment crossAxis;

  @override
  Widget build(BuildContext context) {
    final useRow = context.isDesktop && desktopIsRow;
    return Flex(
      direction: useRow ? Axis.horizontal : Axis.vertical,
      crossAxisAlignment: crossAxis,
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i != 0)
            SizedBox(width: useRow ? spacing : 0, height: useRow ? 0 : spacing),
          children[i],
        ],
      ],
    );
  }
}
