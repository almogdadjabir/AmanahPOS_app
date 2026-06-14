import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/features/category/data/models/responses/category_response_dto.dart';
import 'package:amana_pos/features/category/presentation/bloc/category_bloc.dart';
import 'package:amana_pos/features/category/presentation/category_detail_screen.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/common/motion/motion_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solar_icons/solar_icons.dart';

/// Grid tile for the desktop categories view. A hover-aware card mirroring
/// the pattern of DesktopProductCard — uses a horizontal layout so the icon,
/// name and meta info sit side-by-side in the wider grid slot.
class DesktopCategoryCard extends StatefulWidget {
  final CategoryData category;

  const DesktopCategoryCard({
    super.key,
    required this.category,
  });

  @override
  State<DesktopCategoryCard> createState() => _DesktopCategoryCardState();
}

class _DesktopCategoryCardState extends State<DesktopCategoryCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final tr = context.tr;
    final category = widget.category;

    final rawName = category.name?.trim();
    final name = rawName?.isNotEmpty == true ? rawName! : tr.category;
    final rawDesc = category.description?.trim();
    final description =
        rawDesc?.isNotEmpty == true ? rawDesc! : tr.noDescriptionAdded;
    final isActive = category.isActive ?? false;
    final subCount = category.children?.length ?? 0;
    final iconColor = isActive ? colors.primary : colors.textHint;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppDims.rXl),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppDims.rXl),
          onTap: () => _openDetails(context),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOut,
            padding: const EdgeInsets.all(AppDims.s4),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(AppDims.rXl),
              border: Border.all(
                color: _hovered
                    ? colors.primary.withValues(alpha: 0.35)
                    : colors.border,
                width: _hovered ? 1.3 : 1,
              ),
              boxShadow: _hovered
                  ? [
                      BoxShadow(
                        color: colors.primary.withValues(alpha: 0.10),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.025),
                        blurRadius: 14,
                        offset: const Offset(0, 8),
                      ),
                    ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Icon area
                AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(
                      alpha: _hovered
                          ? (isActive ? 0.14 : 0.10)
                          : (isActive ? 0.10 : 0.06),
                    ),
                    borderRadius: BorderRadius.circular(AppDims.rLg),
                    border: Border.all(
                      color: iconColor.withValues(alpha: isActive ? 0.18 : 0.10),
                    ),
                  ),
                  child: Icon(
                    SolarIconsOutline.layersMinimalistic,
                    size: 26,
                    color: iconColor,
                  ),
                ),

                const SizedBox(width: AppDims.s3),

                // Text content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.bs300(context).copyWith(
                                fontWeight: FontWeight.w900,
                                color: colors.textPrimary,
                                height: 1.1,
                              ),
                            ),
                          ),
                          if (!isActive) ...[
                            const SizedBox(width: AppDims.s2),
                            _InactiveBadge(),
                          ],
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text(
                        description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.sm300(context).copyWith(
                          color: colors.textSecondary,
                          fontWeight: FontWeight.w600,
                          height: 1.35,
                        ),
                      ),
                      if (subCount > 0) ...[
                        const SizedBox(height: AppDims.s2),
                        _SubCategoryChip(count: subCount),
                      ],
                    ],
                  ),
                ),

                const SizedBox(width: AppDims.s3),

                // Hover action indicator
                AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  width: 34,
                  height: 34,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _hovered
                        ? colors.primary.withValues(alpha: 0.10)
                        : colors.surfaceSoft,
                    borderRadius: BorderRadius.circular(AppDims.rMd),
                    border: Border.all(
                      color: _hovered
                          ? colors.primary.withValues(alpha: 0.25)
                          : colors.border,
                    ),
                  ),
                  child: Icon(
                    SolarIconsOutline.altArrowRight,
                    size: 16,
                    color: _hovered ? colors.primary : colors.textHint,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openDetails(BuildContext context) {
    final categoryBloc = context.read<CategoryBloc>();

    Navigator.of(context).push(
      motionPageRoute(
        BlocProvider.value(
          value: categoryBloc,
          child: CategoryDetailScreen(category: widget.category),
        ),
      ),
    );
  }
}

// ── Sub-badge ─────────────────────────────────────────────────────────────────

class _InactiveBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.textHint.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: colors.textHint.withValues(alpha: 0.14),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppDims.s2, vertical: 3),
        child: Text(
          context.tr.inactive,
          style: AppTextStyles.sm100(context).copyWith(
            color: colors.textHint,
            fontWeight: FontWeight.w900,
            height: 1,
          ),
        ),
      ),
    );
  }
}

class _SubCategoryChip extends StatelessWidget {
  final int count;

  const _SubCategoryChip({required this.count});

  @override
  Widget build(BuildContext context) {
    const color = Color(0xFF8B5CF6);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.14)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppDims.s2, vertical: 3),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(SolarIconsOutline.widget, size: 12, color: color),
            const SizedBox(width: 4),
            Text(
              '$count',
              style: AppTextStyles.sm100(context).copyWith(
                color: color,
                fontWeight: FontWeight.w900,
                height: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
