import 'package:amana_pos/config/router/route_strings.dart';
import 'package:amana_pos/features/pos/presentation/bloc/pos_bloc.dart';
import 'package:amana_pos/features/products/presentation/bloc/product_bloc.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/utilities/global_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solar_icons/solar_icons.dart';

class PosSearchSection extends StatelessWidget {
  static const double _controlHeight = 48;

  final TextEditingController searchCtrl;

  const PosSearchSection({
    super.key,
    required this.searchCtrl,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppDims.s4,
        AppDims.s3,
        AppDims.s4,
        AppDims.s1,
      ),
      child: Row(
        children: [
          _ScannerButton(
            size: _controlHeight,
            onTap: () => _openScanner(context),
          ),

          const SizedBox(width: AppDims.s3),

          Expanded(
            child: SizedBox(
              height: _controlHeight,
              child: TextField(
                controller: searchCtrl,
                onChanged: (value) {
                  context.read<PosBloc>().add(PosSearchChanged(value));
                },
                textInputAction: TextInputAction.search,
                style: AppTextStyles.bs300(context).copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.1,
                ),
                cursorColor: colors.primary,
                decoration: InputDecoration(
                  hintText: 'Search · SKU · Barcode',
                  hintStyle: AppTextStyles.bs300(context).copyWith(
                    color: colors.textHint,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                  suffixIcon: Padding(
                    padding: const EdgeInsetsDirectional.only(end: 16),
                    child: Icon(
                      SolarIconsOutline.magnifier,
                      size: 24,
                      color: colors.textSecondary.withValues(alpha: 0.82),
                    ),
                  ),
                  suffixIconConstraints: const BoxConstraints(
                    minWidth: 48,
                    minHeight: 48,
                  ),
                  filled: true,
                  fillColor: colors.surfaceSoft.withValues(
                    alpha: isDark ? 0.78 : 0.92,
                  ),
                  contentPadding: const EdgeInsetsDirectional.fromSTEB(
                    20,
                    0,
                    12,
                    0,
                  ),
                  border: _border(
                    color: colors.border.withValues(alpha: 0.78),
                  ),
                  enabledBorder: _border(
                    color: colors.border.withValues(alpha: 0.78),
                  ),
                  focusedBorder: _border(
                    color: colors.primary.withValues(alpha: 0.72),
                    width: 1.35,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  OutlineInputBorder _border({
    required Color color,
    double width = 1.1,
  }) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppDims.rLg),
      borderSide: BorderSide(
        color: color,
        width: width,
      ),
    );
  }

  Future<void> _openScanner(BuildContext context) async {
    final barcode = await Navigator.of(context).pushNamed<String>(
      RouteStrings.barcodeScannerScreen,
    );

    if (!context.mounted) return;
    if (barcode == null || barcode.trim().isEmpty) return;

    final cleanBarcode = barcode.trim();
    final productState = context.read<ProductBloc>().state;

    final product = productState.products.where((item) {
      return item.barcode?.trim() == cleanBarcode;
    }).firstOrNull;

    if (product == null) {
      GlobalSnackBar.show(
        message: 'No product found for barcode: $cleanBarcode',
        isError: true,
      );
      return;
    }

    context.read<PosBloc>().add(
      PosAddProduct(product),
    );

    GlobalSnackBar.show(
      message: '${product.name ?? 'Product'} added to cart',
    );
  }
}

class _ScannerButton extends StatefulWidget {
  final VoidCallback onTap;
  final double size;

  const _ScannerButton({
    required this.size,
    required this.onTap,
  });

  @override
  State<_ScannerButton> createState() => _ScannerButtonState();
}

class _ScannerButtonState extends State<_ScannerButton> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => _setPressed(true),
      onTapCancel: () => _setPressed(false),
      onTapUp: (_) => _setPressed(false),
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 130),
        curve: Curves.easeOut,
        scale: _pressed ? 0.94 : 1,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppDims.rLg),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                colors.primary.withValues(alpha: 0.96),
                colors.primary.withValues(alpha: isDark ? 0.66 : 0.82),
              ],
            ),
            border: Border.all(
              color: Colors.white.withValues(alpha: isDark ? 0.16 : 0.24),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: colors.primary.withValues(alpha: isDark ? 0.28 : 0.18),
                blurRadius: 22,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Icon(
            SolarIconsOutline.qrCode,
            size: 26,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}