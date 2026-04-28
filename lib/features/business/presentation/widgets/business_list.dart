import 'package:amana_pos/config/router/route_strings.dart';
import 'package:amana_pos/features/business/data/models/responses/business_response_dto.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/utilities/extension.dart';
import 'package:flutter/material.dart';

class BusinessList extends StatelessWidget {
  final List<BusinessData> items;
  const BusinessList({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
          AppDims.s4, AppDims.s4, AppDims.s4, 100),
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppDims.s3),
      itemBuilder: (_, i) => _BusinessCard(data: items[i]),
    );
  }
}

class _BusinessCard extends StatelessWidget {
  final BusinessData data;
  const _BusinessCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final isActive = data.isActive ?? false;

    return Material(
      color: context.appColors.surface,
      borderRadius: BorderRadius.circular(AppDims.rMd),
      child: InkWell(
        onTap: () => Navigator.of(context).pushNamed(
          RouteStrings.businessDetailScreen,
          arguments: {'businessData': data},
        ),
        borderRadius: BorderRadius.circular(AppDims.rMd),
        child: Padding(
          padding: const EdgeInsets.all(AppDims.s3),
          child: Row(
            children: [
              Container(
                width: 56, height: 56,
                decoration: BoxDecoration(
                  color: context.appColors.primaryContainer,
                  borderRadius: BorderRadius.circular(AppDims.rSm),
                ),
                alignment: Alignment.center,
                child: data.logo != null
                    ? ClipRRect(
                  borderRadius: BorderRadius.circular(AppDims.rSm),
                  child: Image.network(data.logo!,
                      width: 56, height: 56, fit: BoxFit.cover),
                )
                    : Text(
                  data.name?.initials ?? '?',
                  style: AppTextStyles.bs600(context).copyWith(
                  fontWeight: FontWeight.w800,
                    color: context.appColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: AppDims.s3),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            data.name ?? '—',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.bs400(context).copyWith(
                            fontWeight: FontWeight.w800,
                              color: context.appColors.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppDims.s2),
                        _StatusBadge(active: isActive),
                      ],
                    ),
                    if (data.address != null && data.address?.isNotEmpty == true) ...[
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Icon(Icons.location_on_outlined,
                              size: 12, color: context.appColors.textHint),
                          const SizedBox(width: 3),
                          Flexible(
                            child: Text(
                              data.address!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.bs200(context).copyWith(
                              fontWeight: FontWeight.w600,
                                color: context.appColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.store_outlined,
                            size: 12, color: context.appColors.textHint),
                        const SizedBox(width: 3),
                        Text(
                          '${data.shopCount ?? 0} shop${(data.shopCount ?? 0) == 1 ? '' : 's'}',
                          style: AppTextStyles.bs200(context).copyWith(
                          fontWeight: FontWeight.w600,
                            color: context.appColors.textHint,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              Icon(Icons.chevron_right_rounded,
                  color: context.appColors.textHint),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final bool active;
  const _StatusBadge({required this.active});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: active
            ? const Color(0xFF22C55E).withValues(alpha: 0.12)
            : context.appColors.surfaceSoft,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        active ? 'Active' : 'Inactive',
        style: AppTextStyles.bs300(context).copyWith(
        fontWeight: FontWeight.w800,
          color: active
              ? const Color(0xFF16A34A)
              : context.appColors.textHint,
        ),
      ),
    );
  }
}