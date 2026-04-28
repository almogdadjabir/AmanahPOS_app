import 'package:amana_pos/features/dashboard/data/models/product_category.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';

/// Horizontal scrolling category pills.
class CategoryChips extends StatelessWidget {
  final List<ProductCategory> categories;
  final String activeId;
  final ValueChanged<String> onPick;

  const CategoryChips({
    super.key,
    required this.categories,
    required this.activeId,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(AppDims.s3, AppDims.s3, AppDims.s3, AppDims.s2),
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppDims.s2),
        itemBuilder: (_, i) {
          final c = categories[i];
          final isActive = c.id == activeId;
          return _CategoryChip(category: c, active: isActive, onTap: () => onPick(c.id));
        },
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final ProductCategory category;
  final bool active;
  final VoidCallback onTap;
  const _CategoryChip({required this.category, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final fg = active ? Colors.white : context.appColors.textPrimary;
    final iconColor = active ? Colors.white : category.color;
    return Material(
      color: active ? context.appColors.primary : context.appColors.surface,
      shape: StadiumBorder(
        side: BorderSide(color: active ? context.appColors.primary : context.appColors.border),
      ),
      child: InkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppDims.s4, vertical: AppDims.s2),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(category.icon, size: 18, color: iconColor),
              const SizedBox(width: AppDims.s2),
              Text(
                category.name,
                style: TextStyle(
                  fontFamily: 'NunitoSans', fontSize: 13, fontWeight: FontWeight.w700, color: fg,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
