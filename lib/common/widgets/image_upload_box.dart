import 'dart:io';

import 'package:amana_pos/common/services/image/app_image_picker.dart';
import 'package:amana_pos/common/widgets/permission_required_sheet.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';

class ImageUploadBox extends StatelessWidget {
  final PickedAppImage? pickedImage;
  final String? imageUrl;
  final String title;
  final String subtitle;
  final ValueChanged<PickedAppImage?> onChanged;

  const ImageUploadBox({
    super.key,
    required this.pickedImage,
    required this.imageUrl,
    required this.title,
    required this.subtitle,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final hasLocalImage = pickedImage != null;
    final hasRemoteImage = imageUrl?.trim().isNotEmpty == true;

    return Material(
      color: colors.surfaceSoft,
      borderRadius: BorderRadius.circular(AppDims.rLg),
      child: InkWell(
        onTap: () => _showPickerActions(context),
        borderRadius: BorderRadius.circular(AppDims.rLg),
        child: Container(
          height: 154,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppDims.rLg),
            border: Border.all(color: colors.border),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (hasLocalImage)
                Image.file(
                  File(pickedImage!.path),
                  fit: BoxFit.cover,
                )
              else if (hasRemoteImage)
                Image.network(
                  imageUrl!.trim(),
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _PlaceholderContent(
                    title: title,
                    subtitle: subtitle,
                  ),
                )
              else
                _PlaceholderContent(
                  title: title,
                  subtitle: subtitle,
                ),

              if (hasLocalImage || hasRemoteImage)
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.42),
                        ],
                      ),
                    ),
                  ),
                ),

              if (hasLocalImage || hasRemoteImage)
                Positioned(
                  left: AppDims.s3,
                  right: AppDims.s3,
                  bottom: AppDims.s3,
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          hasLocalImage ? 'New image selected' : 'Current image',
                          style: AppTextStyles.bs300(context).copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppDims.s2,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          'Change',
                          style: AppTextStyles.bs100(context).copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              if (hasLocalImage || hasRemoteImage)
                Positioned(
                  top: AppDims.s2,
                  right: AppDims.s2,
                  child: GestureDetector(
                    onTap: () => onChanged(null),
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.55),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        color: Colors.white,
                        size: 19,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPickerActions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return Container(
          padding: const EdgeInsets.fromLTRB(
            AppDims.s4,
            AppDims.s3,
            AppDims.s4,
            AppDims.s4,
          ),
          decoration: BoxDecoration(
            color: context.appColors.surface,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppDims.rXl),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: context.appColors.border,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: AppDims.s4),
              _ImageActionTile(
                icon: Icons.photo_library_outlined,
                title: 'Choose from gallery',
                onTap: () async {
                  Navigator.of(context).pop();

                  final result = await AppImagePicker.pickFromGallery();

                  if (!context.mounted) return;

                  if (result.isSuccess) {
                    onChanged(result.image);
                    return;
                  }

                  await _handlePickFailure(
                    context,
                    result.failureReason,
                    source: _ImageSourceType.gallery,
                  );
                },
              ),
              const SizedBox(height: AppDims.s2),
              _ImageActionTile(
                icon: Icons.photo_camera_outlined,
                title: 'Take photo',
                onTap: () async {
                  Navigator.of(context).pop();

                  final result = await AppImagePicker.pickFromCamera();

                  if (!context.mounted) return;

                  if (result.isSuccess) {
                    onChanged(result.image);
                    return;
                  }

                  await _handlePickFailure(
                    context,
                    result.failureReason,
                    source: _ImageSourceType.camera,
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PlaceholderContent extends StatelessWidget {
  final String title;
  final String subtitle;

  const _PlaceholderContent({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
      color: colors.surfaceSoft,
      padding: const EdgeInsets.all(AppDims.s4),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.add_photo_alternate_outlined,
              color: colors.primary,
              size: 28,
            ),
          ),
          const SizedBox(height: AppDims.s3),
          Text(
            title,
            style: AppTextStyles.bs400(context).copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: AppTextStyles.bs200(context).copyWith(
              color: colors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ImageActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _ImageActionTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Material(
      color: colors.surfaceSoft,
      borderRadius: BorderRadius.circular(AppDims.rMd),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDims.rMd),
        child: Padding(
          padding: const EdgeInsets.all(AppDims.s3),
          child: Row(
            children: [
              Icon(icon, color: colors.primary),
              const SizedBox(width: AppDims.s3),
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.bs400(context).copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: colors.textHint,
              ),
            ],
          ),
        ),
      ),
    );
  }


}

enum _ImageSourceType { gallery, camera }

Future<void> _handlePickFailure(
    BuildContext context,
    ImagePickFailureReason? reason, {
      required _ImageSourceType source,
    }) async {
  if (reason == null || reason == ImagePickFailureReason.cancelled) {
    return;
  }

  final isCamera = source == _ImageSourceType.camera;

  if (reason == ImagePickFailureReason.permissionDenied) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isCamera
              ? 'Camera permission is required to take a photo.'
              : 'Photo permission is required to choose an image.',
        ),
      ),
    );
    return;
  }

  if (reason == ImagePickFailureReason.permissionPermanentlyDenied ||
      reason == ImagePickFailureReason.permissionRestricted) {
    await showPermissionRequiredSheet(
      context,
      title: isCamera ? 'Camera Access Needed' : 'Photo Access Needed',
      message: isCamera
          ? 'Please enable camera access in Settings so you can take product and category photos.'
          : 'Please enable photo access in Settings so you can upload product and category images.',
    );
    return;
  }

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('Could not open image picker. Please try again.'),
    ),
  );
}