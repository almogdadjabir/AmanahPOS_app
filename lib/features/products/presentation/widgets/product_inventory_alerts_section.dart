import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/widgets/field_label.dart';
import 'package:amana_pos/widgets/form_field.dart';
import 'package:flutter/material.dart';

class ProductInventoryAlertsSection extends StatelessWidget {
  final TextEditingController minStockCtrl;
  final TextEditingController expiryAlertCtrl;
  final FocusNode? minStockFocus;
  final FocusNode? expiryAlertFocus;
  final bool enabled;

  const ProductInventoryAlertsSection({
    super.key,
    required this.minStockCtrl,
    required this.expiryAlertCtrl,
    this.minStockFocus,
    this.expiryAlertFocus,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 180),
      opacity: enabled ? 1 : 0.45,
      child: IgnorePointer(
        ignoring: !enabled,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppDims.s3),
          decoration: BoxDecoration(
            color: colors.surfaceSoft,
            borderRadius: BorderRadius.circular(AppDims.rMd),
            border: Border.all(color: colors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.notifications_active_outlined,
                    size: 18,
                    color: colors.primary,
                  ),
                  const SizedBox(width: AppDims.s2),
                  Expanded(
                    child: Text(
                      'Inventory Alerts',
                      style: AppTextStyles.bs400(context).copyWith(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppDims.s1),

              Text(
                'Set when AmanaPOS should warn you about low stock.',
                style: AppTextStyles.bs200(context).copyWith(
                  color: colors.textSecondary,
                  fontWeight: FontWeight.w600,
                  height: 1.35,
                ),
              ),

              const SizedBox(height: AppDims.s3),

              FieldLabel(label: 'Minimum Stock Level'),
              const SizedBox(height: AppDims.s1),
              AppFormField(
                controller: minStockCtrl,
                focusNode: minStockFocus,
                nextFocus: expiryAlertFocus,
                hint: 'Example: 5',
                prefixIcon: Icons.warning_amber_rounded,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return null;

                  final value = double.tryParse(v.trim());
                  if (value == null) return 'Enter a valid number';
                  if (value < 0) return 'Minimum stock cannot be negative';

                  return null;
                },
              ),

              const SizedBox(height: AppDims.s3),

              FieldLabel(label: 'Expiry Alert'),
              const SizedBox(height: AppDims.s1),
              AppFormField(
                controller: expiryAlertCtrl,
                focusNode: expiryAlertFocus,
                hint: 'Coming soon',
                prefixIcon: Icons.event_busy_outlined,
                keyboardType: TextInputType.number,
              ),

              const SizedBox(height: AppDims.s2),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppDims.s2),
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(AppDims.rSm),
                ),
                child: Text(
                  'Expiry alerts will be enabled later when batch/expiry tracking is supported.',
                  style: AppTextStyles.bs100(context).copyWith(
                    color: colors.textSecondary,
                    fontWeight: FontWeight.w700,
                    height: 1.35,
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