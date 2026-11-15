import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/config/router/route_strings.dart';
import 'package:amana_pos/features/pos/presentation/bloc/pos_bloc.dart';
import 'package:amana_pos/features/products/presentation/bloc/product_bloc.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/utilities/global_snackbar.dart';
import 'package:amana_pos/common/motion/motion.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:amana_pos/theme/phosphor_icons.dart';

class PosSearchSection extends StatelessWidget {
  static const double _controlHeight = 40;

  final TextEditingController searchCtrl;

  const PosSearchSection({super.key, required this.searchCtrl});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final text = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppDims.s4,
        0,
        AppDims.s4,
        AppDims.s3,
      ),
      child: SizedBox(
        height: _controlHeight,
        child: TextField(
          controller: searchCtrl,
          onChanged: (value) {
            context.read<PosBloc>().add(PosSearchChanged(value));
          },
          textInputAction: TextInputAction.search,
          style: text.bodyLarge!.copyWith(color: colors.textPrimary),
          cursorColor: colors.primary,
          decoration: InputDecoration(
            hintText: context.tr.posSearchHint,
            hintStyle: text.bodyLarge!.copyWith(color: colors.textHint),
            prefixIcon: Icon(
              PhosphorIconsRegular.magnifyingGlass,
              size: 20,
              color: colors.textHint,
            ),
            prefixIconConstraints: const BoxConstraints(
              minWidth: 40,
              minHeight: _controlHeight,
            ),
            suffixIcon: ValueListenableBuilder<TextEditingValue>(
              valueListenable: searchCtrl,
              builder: (context, value, _) {
                final hasText = value.text.isNotEmpty;
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: hasText
                      ? () {
                          searchCtrl.clear();
                          context.read<PosBloc>().add(
                            const PosSearchChanged(''),
                          );
                        }
                      : () => _openScanner(context),
                  child: Center(
                    child: AnimatedSwitcher(
                      duration: Motion.duration(AppDims.fast),
                      child: hasText
                          ? Icon(
                              PhosphorIconsFill.xCircle,
                              key: const ValueKey('clear'),
                              size: 18,
                              color: colors.textHint,
                            )
                          : Icon(
                              PhosphorIconsRegular.scan,
                              key: const ValueKey('scan'),
                              size: 22,
                              color: colors.textSecondary,
                            ),
                    ),
                  ),
                );
              },
            ),
            suffixIconConstraints: const BoxConstraints.tightFor(
              width: 44,
              height: _controlHeight,
            ),
            filled: true,
            fillColor: colors.surfaceSoft,
            contentPadding: EdgeInsets.zero,
            border: _border(),
            enabledBorder: _border(),
            focusedBorder: _border(),
          ),
        ),
      ),
    );
  }

  OutlineInputBorder _border() {
    return OutlineInputBorder(
      borderRadius: AppDims.borderMd,
      borderSide: BorderSide.none,
    );
  }

  Future<void> _openScanner(BuildContext context) async {
    final barcode = await Navigator.of(
      context,
    ).pushNamed<String>(RouteStrings.barcodeScannerScreen);

    if (!context.mounted) return;
    if (barcode == null || barcode.trim().isEmpty) return;

    final cleanBarcode = barcode.trim();
    final productState = context.read<ProductBloc>().state;

    final product = productState.products.where((item) {
      return item.barcode?.trim() == cleanBarcode;
    }).firstOrNull;

    if (product == null) {
      GlobalSnackBar.show(
        message: context.tr.posBarcodeNotFound(cleanBarcode),
        isError: true,
      );
      return;
    }

    context.read<PosBloc>().add(PosAddProduct(product));

    GlobalSnackBar.show(message: '${product.name ?? 'Product'} added to cart');
  }
}
