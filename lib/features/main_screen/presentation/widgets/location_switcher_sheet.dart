import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/features/business/data/models/responses/business_response_dto.dart';
import 'package:amana_pos/features/pos/presentation/bloc/pos_bloc.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/theme/phosphor_icons.dart';
import 'package:amana_pos/widgets/app_group.dart';
import 'package:amana_pos/widgets/app_sheet.dart';
import 'package:amana_pos/widgets/pressable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class LocationSwitcherSheet extends StatelessWidget {
  const LocationSwitcherSheet({
    super.key,
    required this.business,
    required this.selectedShopId,
  });

  final BusinessData business;
  final String? selectedShopId;

  @override
  Widget build(BuildContext context) {
    final shops =
        business.shops
            ?.where((shop) => shop.id != null && (shop.isActive ?? true))
            .toList() ??
        [];

    return AppSheet(
      title: context.tr.lsSwitchLocation,
      subtitle: business.name ?? 'Workspace',
      trailingAction: AppSheetAction(
        label: context.tr.done,
        emphasized: true,
        onTap: () => Navigator.of(context).pop(),
      ),
      keyboardSafe: false,
      child: AppGroup(
        children: [
          for (final shop in shops)
            _ShopRow(
              name: shop.name ?? 'Shop',
              isSelected: shop.id == selectedShopId,
              onTap: () {
                final shopId = shop.id;
                if (shopId == null || shopId.isEmpty) return;

                context.read<PosBloc>().add(
                  PosShopSelected(
                    shopId: shopId,
                    shopName: shop.name ?? 'Shop',
                  ),
                );

                Navigator.of(context).pop();
              },
            ),
        ],
      ),
    );
  }
}

class _ShopRow extends StatelessWidget {
  const _ShopRow({
    required this.name,
    required this.isSelected,
    required this.onTap,
  });

  final String name;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final text = Theme.of(context).textTheme;

    return Pressable(
      onTap: isSelected ? null : onTap,
      scale: 1,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDims.s4,
          vertical: AppDims.s3,
        ),
        child: Row(
          children: [
            const AppIconTile(icon: PhosphorIconsRegular.storefront),
            const SizedBox(width: AppDims.s3),
            Expanded(
              child: Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: text.bodyLarge!.copyWith(color: colors.textPrimary),
              ),
            ),
            if (isSelected)
              Icon(PhosphorIconsRegular.check, size: 20, color: colors.primary),
          ],
        ),
      ),
    );
  }
}
