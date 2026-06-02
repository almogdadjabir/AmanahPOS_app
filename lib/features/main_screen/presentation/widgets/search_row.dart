import 'package:amana_pos/common/widgets/app_search_field.dart';
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
            child: AppSearchField(
              controller: controller,
              onChanged: onChanged,
              hint: 'Search products or SKU…',
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
