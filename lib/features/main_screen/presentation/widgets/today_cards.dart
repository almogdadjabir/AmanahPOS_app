import 'dart:math' as math;

import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';

class OwnerTodayCard extends StatelessWidget {
  const OwnerTodayCard({
    super.key,
    required this.amount,
    required this.salesCount,
    required this.sparkline,
    this.dateLabel,
    this.liveLabel = 'LIVE',
    this.currencyLabel = 'SDG',
    this.onTap,
  });

  final double amount;
  final int salesCount;
  final List<double> sparkline;
  final String? dateLabel;
  final String liveLabel;
  final String currencyLabel;
  final VoidCallback? onTap;

  double get _avgSale => salesCount == 0 ? 0 : amount / salesCount;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final date = dateLabel ?? _formatEnglishDate(DateTime.now());

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDims.rXl),
        child: Ink(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(AppDims.rXl),
            border: Border.all(
              color: colors.primary.withValues(alpha: isDark ? 0.26 : 0.16),
              width: 1.1,
            ),
            gradient: RadialGradient(
              center: const Alignment(0.65, -0.95),
              radius: 1.35,
              colors: [
                colors.primary.withValues(alpha: isDark ? 0.22 : 0.09),
                colors.surface.withValues(alpha: 0),
              ],
              stops: const [0.0, 0.66],
            ),

          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppDims.rXl),
            child: Stack(
              children: [
                Positioned.fill(
                  child: ShaderMask(
                    shaderCallback: (rect) {
                      return RadialGradient(
                        center: const Alignment(0.45, -0.65),
                        radius: 0.95,
                        colors: [
                          colors.textPrimary,
                          Colors.transparent,
                        ],
                      ).createShader(rect);
                    },
                    blendMode: BlendMode.dstIn,
                    child: CustomPaint(
                      painter: _GridPainter(
                        color: colors.primary.withValues(
                          alpha: isDark ? 0.065 : 0.04,
                        ),
                        spacing: 24,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            date,
                            style: AppTextStyles.sm100(context).copyWith(
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.8,
                              color: colors.textHint,
                              height: 1,
                            ),
                          ),
                          const Spacer(),
                          _PulsingDot(
                            color: colors.primary,
                            size: 6,
                          ),
                          const SizedBox(width: 7),
                          Text(
                            liveLabel.toUpperCase(),
                            style: AppTextStyles.sm100(context).copyWith(
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.9,
                              color: colors.primary,
                              height: 1,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      RichText(
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: _formatAmountEnglish(amount),
                              style: AppTextStyles.bs900(context).copyWith(
                                fontSize: 44,
                                fontWeight: FontWeight.w900,
                                height: 1,
                                letterSpacing: -1.2,
                                color: colors.textPrimary,
                                shadows: [
                                  if (isDark)
                                    Shadow(
                                      color: colors.primary.withValues(
                                        alpha: 0.22,
                                      ),
                                      blurRadius: 30,
                                    ),
                                ],
                              ),
                            ),
                            TextSpan(
                              text: '  $currencyLabel',
                              style: AppTextStyles.sm300(context).copyWith(
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.6,
                                color: colors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      _SoftDivider(color: colors.border),
                      const SizedBox(height: 15),
                      Row(
                        children: [
                          _StatPair(
                            value: salesCount.toString(),
                            label: 'SALES',
                          ),
                          const SizedBox(width: 22),
                          _StatPair(
                            value: _formatAmountEnglish(_avgSale),
                            label: 'AVG',
                          ),
                          const Spacer(),
                          SizedBox(
                            width: 112,
                            height: 30,
                            child: CustomPaint(
                              painter: _SparklinePainter(
                                data: sparkline,
                                color: colors.primary,
                                showFill: true,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
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

class CashierShiftCard extends StatelessWidget {
  const CashierShiftCard({
    super.key,
    required this.cashierName,
    required this.shiftStart,
    required this.amount,
    required this.salesCount,
    required this.sparkline,
    this.currencyLabel = 'SDG',
    this.onTap,
  });

  final String cashierName;
  final DateTime shiftStart;
  final double amount;
  final int salesCount;
  final List<double> sparkline;
  final String currencyLabel;
  final VoidCallback? onTap;

  String get _shiftLength {
    final difference = DateTime.now().difference(shiftStart);
    final hours = difference.inHours;
    final minutes = difference.inMinutes.remainder(60);

    return '$hours:${minutes.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDims.rLg),
        child: Ink(
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 11,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppDims.rLg),
            border: Border.all(
              color: colors.secondary.withValues(
                alpha: isDark ? 0.32 : 0.24,
              ),
              width: 1,
            ),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                colors.secondary.withValues(alpha: isDark ? 0.13 : 0.08),
                colors.primary.withValues(alpha: isDark ? 0.07 : 0.04),
              ],
            ),
          ),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    RichText(
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: _formatAmountEnglish(amount),
                            style: AppTextStyles.bs500(context).copyWith(
                              fontWeight: FontWeight.w900,
                              height: 1.1,
                              color: colors.textPrimary,
                            ),
                          ),
                          TextSpan(
                            text: '  $currencyLabel',
                            style: AppTextStyles.sm100(context).copyWith(
                              color: colors.textHint,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '$cashierName · MY SHIFT · $_shiftLength',
                      style: AppTextStyles.sm100(context).copyWith(
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                        color: colors.secondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                width: 1,
                height: 30,
                margin: const EdgeInsets.symmetric(horizontal: 12),
                color: colors.border.withValues(alpha: 0.75),
              ),
              _StatPair(
                value: salesCount.toString(),
                label: 'SALES',
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 58,
                height: 24,
                child: CustomPaint(
                  painter: _SparklinePainter(
                    data: sparkline,
                    color: colors.secondary,
                    showFill: false,
                    strokeWidth: 1.6,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatPair extends StatelessWidget {
  const _StatPair({
    required this.value,
    required this.label,
  });

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: AppTextStyles.bs500(context).copyWith(
            fontWeight: FontWeight.w900,
            height: 1,
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          label,
          style: AppTextStyles.sm100(context).copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: 1.5,
            color: colors.textHint,
            height: 1,
          ),
        ),
      ],
    );
  }
}

class _SoftDivider extends StatelessWidget {
  final Color color;

  const _SoftDivider({
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Colors.transparent,
            color.withValues(alpha: 0.18),
            color.withValues(alpha: 0.62),
            color.withValues(alpha: 0.18),
            Colors.transparent,
          ],
          stops: const [
            0.0,
            0.18,
            0.5,
            0.82,
            1.0,
          ],
        ),
      ),
    );
  }
}

class _PulsingDot extends StatefulWidget {
  const _PulsingDot({
    required this.color,
    required this.size,
  });

  final Color color;
  final double size;

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _glow;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1450),
    )..repeat(reverse: true);

    _glow = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _glow,
      builder: (_, __) {
        final t = _glow.value;
        final opacity = 0.62 + (0.38 * t);
        final blur = 5.0 + (7.0 * t);

        return Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.color.withValues(alpha: opacity),
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: 0.35 + (0.30 * t)),
                blurRadius: blur,
                spreadRadius: 0.5,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SparklinePainter extends CustomPainter {
  _SparklinePainter({
    required this.data,
    required this.color,
    this.showFill = true,
    this.strokeWidth = 1.7,
  });

  final List<double> data;
  final Color color;
  final bool showFill;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    if (data.length < 2) return;

    final maxValue = data.reduce(math.max);
    final minValue = data.reduce(math.min);
    final range = (maxValue - minValue) == 0 ? 1.0 : (maxValue - minValue);

    final strokePath = Path();
    final fillPath = Path();

    for (int i = 0; i < data.length; i++) {
      final x = (i / (data.length - 1)) * size.width;
      final normalized = (data[i] - minValue) / range;
      final y = size.height - 2 - (normalized * (size.height - 4));

      if (i == 0) {
        strokePath.moveTo(x, y);
        fillPath
          ..moveTo(x, size.height)
          ..lineTo(x, y);
      } else {
        strokePath.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }

    if (showFill) {
      fillPath
        ..lineTo(size.width, size.height)
        ..close();

      final shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          color.withValues(alpha: 0.30),
          color.withValues(alpha: 0.00),
        ],
      ).createShader(Offset.zero & size);

      canvas.drawPath(fillPath, Paint()..shader = shader);
    }

    canvas.drawPath(
      strokePath,
      Paint()
        ..color = color
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_SparklinePainter oldDelegate) {
    return oldDelegate.data != data ||
        oldDelegate.color != color ||
        oldDelegate.showFill != showFill ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}

class _GridPainter extends CustomPainter {
  _GridPainter({
    required this.color,
    required this.spacing,
  });

  final Color color;
  final double spacing;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;

    for (double x = 0; x <= size.width; x += spacing) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
    }

    for (double y = 0; y <= size.height; y += spacing) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_GridPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.spacing != spacing;
  }
}

String _formatAmountEnglish(double value) {
  final whole = value.round().toString();

  return whole.replaceAllMapped(
    RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
        (match) => '${match[1]},',
  );
}

const _englishMonths = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

String _formatEnglishDate(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = _englishMonths[date.month - 1];
  final year = date.year.toString();

  return 'TODAY · $day $month $year';
}