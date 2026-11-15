import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:flutter/material.dart';

/// Ported from Baraka: a thin 96 x 3 track with a short segment that sweeps
/// back and forth, so people can see the app is working. Holds still when the
/// system asks to reduce motion.
class SplashProgress extends StatefulWidget {
  const SplashProgress({required this.color, super.key});

  final Color color;

  static const trackWidth = 96.0;
  static const trackHeight = 3.0;
  static const segmentWidth = 32.0;
  static const period = Duration(milliseconds: 1400);

  @override
  State<SplashProgress> createState() => _SplashProgressState();
}

class _SplashProgressState extends State<SplashProgress>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: SplashProgress.period,
  );

  bool _animating = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final shouldAnimate =
        !(MediaQuery.maybeDisableAnimationsOf(context) ?? false);
    if (shouldAnimate == _animating) return;
    _animating = shouldAnimate;
    if (shouldAnimate) {
      _controller.repeat();
    } else {
      _controller
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final track = widget.color.withValues(alpha: 0.24);
    final segment = widget.color.withValues(alpha: 0.90);
    final radius = BorderRadius.circular(SplashProgress.trackHeight);

    return Semantics(
      label: context.tr.commonLoading,
      liveRegion: true,
      child: SizedBox(
        width: SplashProgress.trackWidth,
        height: SplashProgress.trackHeight,
        child: DecoratedBox(
          decoration: BoxDecoration(color: track, borderRadius: radius),
          child: ClipRRect(
            borderRadius: radius,
            child: _animating
                ? AnimatedBuilder(
                    animation: _controller,
                    builder: (context, _) => Align(
                      alignment: Alignment(_offset(_controller.value), 0),
                      child: _Segment(color: segment),
                    ),
                  )
                : Align(child: _Segment(color: segment)),
          ),
        ),
      ),
    );
  }

  double _offset(double t) {
    final sweep = t < 0.5 ? t * 2 : (1 - t) * 2;
    return Curves.easeInOut.transform(sweep) * 2 - 1;
  }
}

class _Segment extends StatelessWidget {
  const _Segment({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: SplashProgress.segmentWidth,
      height: SplashProgress.trackHeight,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(SplashProgress.trackHeight),
      ),
    );
  }
}
