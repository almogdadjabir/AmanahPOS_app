import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/common/widgets/app_progress_line.dart';
import 'package:amana_pos/features/category/presentation/widgets/add_category_sheet.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';
import 'package:solar_icons/solar_icons.dart';

/// Desktop categories header: icon + title, a live-search field, a refresh
/// button and a primary "New category" action — mirrors DesktopProductsTopBar.
class DesktopCategoriesTopBar extends StatelessWidget {
  final TextEditingController searchCtrl;
  final Future<void> Function() onRefresh;

  const DesktopCategoriesTopBar({
    super.key,
    required this.searchCtrl,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final tr = context.tr;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 80,
          child: Padding(
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: AppDims.s5,
            ),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: colors.primary.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(AppDims.rMd),
                    border: Border.all(
                      color: colors.primary.withValues(alpha: 0.16),
                    ),
                  ),
                  child: Icon(
                    SolarIconsOutline.layersMinimalistic,
                    color: colors.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: AppDims.s3),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      tr.productCategoriesTitle,
                      style: AppTextStyles.bs300(context).copyWith(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w900,
                        height: 1.05,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      tr.productCategoriesSubtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.sm300(context).copyWith(
                        color: colors.textSecondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: AppDims.s6),
                Expanded(
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 440),
                      child: _SearchField(controller: searchCtrl),
                    ),
                  ),
                ),
                const SizedBox(width: AppDims.s4),
                _RefreshButton(onRefresh: onRefresh),
                const SizedBox(width: AppDims.s3),
                _AddCategoryButton(),
              ],
            ),
          ),
        ),
        const AppProgressLine(),
      ],
    );
  }
}

// ── Search field ─────────────────────────────────────────────────────────────

class _SearchField extends StatelessWidget {
  final TextEditingController controller;

  const _SearchField({required this.controller});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final hasText = controller.text.trim().isNotEmpty;

        return TextField(
          controller: controller,
          style: AppTextStyles.bs200(context).copyWith(
            color: colors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
          decoration: InputDecoration(
            isDense: true,
            hintText: 'Search by name or description',
            hintStyle: AppTextStyles.bs200(context).copyWith(
              color: colors.textHint,
              fontWeight: FontWeight.w600,
            ),
            prefixIcon: Icon(
              SolarIconsOutline.magnifier,
              size: 18,
              color: colors.textHint,
            ),
            suffixIcon: hasText
                ? InkWell(
                    onTap: controller.clear,
                    borderRadius: BorderRadius.circular(999),
                    child: Icon(
                      SolarIconsOutline.closeCircle,
                      size: 18,
                      color: colors.textHint,
                    ),
                  )
                : null,
            filled: true,
            fillColor: colors.surfaceSoft,
            contentPadding: const EdgeInsets.symmetric(
              vertical: AppDims.s3,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDims.rMd),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDims.rMd),
              borderSide: BorderSide(color: colors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDims.rMd),
              borderSide: BorderSide(color: colors.primary, width: 1.5),
            ),
          ),
        );
      },
    );
  }
}

// ── Add category button ───────────────────────────────────────────────────────

class _AddCategoryButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final tr = context.tr;

    return Material(
      color: colors.primary,
      borderRadius: BorderRadius.circular(AppDims.rMd),
      child: InkWell(
        onTap: () => showAddCategorySheet(context),
        borderRadius: BorderRadius.circular(AppDims.rMd),
        child: Container(
          height: 46,
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppDims.s4,
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                SolarIconsOutline.addCircle,
                color: Colors.white,
                size: 18,
              ),
              const SizedBox(width: AppDims.s2),
              Text(
                tr.newCategory,
                style: AppTextStyles.bs200(context).copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Refresh button ────────────────────────────────────────────────────────────

class _RefreshButton extends StatefulWidget {
  final Future<void> Function() onRefresh;

  const _RefreshButton({required this.onRefresh});

  @override
  State<_RefreshButton> createState() => _RefreshButtonState();
}

class _RefreshButtonState extends State<_RefreshButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _spinCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  );
  bool _busy = false;

  @override
  void dispose() {
    _spinCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleTap() async {
    if (_busy) return;
    setState(() => _busy = true);
    _spinCtrl.repeat();
    try {
      await widget.onRefresh();
    } finally {
      if (mounted) {
        _spinCtrl
          ..stop()
          ..value = 0;
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppDims.rMd),
      child: InkWell(
        onTap: _handleTap,
        borderRadius: BorderRadius.circular(AppDims.rMd),
        child: Container(
          width: 46,
          height: 46,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppDims.rMd),
            color: colors.surfaceSoft.withValues(alpha: 0.65),
            border: Border.all(
              color: colors.border.withValues(alpha: 0.75),
            ),
          ),
          child: RotationTransition(
            turns: _spinCtrl,
            child: Icon(
              SolarIconsOutline.refresh,
              size: 19,
              color: colors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
