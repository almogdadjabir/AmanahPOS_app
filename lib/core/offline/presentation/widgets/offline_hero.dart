import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';

class OfflineHero extends StatefulWidget {
  const OfflineHero({super.key});

  @override
  State<OfflineHero> createState() => _OfflineHeroState();
}

class _OfflineHeroState extends State<OfflineHero>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _float;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _float = Tween<double>(begin: -6, end: 6).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return AnimatedBuilder(
      animation: _float,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _float.value),
          child: child,
        );
      },
      child: Container(
        width: 132,
        height: 132,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colors.primary.withValues(alpha: 0.18),
              const Color(0xFF0D9488).withValues(alpha: 0.10),
              colors.surfaceSoft,
            ],
          ),
          border: Border.all(
            color: colors.primary.withValues(alpha: 0.20),
          ),
          boxShadow: [
            BoxShadow(
              color: colors.primary.withValues(alpha: 0.12),
              blurRadius: 32,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 82,
              height: 82,
              decoration: BoxDecoration(
                color: colors.surface,
                shape: BoxShape.circle,
                border: Border.all(color: colors.border),
              ),
            ),
            Icon(
              Icons.cloud_sync_rounded,
              size: 44,
              color: colors.primary,
            ),
            Positioned(
              right: 26,
              bottom: 28,
              child: Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: const Color(0xFF16A34A),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: colors.surface,
                    width: 3,
                  ),
                ),
                child: const Icon(
                  Icons.offline_bolt_rounded,
                  size: 16,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}