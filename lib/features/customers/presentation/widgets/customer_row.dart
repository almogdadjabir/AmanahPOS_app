import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/common/motion/motion_route.dart';
import 'package:amana_pos/features/customers/data/models/responses/customer_response_dto.dart';
import 'package:amana_pos/features/customers/presentation/bloc/customers_bloc.dart';
import 'package:amana_pos/features/customers/presentation/customer_detail_screen.dart';
import 'package:amana_pos/features/customers/presentation/customer_form_screen.dart';
import 'package:amana_pos/features/customers/presentation/widgets/customer_format.dart';
import 'package:amana_pos/features/sales_history/presentation/widgets/sale_format.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/theme/phosphor_icons.dart';
import 'package:amana_pos/widgets/app_swipe_actions.dart';
import 'package:amana_pos/widgets/directional_icon.dart';
import 'package:amana_pos/widgets/pressable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

void openCustomerDetail(BuildContext context, CustomerData customer) {
  final bloc = context.read<CustomersBloc>();

  Navigator.of(context).push(
    motionPageRoute(
      BlocProvider.value(
        value: bloc,
        child: CustomerDetailScreen(customer: customer),
      ),
    ),
  );
}

/// Round initials avatar. [size] 44 in rows, 84 on the detail hero.
class CustomerAvatar extends StatelessWidget {
  final CustomerData customer;
  final double size;
  final bool inactive;

  const CustomerAvatar({
    super.key,
    required this.customer,
    this.size = 44,
    this.inactive = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: inactive ? colors.surfaceSoft : colors.primaryContainer,
      ),
      child: Text(
        customerInitials(customer),
        style: TextStyle(
          fontSize: size > 60 ? 32 : 16,
          height: 1.3,
          fontWeight: FontWeight.w600,
          color: inactive ? colors.disabled : colors.primary,
        ),
      ),
    );
  }
}

/// Contacts-style list: a letter header, then a grouped card of rows.
class CustomerListGroups extends StatelessWidget {
  final List<CustomerData> customers;
  final bool canManage;

  /// Letter headers (Active list without a search). Search results and the
  /// Inactive list are one flat card.
  final bool grouped;

  /// Space above the flat card (grouped lists get it from the letter header).
  final double flatTop;

  const CustomerListGroups({
    super.key,
    required this.customers,
    required this.canManage,
    this.grouped = true,
    this.flatTop = 12,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final text = Theme.of(context).textTheme;
    final groups = grouped
        ? groupCustomers(customers)
        : [MapEntry('', customers)];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final group in groups) ...[
          if (!grouped) SizedBox(height: flatTop),
          if (grouped)
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(4, 14, 4, 6),
              child: Text(
                group.key,
                style: text.bodySmall!.copyWith(
                  fontSize: 13,
                  height: 1.3,
                  fontWeight: FontWeight.w600,
                  color: colors.textHint,
                ),
              ),
            ),
          DecoratedBox(
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: AppDims.borderLg,
              border: Border.all(color: colors.border),
            ),
            child: ClipRRect(
              borderRadius: AppDims.borderLg,
              child: Column(
                children: [
                  for (var i = 0; i < group.value.length; i++) ...[
                    if (i > 0)
                      Divider(
                        height: 0.5,
                        thickness: 0.5,
                        indent: 68,
                        color: colors.border,
                      ),
                    _SwipeRow(customer: group.value[i], canManage: canManage),
                  ],
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _SwipeRow extends StatelessWidget {
  final CustomerData customer;
  final bool canManage;

  const _SwipeRow({required this.customer, required this.canManage});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final active = customer.isActive != false;

    return AppSwipeActions(
      actions: [
        AppSwipeAction(
          label: context.tr.cuSwipeEdit,
          icon: PhosphorIconsRegular.pencilSimple,
          color: colors.primary,
          onTap: () => openCustomerForm(context, customer: customer),
        ),
        if (canManage && active)
          AppSwipeAction(
            label: context.tr.cuSwipeDeactivate,
            icon: PhosphorIconsRegular.prohibit,
            color: colors.danger,
            onTap: () => confirmDeactivateCustomer(context, customer),
          ),
        if (canManage && !active)
          AppSwipeAction(
            label: context.tr.cuSwipeReactivate,
            icon: PhosphorIconsRegular.userCheck,
            color: colors.success,
            onTap: () => reactivateCustomer(context, customer),
          ),
      ],
      child: CustomerRow(
        key: ValueKey(customer.id ?? customer.name),
        customer: customer,
      ),
    );
  }
}

class CustomerRow extends StatelessWidget {
  final CustomerData customer;

  const CustomerRow({super.key, required this.customer});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final tr = context.tr;
    final text = Theme.of(context).textTheme;

    final active = customer.isActive != false;
    final name = customer.name?.trim() ?? '';
    final phone = customer.phone?.trim() ?? '';
    final spent = double.tryParse(customer.totalPurchases ?? '') ?? 0;

    return Pressable(
      onTap: () => openCustomerDetail(context, customer),
      scale: 1,
      child: ColoredBox(
        color: colors.surface,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 64),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppDims.s4),
            child: Row(
              children: [
                CustomerAvatar(customer: customer, inactive: !active),
                const SizedBox(width: AppDims.s3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: text.bodyLarge!.copyWith(
                                fontSize: 17,
                                height: 1.3,
                                fontWeight: FontWeight.w500,
                                color: active
                                    ? colors.textPrimary
                                    : colors.textSecondary,
                              ),
                            ),
                          ),
                          if (!active) ...[
                            const SizedBox(width: 6),
                            DecoratedBox(
                              decoration: BoxDecoration(
                                color: colors.surfaceSoft,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                child: Text(
                                  tr.cuInactiveTag,
                                  style: TextStyle(
                                    fontSize: 12,
                                    height: 1.3,
                                    fontWeight: FontWeight.w600,
                                    color: colors.textHint,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (phone.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 1),
                          child: Text(
                            ltrIsolate(phone),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: text.bodySmall!.copyWith(
                              fontSize: 13,
                              height: 1.3,
                              color: colors.textHint,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                if (spent > 0) ...[
                  const SizedBox(width: AppDims.s3),
                  Text(
                    saleNumber(spent),
                    textDirection: TextDirection.ltr,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.3,
                      color: colors.textHint,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
                const SizedBox(width: AppDims.s3),
                DirectionalIcon(
                  icon: PhosphorIconsRegular.caretRight,
                  size: 16,
                  color: colors.borderStrong,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
