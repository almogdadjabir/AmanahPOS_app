import 'package:amana_pos/config/router/route_strings.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/widgets/field_label.dart';
import 'package:amana_pos/widgets/form_field.dart';
import 'package:flutter/material.dart';

/// Full-width barcode input with an adjacent scan-button.
///
/// The scan button triggers [RouteStrings.barcodeScannerScreen] and writes
/// the result back into [controller], exactly like the POS search bar does.
class ProductBarcodeField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final FocusNode? nextFocus;

  const ProductBarcodeField({
    super.key,
    required this.controller,
    this.focusNode,
    this.nextFocus,
  });

  Future<void> _scan(BuildContext context) async {
    final code = await Navigator.of(context).pushNamed<String>(
      RouteStrings.barcodeScannerScreen,
    );
    if (!context.mounted) return;
    final clean = code?.trim();
    if (clean == null || clean.isEmpty) return;
    controller.text = clean;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FieldLabel(label: 'Barcode'),
        const SizedBox(height: AppDims.s1),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: AppFormField(
                controller: controller,
                focusNode: focusNode,
                nextFocus: nextFocus,
                hint: '123456789',
                prefixIcon: Icons.barcode_reader,
                keyboardType: TextInputType.number,
                textInputAction:
                    nextFocus == null ? TextInputAction.done : TextInputAction.next,
              ),
            ),
            const SizedBox(width: AppDims.s2),
            // Scan affordance — visually paired with the field.
            GestureDetector(
              onTap: () => _scan(context),
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.09),
                  borderRadius: BorderRadius.circular(AppDims.rMd),
                  border: Border.all(
                    color: colors.primary.withValues(alpha: 0.25),
                  ),
                ),
                child: Icon(
                  Icons.qr_code_scanner_rounded,
                  size: 24,
                  color: colors.primary,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
