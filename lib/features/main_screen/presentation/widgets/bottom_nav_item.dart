import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';

class BottomNavItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback? onTap;
  final bool showPremiumIndicator;

  const BottomNavItem({
    super.key,
    required this.icon,
    required this.label,
    required this.isActive,
    this.onTap,
    this.showPremiumIndicator = false,
  });

  @override
  State<BottomNavItem> createState() => _BottomNavItemState();
}

class _BottomNavItemState extends State<BottomNavItem> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final activeColor = colors.primary;
    final inactiveColor = colors.textSecondary.withValues(alpha: 0.74);
    final itemColor = widget.isActive ? activeColor : inactiveColor;

    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => _setPressed(true),
      onTapCancel: () => _setPressed(false),
      onTapUp: (_) => _setPressed(false),
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        scale: _pressed ? 0.94 : 1,
        child: Center(
          child: SizedBox(
            height: 64,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      transitionBuilder: (child, animation) {
                        return FadeTransition(
                          opacity: animation,
                          child: ScaleTransition(
                            scale: Tween<double>(begin: 0.88, end: 1).animate(animation),
                            child: child,
                          ),
                        );
                      },
                      child: Icon(
                        widget.icon,
                        key: ValueKey(widget.icon),
                        size: widget.isActive ? 27 : 25,
                        color: itemColor,
                      ),
                    ),
                    if (widget.showPremiumIndicator)
                      Positioned(
                        top: -3,
                        right: -5,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFFFBBF24),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  style: AppTextStyles.sm200(context).copyWith(
                    color: itemColor,
                    fontWeight: widget.isActive ? FontWeight.w900 : FontWeight.w700,
                    height: 1,
                    letterSpacing: widget.isActive ? -0.15 : 0,
                  ),
                  child: Text(
                    widget.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
