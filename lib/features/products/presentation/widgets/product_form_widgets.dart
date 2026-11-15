import 'dart:io';

import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/common/services/image/app_image_picker.dart';
import 'package:amana_pos/core/offline/presentation/widgets/offline_cached_image.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/theme/phosphor_icons.dart';
import 'package:amana_pos/widgets/pressable.dart';
import 'package:flutter/material.dart';

/// Top bar of a full-screen form: Cancel at the start, centred title, Save at
/// the end. Save is dim while [onSave] is null and shows a spinner while
/// [saving].
class FormNavBar extends StatelessWidget {
  final String title;
  final VoidCallback onCancel;
  final VoidCallback? onSave;
  final bool saving;

  const FormNavBar({
    super.key,
    required this.title,
    required this.onCancel,
    required this.onSave,
    this.saving = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final tr = context.tr;

    return SizedBox(
      height: 44,
      child: Row(
        children: [
          Pressable(
            onTap: onCancel,
            scale: 1,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: SizedBox(
                height: 44,
                child: Center(
                  child: Text(
                    tr.cancel,
                    style: TextStyle(fontSize: 17, color: colors.primary),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: colors.textPrimary,
              ),
            ),
          ),
          Pressable(
            onTap: saving ? null : onSave,
            scale: 1,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: SizedBox(
                height: 44,
                child: Center(
                  child: saving
                      ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: colors.primary,
                          ),
                        )
                      : Text(
                          tr.save,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: onSave == null
                                ? colors.disabled
                                : colors.primary,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Centred 104pt photo tile: dashed with a camera while empty, the image once
/// chosen. Tapping opens the gallery / camera chooser.
class FormPhotoTile extends StatelessWidget {
  final PickedAppImage? picked;
  final String? imageUrl;
  final VoidCallback onTap;

  const FormPhotoTile({
    super.key,
    required this.picked,
    required this.imageUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final tr = context.tr;
    final hasUrl = imageUrl?.trim().isNotEmpty == true;
    final hasImage = picked != null || hasUrl;

    return Center(
      child: Pressable(
        onTap: onTap,
        child: SizedBox(
          width: 104,
          height: 104,
          child: hasImage
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(26),
                  child: picked != null
                      ? Image.file(File(picked!.path), fit: BoxFit.cover)
                      : OfflineCachedImage(
                          imageUrl: imageUrl,
                          fit: BoxFit.cover,
                        ),
                )
              : CustomPaint(
                  painter: _DashedRRectPainter(
                    color: colors.borderStrong,
                    radius: 26,
                    fill: colors.surface,
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          PhosphorIconsRegular.camera,
                          size: 30,
                          color: colors.primary,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          tr.pfAddPhoto,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: colors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}

class _DashedRRectPainter extends CustomPainter {
  final Color color;
  final Color fill;
  final double radius;

  const _DashedRRectPainter({
    required this.color,
    required this.fill,
    required this.radius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );
    canvas.drawRRect(rrect, Paint()..color = fill);

    final path = Path()..addRRect(rrect.deflate(0.75));
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        canvas.drawPath(metric.extractPath(distance, distance + 6), paint);
        distance += 10;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedRRectPainter old) =>
      old.color != color || old.fill != fill || old.radius != radius;
}

/// "More details" / "Fewer details" row with a caret that flips.
class FormDisclosureRow extends StatelessWidget {
  final bool expanded;
  final VoidCallback onTap;

  const FormDisclosureRow({
    super.key,
    required this.expanded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final tr = context.tr;

    return Pressable(
      onTap: onTap,
      haptic: true,
      scale: 1,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 52),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppDims.s4),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  expanded ? tr.pfFewerDetails : tr.pfMoreDetails,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w500,
                    color: colors.primary,
                  ),
                ),
              ),
              RotatedBox(
                quarterTurns: expanded ? 2 : 0,
                child: Icon(
                  PhosphorIconsRegular.caretDown,
                  size: 18,
                  color: colors.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
