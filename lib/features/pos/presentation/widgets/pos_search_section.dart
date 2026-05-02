import 'package:amana_pos/features/pos/presentation/bloc/pos_bloc.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/utilities/global_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class PosSearchSection extends StatelessWidget {
  final TextEditingController searchCtrl;

  const PosSearchSection({super.key,
    required this.searchCtrl,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppDims.s4,
        AppDims.s3,
        AppDims.s4,
        AppDims.s1,
      ),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 46,
              child: TextField(
                controller: searchCtrl,
                onChanged: (value) {
                  context.read<PosBloc>().add(PosSearchChanged(value));
                },
                style: AppTextStyles.bs300(context).copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
                decoration: InputDecoration(
                  hintText: 'Search products, SKU, barcode...',
                  hintStyle: AppTextStyles.bs300(context).copyWith(
                    color: colors.textHint,
                    fontWeight: FontWeight.w600,
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    size: 20,
                    color: colors.textHint,
                  ),
                  filled: true,
                  fillColor: colors.surface,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppDims.s3,
                    vertical: 0,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppDims.rMd),
                    borderSide: BorderSide(color: colors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppDims.rMd),
                    borderSide: BorderSide(color: colors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppDims.rMd),
                    borderSide: BorderSide(
                      color: colors.primary,
                      width: 1.4,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: AppDims.s2),
          Material(
            color: colors.surface,
            borderRadius: BorderRadius.circular(AppDims.rMd),
            child: InkWell(
              onTap: () {
                GlobalSnackBar.show(
                  message: 'Barcode scanner coming soon',
                  isInfo: true,
                );
              },
              borderRadius: BorderRadius.circular(AppDims.rMd),
              child: Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppDims.rMd),
                  border: Border.all(color: colors.border),
                ),
                child: Icon(
                  Icons.qr_code_scanner_rounded,
                  size: 21,
                  color: colors.textPrimary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}