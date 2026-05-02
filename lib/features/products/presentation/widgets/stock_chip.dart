import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:flutter/material.dart';

class StockChip extends StatelessWidget {
  final double level;

  const StockChip({
    super.key,
    required this.level,
  });

  @override
  Widget build(BuildContext context) {
    final stock = level;

    final bool out = stock <= 0;
    final bool low = stock > 0 && stock <= 5;

    final Color color = out
        ? const Color(0xFFDC2626)
        : low
        ? const Color(0xFFEA580C)
        : const Color(0xFF16A34A);

    final String label = out
        ? 'Out'
        : low
        ? 'Low: ${_format(stock)}'
        : 'Stock: ${_format(stock)}';

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 7,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTextStyles.bs100(context).copyWith(
          fontWeight: FontWeight.w900,
          color: color,
        ),
      ),
    );
  }

  String _format(double value) {
    if (value % 1 == 0) return value.toInt().toString();
    return value.toStringAsFixed(1);
  }
}