import 'package:amana_pos/features/main_screen/data/section.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';

class FeatureListItem extends StatefulWidget {
  final SectionItem  item;
  final VoidCallback onPick;

  const FeatureListItem({
    super.key,
    required this.item,
    required this.onPick,
  });

  @override
  State<FeatureListItem> createState() => _FeatureListItemState();
}

class _FeatureListItemState extends State<FeatureListItem> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final active = item.active;
    final color = item.color;
    final colors = context.appColors;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        item.onTap?.call();
        widget.onPick();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 80),
        color: _pressed
            ? color.withValues(alpha: 0.06)
            : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        height: 62,
        child: Row(
          children: [

            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width:  40, height: 40,
              decoration: BoxDecoration(
                color: active
                    ? color.withValues(alpha: 0.13)
                    : colors.surfaceSoft,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                item.icon,
                size:  20,
                color: active ? color : colors.textSecondary,
              ),
            ),

            const SizedBox(width: 14),

            Expanded(
              child: Text(
                item.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bs400(context).copyWith(
                  fontWeight: FontWeight.w800,
                  color:      active ? color : colors.textPrimary,
                ),
              ),
            ),

            Icon(
              Icons.chevron_right_rounded,
              size:  20,
              color: active
                  ? color.withValues(alpha: 0.60)
                  : colors.textHint.withValues(alpha: 0.40),
            ),
          ],
        ),
      ),
    );
  }
}