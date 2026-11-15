import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/widgets/shimmer.dart';
import 'package:flutter/material.dart';

/// Skeleton in the final layout of the notification list.
class NotificationSkeleton extends StatelessWidget {
  final int rows;
  const NotificationSkeleton({super.key, this.rows = 5});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return AppSkeleton(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: AppDims.borderLg,
          border: Border.all(color: colors.border),
        ),
        child: Column(
          children: [
            for (var i = 0; i < rows; i++) ...[
              if (i > 0)
                Divider(
                  height: 0.5,
                  thickness: 0.5,
                  indent: AppDims.s4 + 40 + AppDims.s3,
                  color: colors.border,
                ),
              const Padding(
                padding: EdgeInsetsDirectional.fromSTEB(
                  AppDims.s4,
                  12,
                  AppDims.s4,
                  13,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Shimmer(width: 40, height: 40, radius: 11),
                    SizedBox(width: AppDims.s3),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Shimmer(width: 140, height: 14, radius: 6),
                          SizedBox(height: 9),
                          Shimmer(width: 240, height: 11, radius: 6),
                          SizedBox(height: 6),
                          Shimmer(width: 180, height: 11, radius: 6),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
