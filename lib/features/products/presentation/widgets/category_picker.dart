import 'package:amana_pos/features/category/data/models/responses/category_response_dto.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';

class CategoryPicker extends StatelessWidget {
  final List<CategoryData> categories;
  final CategoryData?      selected;
  final ValueChanged<CategoryData> onSelected;

  const CategoryPicker({super.key,
    required this.categories,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return GestureDetector(
      onTap: () => _showPicker(context),
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: AppDims.s3),
        decoration: BoxDecoration(
          color: colors.surfaceSoft,
          borderRadius: BorderRadius.circular(AppDims.rMd),
          border: Border.all(color: colors.border),
        ),
        child: Row(
          children: [
            Icon(Icons.layers_rounded, size: 18, color: colors.textHint),
            const SizedBox(width: AppDims.s2),
            Expanded(
              child: Text(
                selected?.name ?? 'Select a category',
                style: AppTextStyles.bs500(context).copyWith(
                  fontWeight: FontWeight.w600,
                  color: selected != null ? colors.textPrimary : colors.textHint,
                ),
              ),
            ),
            Icon(Icons.keyboard_arrow_down_rounded,
                size: 20, color: colors.textHint),
          ],
        ),
      ),
    );
  }

  void _showPicker(BuildContext context) {
    final colors = context.appColors;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppDims.rXl)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: AppDims.s3),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: colors.border,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppDims.s4),
              child: Text(
                'Select Category',
                style: AppTextStyles.bs600(context).copyWith(
                  fontWeight: FontWeight.w800,
                  color: colors.textPrimary,
                ),
              ),
            ),
            if (categories.isEmpty)
              Padding(
                padding: const EdgeInsets.all(AppDims.s5),
                child: Text(
                  'No categories available',
                  style: AppTextStyles.bs600(context).copyWith(color: colors.textHint),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(
                    AppDims.s4, 0, AppDims.s4, AppDims.s5),
                itemCount:       categories.length,
                separatorBuilder: (_, __) =>
                    Divider(height: 1, color: colors.border),
                itemBuilder: (_, i) {
                  final cat        = categories[i];
                  final isSelected = cat.id == selected?.id;

                  return ListTile(
                    onTap: () {
                      onSelected(cat);
                      Navigator.of(context).pop();
                    },
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color:        colors.primaryContainer,
                        borderRadius: BorderRadius.circular(AppDims.rSm),
                      ),
                      child: Icon(Icons.layers_rounded,
                          size: 18, color: colors.primary),
                    ),
                    title: Text(
                      cat.name ?? '',
                      style: AppTextStyles.bs400(context).copyWith(
                        fontWeight:  isSelected
                            ? FontWeight.w800
                            : FontWeight.w600,
                        color: isSelected ? colors.primary : colors.textPrimary,
                      ),
                    ),
                    trailing: isSelected
                        ? Icon(Icons.check_circle_rounded,
                        color: colors.primary, size: 20)
                        : null,
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}