import 'package:amana_pos/common/motion/motion.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';

/// One skeleton block. Static fill; wrap a group of blocks in
/// [AppSkeleton] to give the whole group a single soft pulse.
class Shimmer extends StatelessWidget {
  final double width;
  final double height;
  final double radius;

  const Shimmer({
    super.key,
    required this.width,
    required this.height,
    required this.radius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: context.appColors.surfaceSoft,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

/// Loading placeholder wrapper: one controller pulses the whole subtree
/// while loading; static when animations are off.
class AppSkeleton extends StatefulWidget {
  final Widget child;

  const AppSkeleton({super.key, required this.child});

  @override
  State<AppSkeleton> createState() => _AppSkeletonState();
}

class _AppSkeletonState extends State<AppSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );

  @override
  void initState() {
    super.initState();
    if (Motion.on) _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      excludeSemantics: true,
      child: FadeTransition(
        opacity: Tween<double>(begin: 0.55, end: 1).animate(
          CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
        ),
        child: widget.child,
      ),
    );
  }
}
