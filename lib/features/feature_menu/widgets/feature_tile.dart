import 'package:amana_pos/features/main_screen/data/section.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';

class FeatureTile extends StatelessWidget {
  final SectionItem item;
  final VoidCallback onTap;
  const FeatureTile({super.key, required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final active = item.active;
    return Material(
      color: active
          ? context.appColors.primaryContainer
          : context.appColors.surfaceSoft,
      borderRadius: BorderRadius.circular(AppDims.rMd),
      child: InkWell(
        onTap: () {
          item.onTap?.call();
          onTap();
        },
        borderRadius: BorderRadius.circular(AppDims.rMd),
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppDims.s3, vertical: AppDims.s2),
          child: Row(
            children: [
              _TileIcon(item: item),
              const SizedBox(width: AppDims.s2),
              Expanded(child: _TileLabel(item: item, active: active)),
            ],
          ),
        ),
      ),
    );
  }
}

class _TileIcon extends StatelessWidget {
  final SectionItem item;
  const _TileIcon({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44, height: 44,
      decoration: BoxDecoration(
        color: item.color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(AppDims.rSm),
      ),
      child: Icon(item.icon, size: 22, color: item.color),
    );
  }
}

class _TileLabel extends StatelessWidget {
  final SectionItem item;
  final bool active;
  const _TileLabel({required this.item, required this.active});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(
                item.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'NunitoSans', fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: active
                      ? context.appColors.primary
                      : context.appColors.textPrimary,
                ),
              ),
            ),
            if (active) ...[
              const SizedBox(width: 5),
              _NowBadge(),
            ],
          ],
        ),
        const SizedBox(height: 1),
        Text(
          item.desc,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontFamily: 'NunitoSans', fontSize: 10.5,
            fontWeight: FontWeight.w600,
            color: context.appColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _NowBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: context.appColors.primary,
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Text(
        'NOW',
        style: TextStyle(
          fontFamily: 'NunitoSans', fontSize: 8.5,
          fontWeight: FontWeight.w800,
          color: Colors.white, letterSpacing: 0.4,
        ),
      ),
    );
  }
}