import 'package:amana_pos/common/app_progress/app_progress_cubit.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/utilities/dependencies_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The thin line beneath the main app bar.
///
/// • Idle  → the faint decorative gradient line (transparent → border →
///   primary → border → transparent).
/// • Active → the exact same line, but its primary glow gently sweeps across.
///   When loading finishes it rests back to the static idle look.
///
/// Drive it globally via [AppProgressCubit], or locally by passing [isLoading]
/// / [value].
class AppProgressLine extends StatelessWidget {
  const AppProgressLine({
    super.key,
    this.isLoading,
    this.value,
    this.height = 1.0,
  });

  final bool? isLoading;
  final double? value;
  final double height;

  @override
  Widget build(BuildContext context) {
    if (isLoading != null || value != null) {
      return _ProgressLineView(
        active: isLoading ?? (value != null),
        height: height,
      );
    }

    return BlocBuilder<AppProgressCubit, AppProgressState>(
      bloc: getIt<AppProgressCubit>(),
      builder: (context, state) => _ProgressLineView(
        active: state.isActive,
        height: height,
      ),
    );
  }
}

class _ProgressLineView extends StatelessWidget {
  const _ProgressLineView({required this.active, required this.height});

  final bool active;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: active
            ? _GradientLine(key: const ValueKey('active'), animate: true)
            : _GradientLine(key: const ValueKey('idle'), animate: false),
      ),
    );
  }
}

/// The decorative gradient line. When [animate] is true its glow sweeps across
/// on a loop; otherwise it sits still (the default look).
class _GradientLine extends StatefulWidget {
  const _GradientLine({super.key, required this.animate});

  final bool animate;

  @override
  State<_GradientLine> createState() => _GradientLineState();
}

class _GradientLineState extends State<_GradientLine>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    if (widget.animate) _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    // The exact idle look — one primary accent, no glow, no second colour.
    final stops = const [0.0, 0.22, 0.5, 0.78, 1.0];
    final gradientColors = [
      Colors.transparent,
      colors.border.withValues(alpha: 0.16),
      colors.primary.withValues(alpha: 0.30),
      colors.border.withValues(alpha: 0.16),
      Colors.transparent,
    ];

    if (!widget.animate) {
      return Center(
        child: Container(
          height: 1,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: gradientColors, stops: stops),
          ),
        ),
      );
    }

    return Center(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (_, __) {
          return Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: gradientColors,
                stops: stops,
                tileMode: TileMode.repeated,
                transform: _SweepTransform(_controller.value),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Slides the gradient horizontally so the accent sweeps and loops seamlessly.
class _SweepTransform extends GradientTransform {
  const _SweepTransform(this.fraction);

  final double fraction;

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(-bounds.width * fraction, 0, 0);
  }
}