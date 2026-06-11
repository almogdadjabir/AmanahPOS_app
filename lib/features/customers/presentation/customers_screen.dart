import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/core/responsive/responsive.dart';
import 'package:amana_pos/features/customers/data/models/responses/customer_response_dto.dart';
import 'package:amana_pos/features/customers/presentation/bloc/customers_bloc.dart';
import 'package:amana_pos/features/customers/presentation/widgets/customer_form_sheet.dart';
import 'package:amana_pos/features/customers/presentation/widgets/delete_customer_sheet.dart';
import 'package:amana_pos/features/customers/presentation/widgets/desktop_customers_view.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/utilities/global_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solar_icons/solar_icons.dart';

enum CustomerQuickFilter {
  all,
  active,
  inactive,
  credit,
  withPhone,
}

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  final _scrollCtrl = ScrollController();
  final _searchCtrl = TextEditingController();

  CustomerQuickFilter _selectedFilter = CustomerQuickFilter.all;
  bool _isRequestingMore = false;

  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized || context.isDesktop) return;
    _initialized = true;
    context.read<CustomersBloc>().add(const OnCustomersInitial());
    _scrollCtrl.addListener(_onScroll);
  }

  void _onCustomerFilterChanged(CustomerQuickFilter filter) {
    if (_selectedFilter == filter) return;

    setState(() {
      _selectedFilter = filter;
    });

    if (_scrollCtrl.hasClients) {
      _scrollCtrl.animateTo(
        0,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _onScroll() {
    if (!_scrollCtrl.hasClients) return;

    final state = context.read<CustomersBloc>().state;

    if (!state.hasMorePages) return;
    if (state.status == CustomersStatus.loading) return;
    if (state.status == CustomersStatus.loadingMore) return;
    if (_isRequestingMore) return;

    final position = _scrollCtrl.position;
    final shouldLoadMore = position.pixels >= position.maxScrollExtent - 260;

    if (!shouldLoadMore) return;

    _isRequestingMore = true;

    context.read<CustomersBloc>().add(const OnLoadMoreCustomers());

    Future<void>.delayed(const Duration(milliseconds: 500), () {
      _isRequestingMore = false;
    });
  }

  Future<void> _refresh() async {
    context.read<CustomersBloc>().add(const OnCustomersInitial());
    await Future<void>.delayed(const Duration(milliseconds: 450));
  }

  List<CustomerData> _filteredCustomers(List<CustomerData> customers) {
    switch (_selectedFilter) {
      case CustomerQuickFilter.all:
        return customers;

      case CustomerQuickFilter.active:
        return customers.where((customer) {
          return customer.isActive == true;
        }).toList(growable: false);

      case CustomerQuickFilter.inactive:
        return customers.where((customer) {
          return customer.isActive == false;
        }).toList(growable: false);

      case CustomerQuickFilter.credit:
        return customers.where((customer) {
          return _customerCreditAmount(customer) > 0;
        }).toList(growable: false);

      case CustomerQuickFilter.withPhone:
        return customers.where((customer) {
          return customer.phone?.trim().isNotEmpty == true;
        }).toList(growable: false);
    }
  }

  static double _customerCreditAmount(CustomerData customer) {
    final raw = customer.totalPurchases?.trim();

    if (raw == null || raw.isEmpty) return 0;

    return double.tryParse(raw) ?? 0;
  }

  @override
  void dispose() {
    _scrollCtrl.removeListener(_onScroll);
    _scrollCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (context.isDesktop) return const DesktopCustomersView();

    return BlocListener<CustomersBloc, CustomersState>(
      listenWhen: (prev, curr) => prev.submitStatus != curr.submitStatus,
      listener: (context, state) {
        if (state.submitStatus == CustomerSubmitStatus.success) {
          Navigator.of(context).maybePop();

          GlobalSnackBar.show(
            message: context.tr.customerUpdatedSuccess,
            isInfo: true,
          );

          context.read<CustomersBloc>().add(
            const OnAcknowledgeCustomerSubmit(),
          );
        }

        if (state.submitStatus == CustomerSubmitStatus.failure) {
          GlobalSnackBar.show(
            message: state.submitError ?? context.tr.somethingWentWrong,
            isError: true,
            isAutoDismiss: false,
          );

          context.read<CustomersBloc>().add(
            const OnAcknowledgeCustomerSubmit(),
          );
        }
      },
      child: Scaffold(
        backgroundColor: context.appColors.background,
        body: RefreshIndicator(
          color: context.appColors.primary,
          onRefresh: _refresh,
          child: CustomScrollView(
            controller: _scrollCtrl,
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              const _CustomersAppBar(),

              BlocBuilder<CustomersBloc, CustomersState>(
                buildWhen: (prev, curr) =>
                prev.customers != curr.customers ||
                    prev.status != curr.status,
                builder: (context, state) {
                  if (state.status == CustomersStatus.initial ||
                      state.status == CustomersStatus.loading) {
                    return const SliverToBoxAdapter(
                      child: SizedBox.shrink(),
                    );
                  }

                  return SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      AppDims.s4,
                      AppDims.s4,
                      AppDims.s4,
                      0,
                    ),
                    sliver: SliverToBoxAdapter(
                      child: _CustomersHeader(
                        customers: state.customers,
                        selectedFilter: _selectedFilter,
                        onFilterChanged: _onCustomerFilterChanged,
                      ),
                    ),
                  );
                },
              ),

              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  AppDims.s4,
                  AppDims.s4,
                  AppDims.s4,
                  0,
                ),
                sliver: SliverToBoxAdapter(
                  child: _CustomersSearchField(controller: _searchCtrl),
                ),
              ),

              BlocBuilder<CustomersBloc, CustomersState>(
                buildWhen: (prev, curr) =>
                prev.status != curr.status ||
                    prev.filteredCustomers != curr.filteredCustomers ||
                    prev.searchQuery != curr.searchQuery,
                builder: (context, state) {
                  final customers = _filteredCustomers(state.filteredCustomers);

                  return switch (state.status) {
                    CustomersStatus.initial ||
                    CustomersStatus.loading =>
                    const _CustomersLoading(),

                    CustomersStatus.failure => SliverFillRemaining(
                      hasScrollBody: false,
                      child: _CustomersError(
                        message: state.responseError,
                        onRetry: _refresh,
                      ),
                    ),

                    _ => customers.isEmpty
                        ? SliverFillRemaining(
                      hasScrollBody: false,
                      child: _CustomersEmpty(
                        query: state.searchQuery,
                        filter: _selectedFilter,
                        onAdd: () => showCustomerFormSheet(context),
                      ),
                    )
                        : _CustomersList(
                      customers: customers,
                      isLoadingMore:
                      state.status == CustomersStatus.loadingMore,
                    ),
                  };
                },
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => showCustomerFormSheet(context),
          backgroundColor: context.appColors.primary,
          icon: const Icon(
            SolarIconsOutline.userPlus,
            color: Colors.white,
          ),
          label: Text(
            context.tr.addCustomer,
            style: AppTextStyles.bs300(context).copyWith(
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

class _CustomersAppBar extends StatelessWidget {
  const _CustomersAppBar();

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    return SliverAppBar(
      automaticallyImplyLeading: false,
      pinned: true,
      elevation: 0,
      backgroundColor: context.appColors.background,
      surfaceTintColor: Colors.transparent,
      title: Text(
        tr.customers,
        style: AppTextStyles.bs600(context).copyWith(
          color: context.appColors.textPrimary,
          fontWeight: FontWeight.w900,
        ),
      ),
      actions: [
        IconButton(
          onPressed: () {
            context.read<CustomersBloc>().add(const OnCustomersInitial());
          },
          icon: Icon(
            SolarIconsOutline.refresh,
            color: context.appColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _CustomersHeader extends StatelessWidget {
  final List<CustomerData> customers;
  final CustomerQuickFilter selectedFilter;
  final ValueChanged<CustomerQuickFilter> onFilterChanged;

  const _CustomersHeader({
    required this.customers,
    required this.selectedFilter,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final tr = context.tr;

    final active = customers.where((customer) {
      return customer.isActive == true;
    }).length;

    final inactive = customers.where((customer) {
      return customer.isActive == false;
    }).length;

    final credit = customers.where((customer) {
      return _CustomersScreenState._customerCreditAmount(customer) > 0;
    }).length;

    final withPhone = customers.where((customer) {
      return customer.phone?.trim().isNotEmpty == true;
    }).length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDims.s4),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppDims.rLg),
        border: Border.all(color: colors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(AppDims.rLg),
                  border: Border.all(
                    color: colors.primary.withValues(alpha: 0.16),
                  ),
                ),
                child: Icon(
                  SolarIconsOutline.usersGroupRounded,
                  color: colors.primary,
                  size: 30,
                ),
              ),
              const SizedBox(width: AppDims.s3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tr.customers,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bs700(context).copyWith(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w900,
                        height: 1.05,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      tr.customersSubtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bs300(context).copyWith(
                        color: colors.textSecondary,
                        fontWeight: FontWeight.w700,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDims.s4),
          Row(
            children: [
              Expanded(
                child: _CustomerMiniStat(
                  label: tr.customerStatTotal,
                  value: '${customers.length}',
                  icon: SolarIconsOutline.usersGroupRounded,
                  color: colors.primary,
                  isSelected: selectedFilter == CustomerQuickFilter.all,
                  onTap: () => onFilterChanged(CustomerQuickFilter.all),
                ),
              ),
              const SizedBox(width: AppDims.s2),
              Expanded(
                child: _CustomerMiniStat(
                  label: tr.customerStatActive,
                  value: '$active',
                  icon: SolarIconsOutline.checkCircle,
                  color: const Color(0xFF16A34A),
                  isSelected: selectedFilter == CustomerQuickFilter.active,
                  onTap: () => onFilterChanged(CustomerQuickFilter.active),
                ),
              ),
              const SizedBox(width: AppDims.s2),
              Expanded(
                child: _CustomerMiniStat(
                  label: tr.customerStatInactive,
                  value: '$inactive',
                  icon: SolarIconsOutline.pauseCircle,
                  color: const Color(0xFF94A3B8),
                  isSelected: selectedFilter == CustomerQuickFilter.inactive,
                  onTap: () => onFilterChanged(CustomerQuickFilter.inactive),
                ),
              ),
              const SizedBox(width: AppDims.s2),
              Expanded(
                child: _CustomerMiniStat(
                  label: tr.customerStatCredit,
                  value: '$credit',
                  icon: SolarIconsOutline.walletMoney,
                  color: const Color(0xFFEA580C),
                  isSelected: selectedFilter == CustomerQuickFilter.credit,
                  onTap: () => onFilterChanged(CustomerQuickFilter.credit),
                ),
              ),
              const SizedBox(width: AppDims.s2),
              Expanded(
                child: _CustomerMiniStat(
                  label: tr.customerStatPhone,
                  value: '$withPhone',
                  icon: SolarIconsOutline.phoneRounded,
                  color: const Color(0xFF0EA5E9),
                  isSelected: selectedFilter == CustomerQuickFilter.withPhone,
                  onTap: () => onFilterChanged(CustomerQuickFilter.withPhone),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CustomerMiniStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _CustomerMiniStat({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppDims.rMd),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDims.rMd),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(
            horizontal: AppDims.s2,
            vertical: AppDims.s3,
          ),
          decoration: BoxDecoration(
            color: isSelected
                ? color.withValues(alpha: 0.14)
                : color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(AppDims.rMd),
            border: Border.all(
              width: isSelected ? 1.4 : 1,
              color: isSelected
                  ? color.withValues(alpha: 0.55)
                  : color.withValues(alpha: 0.12),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 20,
                color: color,
              ),
              const SizedBox(height: 6),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  value,
                  maxLines: 1,
                  style: AppTextStyles.bs500(context).copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bs100(context).copyWith(
                  color: isSelected ? color : colors.textSecondary,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CustomersSearchField extends StatelessWidget {
  final TextEditingController controller;

  const _CustomersSearchField({
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final tr = context.tr;

    return SizedBox(
      height: 46,
      child: TextField(
        controller: controller,
        onChanged: (value) {
          context.read<CustomersBloc>().add(
            OnCustomerSearchChanged(value),
          );
        },
        style: AppTextStyles.bs300(context).copyWith(
          color: colors.textPrimary,
          fontWeight: FontWeight.w700,
        ),
        decoration: InputDecoration(
          hintText: tr.customerSearchHint,
          hintStyle: AppTextStyles.bs300(context).copyWith(
            color: colors.textHint,
            fontWeight: FontWeight.w600,
          ),
          prefixIcon: Icon(
            SolarIconsOutline.magnifier,
            color: colors.textHint,
            size: 20,
          ),
          filled: true,
          fillColor: colors.surface,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppDims.s3,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppDims.rMd),
            borderSide: BorderSide(color: colors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppDims.rMd),
            borderSide: BorderSide(color: colors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppDims.rMd),
            borderSide: BorderSide(
              color: colors.primary,
              width: 1.4,
            ),
          ),
        ),
      ),
    );
  }
}

class _CustomersList extends StatelessWidget {
  final List<CustomerData> customers;
  final bool isLoadingMore;

  const _CustomersList({
    required this.customers,
    required this.isLoadingMore,
  });

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(
        AppDims.s4,
        AppDims.s4,
        AppDims.s4,
        100,
      ),
      sliver: SliverList.separated(
        itemCount: customers.length + (isLoadingMore ? 1 : 0),
        separatorBuilder: (_, __) => const SizedBox(height: AppDims.s3),
        itemBuilder: (context, index) {
          if (index >= customers.length) {
            return const _LoadMoreIndicator();
          }

          return _CustomerCard(customer: customers[index]);
        },
      ),
    );
  }
}

class _CustomerCard extends StatelessWidget {
  final CustomerData customer;

  const _CustomerCard({
    required this.customer,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final tr = context.tr;
    final isActive = customer.isActive ?? true;
    final name = customer.name?.trim().isNotEmpty == true
        ? customer.name!.trim()
        : 'Customer';

    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(AppDims.rLg),
      child: InkWell(
        onTap: () => showCustomerFormSheet(context, customer: customer),
        borderRadius: BorderRadius.circular(AppDims.rLg),
        child: Container(
          padding: const EdgeInsets.all(AppDims.s4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppDims.rLg),
            border: Border.all(color: colors.border),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 25,
                backgroundColor: colors.primaryContainer,
                child: Text(
                  name.characters.first.toUpperCase(),
                  style: AppTextStyles.bs500(context).copyWith(
                    color: colors.primary,
                    fontWeight: FontWeight.w900,
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
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.bs400(context).copyWith(
                              color: colors.textPrimary,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        if (!isActive) ...[
                          const SizedBox(width: AppDims.s2),
                          _SmallPill(
                            label: tr.customerInactiveLabel,
                            color: colors.textHint,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      customer.phone?.trim().isNotEmpty == true
                          ? customer.phone!.trim()
                          : tr.noPhone,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bs200(context).copyWith(
                        color: colors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (customer.email?.trim().isNotEmpty == true) ...[
                      const SizedBox(height: 2),
                      Text(
                        customer.email!.trim(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bs100(context).copyWith(
                          color: colors.textHint,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    const SizedBox(height: AppDims.s2),
                    Wrap(
                      spacing: AppDims.s2,
                      runSpacing: AppDims.s1,
                      children: [
                        _SmallPill(
                          label: tr.loyaltyPointsSuffix(customer.loyaltyPoints ?? 0),
                          color: const Color(0xFF8B5CF6),
                        ),
                        _SmallPill(
                          label: '${tr.customerSalesPrefix} ${customer.totalPurchases ?? '0.00'}',
                          color: const Color(0xFF16A34A),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppDims.s2),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') {
                    showCustomerFormSheet(context, customer: customer);
                  }

                  if (value == 'delete') {
                    showDeleteCustomerSheet(context, customer: customer);
                  }
                },
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: 'edit',
                    child: Text(tr.edit),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Text(tr.delete),
                  ),
                ],
                icon: Icon(
                  SolarIconsOutline.menuDots,
                  color: colors.textHint,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SmallPill extends StatelessWidget {
  final String label;
  final Color color;

  const _SmallPill({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDims.s2,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: AppTextStyles.bs100(context).copyWith(
          color: color,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _CustomersEmpty extends StatelessWidget {
  final String query;
  final CustomerQuickFilter filter;
  final VoidCallback onAdd;

  const _CustomersEmpty({
    required this.query,
    required this.filter,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final tr = context.tr;
    final hasQuery = query.trim().isNotEmpty;

    final title = hasQuery
        ? tr.customersNoMatchTitle
        : switch (filter) {
      CustomerQuickFilter.all => tr.customersEmptyAll,
      CustomerQuickFilter.active => tr.customersEmptyActive,
      CustomerQuickFilter.inactive => tr.customersEmptyInactive,
      CustomerQuickFilter.credit => tr.customersEmptyCredit,
      CustomerQuickFilter.withPhone => tr.customersEmptyPhone,
    };

    final message = hasQuery
        ? tr.customersNoMatchMsg(query.trim())
        : switch (filter) {
      CustomerQuickFilter.all => tr.customersEmptyAllMsg,
      CustomerQuickFilter.active => tr.customersEmptyActiveMsg,
      CustomerQuickFilter.inactive => tr.customersEmptyInactiveMsg,
      CustomerQuickFilter.credit => tr.customersEmptyCreditMsg,
      CustomerQuickFilter.withPhone => tr.customersEmptyPhoneMsg,
    };

    final icon = hasQuery
        ? SolarIconsOutline.magnifier
        : switch (filter) {
      CustomerQuickFilter.all => SolarIconsOutline.usersGroupRounded,
      CustomerQuickFilter.active => SolarIconsOutline.checkCircle,
      CustomerQuickFilter.inactive => SolarIconsOutline.pauseCircle,
      CustomerQuickFilter.credit => SolarIconsOutline.walletMoney,
      CustomerQuickFilter.withPhone => SolarIconsOutline.phoneRounded,
    };

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDims.s5),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: colors.surfaceSoft,
                borderRadius: BorderRadius.circular(AppDims.rXl),
                border: Border.all(color: colors.border),
              ),
              child: Icon(
                icon,
                size: 34,
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: AppDims.s3),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTextStyles.bs500(context).copyWith(
                color: colors.textPrimary,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: AppDims.s1),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTextStyles.bs200(context).copyWith(
                color: colors.textSecondary,
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
            if (!hasQuery && filter == CustomerQuickFilter.all) ...[
              const SizedBox(height: AppDims.s4),
              FilledButton.icon(
                onPressed: onAdd,
                icon: const Icon(SolarIconsOutline.userPlus),
                label: Text(tr.addCustomer),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CustomersLoading extends StatelessWidget {
  const _CustomersLoading();

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.all(AppDims.s4),
      sliver: SliverList.separated(
        itemCount: 6,
        separatorBuilder: (_, __) => const SizedBox(height: AppDims.s3),
        itemBuilder: (_, __) {
          return Container(
            height: 104,
            decoration: BoxDecoration(
              color: context.appColors.surfaceSoft,
              borderRadius: BorderRadius.circular(AppDims.rLg),
            ),
          );
        },
      ),
    );
  }
}

class _CustomersError extends StatelessWidget {
  final String? message;
  final Future<void> Function() onRetry;

  const _CustomersError({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDims.s5),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              SolarIconsOutline.cloudCross,
              size: 46,
              color: context.appColors.textHint,
            ),
            const SizedBox(height: AppDims.s3),
            Text(
              tr.customersLoadFailed,
              style: AppTextStyles.bs500(context).copyWith(
                color: context.appColors.textPrimary,
                fontWeight: FontWeight.w900,
              ),
            ),
            if (message != null) ...[
              const SizedBox(height: AppDims.s1),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: AppTextStyles.bs200(context).copyWith(
                  color: context.appColors.textSecondary,
                ),
              ),
            ],
            const SizedBox(height: AppDims.s4),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(
                SolarIconsOutline.refresh,
                size: 16,
              ),
              label: Text(tr.retry),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadMoreIndicator extends StatelessWidget {
  const _LoadMoreIndicator();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppDims.s4),
      child: Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            color: context.appColors.primary,
          ),
        ),
      ),
    );
  }
}