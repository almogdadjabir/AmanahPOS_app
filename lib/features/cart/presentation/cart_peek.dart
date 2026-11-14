import 'dart:ui' as ui;

import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/common/motion/motion_animate.dart';
import 'package:amana_pos/features/pos/presentation/bloc/pos_bloc.dart';
import 'package:amana_pos/features/pos/presentation/pos_screen.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/utilities/format.dart';
import 'package:amana_pos/widgets/app_amount.dart';
import 'package:amana_pos/widgets/app_button.dart';
import 'package:amana_pos/widgets/directional_icon.dart';
import 'package:amana_pos/widgets/pressable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:amana_pos/theme/phosphor_icons.dart';

/// Floating charge dock: glass capsule with item count, running total and
/// the button that opens the ticket.
class CartPeek extends StatelessWidget {
  const CartPeek({super.key, required this.state, required this.onTap});

  final PosState state;
  final VoidCallback onTap;

  static const double _radius = 20;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final text = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isLoading = state.submitStatus == PosSubmitStatus.loading;

    return Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(
            AppDims.s3,
            0,
            AppDims.s3,
            AppDims.s2,
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(_radius),
              boxShadow: isDark
                  ? null
                  : [
                      BoxShadow(
                        color: colors.shadow,
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(_radius),
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: colors.surface.withValues(alpha: 0.78),
                    borderRadius: BorderRadius.circular(_radius),
                    border: Border.all(color: colors.border),
                  ),
                  child: Padding(
                    padding: const EdgeInsetsDirectional.all(AppDims.s2),
                    child: Row(
                      children: [
                        Expanded(
                          child: Pressable(
                            onTap: isLoading ? null : onTap,
                            semanticLabel: context.tr.reviewCart,
                            child: Padding(
                              padding: const EdgeInsetsDirectional.symmetric(
                                horizontal: AppDims.s3 - 2,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    context.tr.itemCount(state.itemCount),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: text.bodySmall!.copyWith(
                                      color: colors.textHint,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Align(
                                    alignment: AlignmentDirectional.centerStart,
                                    child: AppAmount(
                                      value: money(state.total),
                                      unit: AppFormat.currency,
                                      textAlign: TextAlign.start,
                                      style: const TextStyle(
                                        fontSize: 21,
                                        fontWeight: FontWeight.w600,
                                        height: 1.1,
                                      ).copyWith(color: colors.textPrimary),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppDims.s2),
                        AppButton(
                          label: context.tr.posCharge,
                          isLoading: isLoading,
                          onPressed: isLoading ? null : onTap,
                          suffixIcon: const DirectionalIcon(
                            icon: PhosphorIconsRegular.caretRight,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        )
        .mAnimate()
        .fadeIn(duration: AppDims.medium, curve: AppDims.soft)
        .slideY(
          begin: 0.5,
          end: 0,
          duration: AppDims.slow,
          curve: AppDims.sheetCurve,
        );
  }
}
