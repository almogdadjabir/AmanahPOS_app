import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';

class ProductsEmpty extends StatelessWidget {
  final String? query;
  const ProductsEmpty({super.key, this.query});

  @override
  Widget build(BuildContext context) {
    final hasQuery = query != null && query!.trim().isNotEmpty;
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56, height: 56,
            decoration: BoxDecoration(color: context.appColors.surfaceSoft, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Icon(Icons.search_off_rounded, color: context.appColors.textHint),
          ),
          const SizedBox(height: 12),
          Text(
            'No products found',
            style: TextStyle(
              fontFamily: 'NunitoSans', fontSize: 14, fontWeight: FontWeight.w700,
              color: context.appColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            hasQuery ? 'Nothing matches "${query!.trim()}"' : 'Try a different category',
            style: TextStyle(
              fontFamily: 'NunitoSans', fontSize: 12, fontWeight: FontWeight.w500,
              color: context.appColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
