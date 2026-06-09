import 'package:amana_pos/theme/app_colors.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/widgets/amana_logo.dart';
import 'package:amana_pos/widgets/grid_painter.dart';
import 'package:flutter/material.dart';
import 'package:solar_icons/solar_icons.dart';

class DesktopLoginBrandPanel extends StatelessWidget {
  const DesktopLoginBrandPanel({super.key});

  static const Color _gradientTop = AppColors.primary;
  static const Color _gradientBottom = Color(0xFF0a4f49);
  static const Color _gold = Color(0xFFE8C170);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.sizeOf(context).height,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_gradientTop, _gradientBottom],
          stops: [0.0, 1.0],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Fine grid texture — adds material depth instead of a flat fill.
          Positioned.fill(
            child: CustomPaint(
              painter: GridPainter(
                color: Colors.white.withValues(alpha: 0.025),
                spacing: 28,
              ),
            ),
          ),

          // Warm ember glow, lower-left — the panel's one accent gesture.
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(-0.85, 1.0),
                  radius: 1.05,
                  colors: [
                    _gold.withValues(alpha: 0.16),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0.9, -0.9),
                  radius: 0.8,
                  colors: [
                    Colors.white.withValues(alpha: 0.05),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          Align(
            alignment: Alignment.center,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDims.s8,
                vertical: AppDims.s8,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Logo mark + wordmark
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const AmanaPosLogoMark(size: 40, isInAppBar: true),
                      const SizedBox(width: AppDims.s3),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'AmanaPOS',
                            style: AppTextStyles.bs200(context).copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              height: 1,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'POINT OF SALE PLATFORM',
                            style: AppTextStyles.sm100(context).copyWith(
                              color: Colors.white.withValues(alpha: 0.45),
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.6,
                              height: 1,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 56),

                  // Eyebrow — small tracked-out label with a gold rule.
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 22,
                        height: 1.5,
                        color: _gold.withValues(alpha: 0.65),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'BUILT FOR INDEPENDENT RETAIL',
                        style: AppTextStyles.sm100(context).copyWith(
                          color: _gold.withValues(alpha: 0.85),
                          fontWeight: FontWeight.w700,
                          letterSpacing: 2.0,
                          height: 1,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: AppDims.s4),

                  // Headline — restrained weight and size read as considered,
                  // not shouted. Editorial line breaks over a single accent tone.
                  Text(
                    'A calmer way to\nrun the counter.',
                    style: AppTextStyles.bs700(context).copyWith(
                      color: Colors.white.withValues(alpha: 0.96),
                      fontWeight: FontWeight.w600,
                      height: 1.22,
                      letterSpacing: -0.4,
                    ),
                  ),

                  const SizedBox(height: AppDims.s4),

                  // Subline
                  SizedBox(
                    width: 340,
                    child: Text(
                      'Real-time inventory, multi-branch oversight, '
                      'and instant receipts — all in one quiet, dependable system.',
                      style: AppTextStyles.sm300(context).copyWith(
                        color: Colors.white.withValues(alpha: 0.58),
                        height: 1.65,
                      ),
                    ),
                  ),

                  const SizedBox(height: AppDims.s8),

                  // Feature badges — real iconography, not emoji glyphs.
                  const Wrap(
                    spacing: AppDims.s2,
                    runSpacing: AppDims.s2,
                    children: [
                      _Badge(icon: SolarIconsOutline.lightning, label: 'Offline-ready'),
                      _Badge(icon: SolarIconsOutline.global, label: 'Multi-branch'),
                      _Badge(icon: SolarIconsOutline.shieldKeyhole, label: 'Secure by design'),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.icon, required this.label});

  final IconData icon;
  final String label;

  static const Color _gold = DesktopLoginBrandPanel._gold;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.12),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 8, 14, 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: _gold.withValues(alpha: 0.9)),
            const SizedBox(width: 8),
            Text(
              label,
              style: AppTextStyles.sm100(context).copyWith(
                color: Colors.white.withValues(alpha: 0.78),
                fontWeight: FontWeight.w600,
                height: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
