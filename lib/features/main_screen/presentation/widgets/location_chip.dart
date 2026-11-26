import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/features/business/data/models/responses/business_response_dto.dart';
import 'package:amana_pos/features/main_screen/presentation/widgets/location_switcher_sheet.dart';
import 'package:amana_pos/features/pos/presentation/bloc/pos_bloc.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/theme/phosphor_icons.dart';
import 'package:amana_pos/widgets/app_sheet.dart';
import 'package:amana_pos/widgets/pressable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class LocationChip extends StatelessWidget {
  const LocationChip({
    super.key,
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
    final text = Theme.of(context).textTheme;
    final hasMultiple =
        (business?.shopCount ?? business?.shops?.length ?? 0) > 1;

    // One branch: the business name ("Main Branch" says nothing). Several:
    // only the branch you are working in, the business name is not repeated.
    final shop = _selectedShop();
    final businessName = business?.name?.trim() ?? '';
    final shopName = shop?.name?.trim() ?? '';
    final branchName = !hasMultiple && businessName.isNotEmpty
        ? businessName
        : shopName.isNotEmpty
        ? shopName
        : businessName.isNotEmpty
        ? businessName
        : context.tr.selectBranch;

    return Pressable(
      onTap: hasMultiple
          ? () => showAppSheet(
              context,
              builder: (_) => BlocProvider.value(
                value: context.read<PosBloc>(),
                child: LocationSwitcherSheet(
                  business: business!,
                  selectedShopId: selectedShopId,
                ),
              ),
            )
          : null,
      child: Container(
        height: 34,
        constraints: const BoxConstraints(maxWidth: 180),
        padding: const EdgeInsetsDirectional.only(
          start: AppDims.s3,
          end: AppDims.s3 - 2,
        ),
        decoration: BoxDecoration(
          color: colors.surfaceSoft,
          borderRadius: AppDims.borderPill,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              PhosphorIconsRegular.storefront,
              size: 17,
              color: colors.textSecondary,
            ),
            const SizedBox(width: AppDims.s2 - 1),
            Flexible(
              child: Text(
                branchName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: text.labelLarge!.copyWith(color: colors.textPrimary),
              ),
            ),
            if (hasMultiple) ...[
              const SizedBox(width: AppDims.s1 + 2),
              Icon(
                PhosphorIconsRegular.caretDown,
                size: 12,
                color: colors.textHint,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
