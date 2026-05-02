import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';

/// Search input + barcode-scanner button.
class SearchRow extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback? onScanTap;

  const SearchRow({
    super.key,
    required this.controller,
    required this.onChanged,
    this.onScanTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppDims.s3, AppDims.s3, AppDims.s3, 0),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: AppDims.s3),
              decoration: BoxDecoration(
                color: context.appColors.surface,
                borderRadius: BorderRadius.circular(AppDims.rMd),
                border: Border.all(color: context.appColors.border),
              ),
              child: Row(
                children: [
                  Icon(Icons.search_rounded, size: 18, color: context.appColors.textHint),
                  const SizedBox(width: AppDims.s2),
                  Expanded(
                    child: TextField(
                      controller: controller,
                      onChanged: onChanged,
                      style: TextStyle(
                        fontFamily: 'NunitoSans', fontSize: 13, fontWeight: FontWeight.w500,
                        color: context.appColors.textPrimary,
                      ),
                      decoration: InputDecoration(
                        isDense: true,
                        border: InputBorder.none,
                        hintText: 'Search products or SKU…',
                        hintStyle: TextStyle(
                          fontFamily: 'NunitoSans', fontSize: 13, fontWeight: FontWeight.w500,
                          color: context.appColors.textHint,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: AppDims.s2),
          Material(
            color: context.appColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDims.rMd),
              side: BorderSide(color: context.appColors.border),
            ),
            child: InkWell(
              onTap: onScanTap,
              borderRadius: BorderRadius.circular(AppDims.rMd),
              child: SizedBox(
                width: 44, height: 44,
                child: Icon(Icons.qr_code_scanner_rounded, size: 20, color: context.appColors.textPrimary),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
