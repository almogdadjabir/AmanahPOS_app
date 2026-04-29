import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';

class AnimatedMenuIcon extends StatefulWidget {
  final bool isOpen;
  final Color? color;
  final Color? openColor;

  const AnimatedMenuIcon({
    super.key,
    required this.isOpen,
    this.color,
    this.openColor,
  });

  @override
  State<AnimatedMenuIcon> createState() => _AnimatedMenuIconState();
}

class _AnimatedMenuIconState extends State<AnimatedMenuIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  late final Animation<double> _topRotate;
  late final Animation<double> _topTranslate;
  late final Animation<double> _midFade;
  late final Animation<double> _midScale;
  late final Animation<double> _botRotate;
  late final Animation<double> _botTranslate;
  late final Animation<Color?> _topColor;
  late final Animation<Color?> _botColor;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _buildAnimations();
    if (widget.isOpen) _ctrl.value = 1.0;
  }

  void _buildAnimations() {
    final curve = CurvedAnimation(
      parent: _ctrl,
      curve: Curves.easeInOutCubic,
    );
    final delayed = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.1, 1.0, curve: Curves.easeInOutCubic),
    );

    _topRotate = Tween<double>(begin: 0, end: 0.785398).animate(delayed);
    _topTranslate = Tween<double>(begin: 0, end: 7).animate(curve);
    _midFade = Tween<double>(begin: 1, end: 0).animate(
        CurvedAnimation(parent: _ctrl,
            curve: const Interval(0.0, 0.4, curve: Curves.easeIn)));
    _midScale = Tween<double>(begin: 1, end: 0).animate(
        CurvedAnimation(parent: _ctrl,
            curve: const Interval(0.0, 0.4, curve: Curves.easeIn)));
    _botRotate = Tween<double>(begin: 0, end: -0.785398).animate(delayed);
    _botTranslate = Tween<double>(begin: 0, end: -7).animate(curve);
  }

  @override
  void didUpdateWidget(AnimatedMenuIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isOpen != oldWidget.isOpen) {
      widget.isOpen ? _ctrl.forward() : _ctrl.reverse();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final baseColor = widget.color ?? context.appColors.textPrimary;
    final activeColor = widget.openColor ?? const Color(0xFF0D9488);

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        final barColor = Color.lerp(baseColor, activeColor, _ctrl.value)!;

        return SizedBox(
          width: 22, height: 16,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                top: 0, left: 0, right: 0,
                child: Transform.translate(
                  offset: Offset(0, _topTranslate.value),
                  child: Transform.rotate(
                    angle: _topRotate.value,
                    child: _Bar(color: barColor),
                  ),
                ),
              ),

              Positioned(
                top: 7, left: 0, right: 0,
                child: Opacity(
                  opacity: _midFade.value,
                  child: Transform.scale(
                    scaleX: _midScale.value,
                    child: _Bar(color: barColor),
                  ),
                ),
              ),

              Positioned(
                bottom: 0, left: 0, right: 0,
                child: Transform.translate(
                  offset: Offset(0, _botTranslate.value),
                  child: Transform.rotate(
                    angle: _botRotate.value,
                    child: _Bar(color: barColor),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Bar extends StatelessWidget {
  final Color color;
  const _Bar({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 2,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}