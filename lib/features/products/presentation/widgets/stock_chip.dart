import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:flutter/material.dart';

class StockChip extends StatelessWidget {
  final double level;
  const StockChip({super.key, required this.level});

  @override
  Widget build(BuildContext context) {
    final low = level == 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: low
            ? const Color(0xFFDC2626).withValues(alpha: 0.10)
            : const Color(0xFF22C55E).withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        low ? 'Out of stock' : 'Stock: $level',
        style: AppTextStyles.bs100(context).copyWith(
        fontWeight: FontWeight.w700,
          color: low
              ? const Color(0xFFDC2626)
              : const Color(0xFF16A34A),
        ),
      ),
    );
  }
}