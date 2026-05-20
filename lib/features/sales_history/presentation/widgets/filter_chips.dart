import 'package:amana_pos/features/sales_history/utility/sale_utility.dart';
import 'package:amana_pos/theme/app_colors.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:solar_icons/solar_icons.dart';

class FilterChips extends StatelessWidget {
  final SaleFilter active;
  final ValueChanged<SaleFilter> onSelect;

  final Map<SaleFilter, int>? counts;

  const FilterChips({
    super.key,
    required this.active,
    required this.onSelect,
    this.counts,
  });

  static IconData _iconFor(SaleFilter f) => switch (f) {
    SaleFilter.all => SolarIconsOutline.widget,
    SaleFilter.today => SolarIconsOutline.calendarDate,
    SaleFilter.completed => SolarIconsOutline.checkCircle,
    SaleFilter.refunded  => SolarIconsOutline.undoLeft,
    SaleFilter.pending => SolarIconsOutline.clockCircle,
    _ => SolarIconsOutline.tuning,
  };

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 46,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(
          left: AppDims.s4,
          right: AppDims.s4,
          bottom: AppDims.s2,
        ),
        itemCount: SaleFilter.values.length,
        itemBuilder: (_, i) {
          final f = SaleFilter.values[i];
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: _Chip(
              label: f.label,
              icon: _iconFor(f),
              active: active == f,
              count: counts?[f],
              onTap: () => onSelect(f),
            ),
          );
        },
      ),
    );
  }
}


class _Chip extends StatefulWidget {
  final String label;
  final IconData icon;
  final bool active;
  final int? count;
  final VoidCallback onTap;

  const _Chip({
    required this.label,
    required this.icon,
    required this.active,
    required this.onTap,
    this.count,
  });

  @override
  State<_Chip> createState() => _ChipState();
}

class _ChipState extends State<_Chip> {
  bool _pressed = false;

  void _down(TapDownDetails _)  => setState(() => _pressed = true);
  void _cancel() => setState(() => _pressed = false);
  void _up(TapUpDetails _) {
    HapticFeedback.selectionClick();
    setState(() => _pressed = false);
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final colors   = context.appColors;
    final isActive = widget.active;

    return GestureDetector(
      onTapDown: _down,
      onTapUp: _up,
      onTapCancel: _cancel,
      child: AnimatedScale(
        scale: _pressed ? 0.92 : 1.0,
        duration: const Duration(milliseconds: 80),
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration:  const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          padding: EdgeInsets.symmetric(
            horizontal: isActive ? 14 : 12,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: isActive ? AppColors.primary : colors.surfaceSoft,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isActive ? AppColors.primary : colors.border,
              width: isActive ? 1.5 : 1.0,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.icon,
                size:  13,
                color: isActive ? Colors.white : colors.textHint,
              ),
              const SizedBox(width: 5),

              Text(
                widget.label,
                style: AppTextStyles.sm100(context).copyWith(
                  color: isActive ? Colors.white : colors.textSecondary,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
                  fontSize: 12,
                ),
              ),

              if (widget.count != null && widget.count! > 0) ...[
                const SizedBox(width: 5),
                _Badge(count: widget.count!, active: isActive),
              ],
            ],
          ),
        ),
      ),
    );
  }
}


class _Badge extends StatelessWidget {
  final int  count;
  final bool active;

  const _Badge({required this.count, required this.active});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: active
            ? Colors.white.withValues(alpha: 0.25)
            : AppColors.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        count > 99 ? '99+' : '$count',
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: active ? Colors.white : AppColors.primary,
        ),
      ),
    );
  }
}