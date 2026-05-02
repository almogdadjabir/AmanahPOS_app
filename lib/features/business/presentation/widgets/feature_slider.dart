import 'dart:async';

import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';

class FeatureSlider extends StatefulWidget {
  const FeatureSlider({super.key});

  @override
  State<FeatureSlider> createState() => _FeatureSliderState();
}

class _FeatureSliderState extends State<FeatureSlider> {
  static const List<_FeatureAd> _features = [
    _FeatureAd(
      icon: Icons.bolt_rounded,
      title: 'Instant checkout flow',
      subtitle: 'Serve customers faster with a clean, focused sales experience.',
    ),
    _FeatureAd(
      icon: Icons.admin_panel_settings_rounded,
      title: 'Role-based staff control',
      subtitle: 'Give each team member the right access without confusion.',
    ),
    _FeatureAd(
      icon: Icons.query_stats_rounded,
      title: 'Real-time business pulse',
      subtitle: 'See what is selling, what is slowing down, and what needs action.',
    ),
    _FeatureAd(
      icon: Icons.inventory_rounded,
      title: 'Stock awareness',
      subtitle: 'Stay ahead of low stock and avoid selling unavailable products.',
    ),
    _FeatureAd(
      icon: Icons.storefront_rounded,
      title: 'Branch-ready workspace',
      subtitle: 'Start with one location and grow into multiple shops easily.',
    ),
    _FeatureAd(
      icon: Icons.receipt_rounded,
      title: 'Clean order tracking',
      subtitle: 'Keep every order visible, organized, and easy to follow.',
    ),
    _FeatureAd(
      icon: Icons.workspace_premium_rounded,
      title: 'Owner command center',
      subtitle: 'Create your business once and unlock your full POS workspace.',
    ),
  ];

  static const Duration _readDuration = Duration(milliseconds: 5000);
  static const Duration _slideDuration = Duration(milliseconds: 760);

  PageController? _pageController;
  Timer? _timer;

  late int _page;

  @override
  void initState() {
    super.initState();

    // Start from a large number so we can always animate forward smoothly.
    _page = _features.length * 1000;

    _pageController = PageController(
      initialPage: _page,
      keepPage: false,
    );

    _timer = Timer.periodic(_readDuration, (_) {
      final controller = _pageController;

      if (!mounted || controller == null || !controller.hasClients) return;

      _page++;

      controller.animateToPage(
        _page,
        duration: _slideDuration,
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _timer = null;

    _pageController?.dispose();
    _pageController = null;

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _pageController;

    if (controller == null) {
      return const SizedBox(height: 92);
    }

    return RepaintBoundary(
      child: SizedBox(
        height: 92,
        child: PageView.builder(
          controller: controller,
          physics: const NeverScrollableScrollPhysics(),
          allowImplicitScrolling: false,
          itemBuilder: (context, index) {
            final feature = _features[index % _features.length];

            return AnimatedBuilder(
              animation: controller,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppDims.s1),
                child: Row(
                  children: [
                    RepaintBoundary(
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: context.appColors.primary.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(AppDims.rMd),
                          border: Border.all(
                            color: context.appColors.primary.withValues(alpha: 0.12),
                          ),
                        ),
                        child: Icon(
                          feature.icon,
                          color: context.appColors.primary,
                          size: 25,
                        ),
                      ),
                    ),

                    const SizedBox(width: AppDims.s3),

                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            feature.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.bs600(context).copyWith(
                              color: context.appColors.textPrimary,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            feature.subtitle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.bs200(context).copyWith(
                              color: context.appColors.textSecondary,
                              height: 1.35,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              builder: (context, child) {
                double pageOffset = 0;

                if (controller.hasClients &&
                    controller.position.haveDimensions) {
                  pageOffset = (controller.page ?? _page.toDouble()) - index;
                }

                final distance = pageOffset.abs().clamp(0.0, 1.0);

                final opacity = (1.0 - (distance * 0.35)).clamp(0.65, 1.0);
                final scale = (1.0 - (distance * 0.025)).clamp(0.975, 1.0);

                return Opacity(
                  opacity: opacity,
                  child: Transform.scale(
                    scale: scale,
                    child: child,
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _FeatureAd {
  final IconData icon;
  final String title;
  final String subtitle;

  const _FeatureAd({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
}