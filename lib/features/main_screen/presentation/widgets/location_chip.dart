import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/features/business/data/models/responses/business_response_dto.dart';
import 'package:amana_pos/features/main_screen/presentation/widgets/location_switcher_sheet.dart';
import 'package:amana_pos/features/pos/presentation/bloc/pos_bloc.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solar_icons/solar_icons.dart';

class LocationChip extends StatelessWidget {
  const LocationChip({super.key,
    required this.business,
    required this.selectedShopId,
  });

  final BusinessData? business;
  final String? selectedShopId;

  ShopData? _selectedShop() {
    final shops = business?.shops ?? const <ShopData>[];
    if (selectedShopId != null && selectedShopId!.isNotEmpty) {
      for (final shop in shops) {
        if (shop.id == selectedShopId) return shop;
      }
    }
    final active = shops.where((s) => s.id != null && (s.isActive ?? true));
    return active.isEmpty ? null : active.first;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final hasMultiple = (business?.shopCount ?? 0) > 1;
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    final bizName = business?.name?.trim().isNotEmpty == true
        ? business!.name!.trim()
        : 'Workspace';

    final shop = _selectedShop();
    final branchName = shop?.name?.trim().isNotEmpty == true
        ? shop!.name!.trim()
        : context.tr.selectBranch;

    final address = business?.address?.trim().isNotEmpty == true
        ? business!.address!.trim()
        : context.tr.businessWorkspace;

    return GestureDetector(
      onTap: hasMultiple
          ? () => showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (_) => BlocProvider.value(
          value: context.read<PosBloc>(),
          child: LocationSwitcherSheet(
            business: business!,
            selectedShopId: selectedShopId,
          ),
        ),
      )
          : null,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 46,
        padding: const EdgeInsetsDirectional.fromSTEB(12, 0, 12, 0),
        decoration: BoxDecoration(
          color: colors.surfaceSoft.withValues(alpha: 0.66),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: colors.border.withValues(alpha: 0.78),
            width: 1.1,
          ),
        ),
        child: Row(
          children: [
            if (hasMultiple) ...[
              Icon(
                SolarIconsOutline.altArrowDown,
                size: 14,
                color: colors.textHint,
              ),
              const SizedBox(width: 6),
            ],

            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
                    text: TextSpan(children: [
                      TextSpan(
                        text: bizName,
                        style: AppTextStyles.bs200(context).copyWith(
                          color: colors.textPrimary,
                          fontWeight: FontWeight.w900,
                          height: 1,
                        ),
                      ),
                      TextSpan(
                        text: '  ·  ',
                        style: AppTextStyles.sm300(context).copyWith(
                          color: colors.textHint,
                        ),
                      ),
                      TextSpan(
                        text: branchName,
                        style: AppTextStyles.bs200(context).copyWith(
                          color: colors.textSecondary,
                          fontWeight: FontWeight.w700,
                          height: 1,
                        ),
                      ),
                    ]),
                  ),

                  const SizedBox(height: 2),

                  Text(
                    address,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.start,
                    style: AppTextStyles.bs300(context).copyWith(
                      color: colors.textHint,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}