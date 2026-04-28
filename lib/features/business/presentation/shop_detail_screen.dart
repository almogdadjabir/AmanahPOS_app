import 'package:amana_pos/features/business/data/models/responses/business_response_dto.dart';
import 'package:amana_pos/features/business/presentation/bloc/business_bloc.dart';
import 'package:amana_pos/features/business/presentation/widgets/edit_shop_sheet.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ShopDetailScreen extends StatelessWidget {
  final String businessId;
  final Shops shop;

  const ShopDetailScreen({
    super.key,
    required this.businessId,
    required this.shop,
  });

  @override
  Widget build(BuildContext context) {
    // Stay in sync with optimistic updates
    return BlocSelector<BusinessBloc, BusinessState, Shops?>(
      selector: (state) => state.businessList
          ?.firstWhere((b) => b.id == businessId,
          orElse: () => BusinessData())
          .shops
          ?.firstWhere((s) => s.id == shop.id, orElse: () => shop),
      builder: (context, data) {
        final s = data ?? shop;
        return Scaffold(
          backgroundColor: context.appColors.background,
          body: CustomScrollView(
            slivers: [
              _ShopAppBar(businessId: businessId, shop: s),
              SliverPadding(
                padding: const EdgeInsets.all(AppDims.s4),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _ShopInfoSection(shop: s),
                    const SizedBox(height: AppDims.s6),
                  ]),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─── App bar ──────────────────────────────────────────────────────────────────

class _ShopAppBar extends StatelessWidget {
  final String businessId;
  final Shops shop;
  const _ShopAppBar({required this.businessId, required this.shop});

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 150,
      pinned: true,
      backgroundColor: context.appColors.surface,
      leading: IconButton(
        onPressed: () => Navigator.of(context).pop(),
        icon: Icon(Icons.arrow_back_rounded,
            color: context.appColors.textPrimary),
      ),
      actions: [
        IconButton(
          onPressed: () =>
              showEditShopSheet(context, businessId: businessId, shop: shop),
          icon: Icon(Icons.edit_outlined,
              color: context.appColors.textPrimary, size: 20),
          tooltip: 'Edit shop',
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          color: context.appColors.surface,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 48),
              Container(
                width: 64, height: 64,
                decoration: BoxDecoration(
                  color: context.appColors.surfaceSoft,
                  borderRadius: BorderRadius.circular(AppDims.rMd),
                ),
                child: Icon(Icons.storefront_outlined,
                    size: 30, color: context.appColors.primary),
              ),
              const SizedBox(height: AppDims.s2),
              Text(
                shop.name ?? '—',
                style: TextStyle(
                  fontFamily: 'NunitoSans', fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: context.appColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Info section ─────────────────────────────────────────────────────────────

class _ShopInfoSection extends StatelessWidget {
  final Shops shop;
  const _ShopInfoSection({required this.shop});

  @override
  Widget build(BuildContext context) {
    final isActive = shop.isActive ?? false;

    return Container(
      decoration: BoxDecoration(
        color: context.appColors.surface,
        borderRadius: BorderRadius.circular(AppDims.rMd),
      ),
      child: Column(
        children: [
          _InfoRow(
            icon: Icons.circle,
            iconColor: isActive
                ? const Color(0xFF22C55E)
                : context.appColors.textHint,
            label: 'Status',
            value: isActive ? 'Active' : 'Inactive',
          ),
          _Divider(),
          if (shop.address != null) ...[
            _InfoRow(
              icon: Icons.location_on_outlined,
              label: 'Address',
              value: shop.address!,
            ),
            _Divider(),
          ],
          if (shop.phone != null)
            _InfoRow(
              icon: Icons.phone_outlined,
              label: 'Phone',
              value: shop.phone!,
            ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final String label;
  final String value;
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppDims.s4, vertical: AppDims.s3),
      child: Row(
        children: [
          Icon(icon, size: 16,
              color: iconColor ?? context.appColors.textHint),
          const SizedBox(width: AppDims.s3),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'NunitoSans', fontSize: 13,
              fontWeight: FontWeight.w600,
              color: context.appColors.textSecondary,
            ),
          ),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              maxLines: 2,
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'NunitoSans', fontSize: 13,
                fontWeight: FontWeight.w700,
                color: context.appColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1, thickness: 1,
      indent: AppDims.s4,
      color: context.appColors.border,
    );
  }
}