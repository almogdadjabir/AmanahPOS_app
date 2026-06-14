import 'dart:async';

import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/features/customers/data/models/responses/customer_response_dto.dart';
import 'package:amana_pos/features/customers/presentation/bloc/customers_bloc.dart';
import 'package:amana_pos/features/customers/presentation/widgets/customer_form_sheet.dart';
import 'package:amana_pos/features/customers/presentation/widgets/delete_customer_sheet.dart';
import 'package:amana_pos/features/customers/presentation/widgets/desktop_customers_sidebar.dart';
import 'package:amana_pos/features/customers/presentation/widgets/desktop_customers_top_bar.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/utilities/global_snackbar.dart';
import 'package:amana_pos/widgets/shimmer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:amana_pos/common/motion/motion_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solar_icons/solar_icons.dart';

// Re-export the filter enum so the main screen can share it.
// (CustomerQuickFilter is defined in customers_screen.dart)

const double _kSidebarWidth = 320;
const double _kMaxContentWidth = 1800;

/// Desktop layout for the customers screen.
///
/// Trades the mobile single-column list for a control-room composition:
/// a search/add top bar, five clickable filter cards, a scrollable customer
/// list with infinite scroll, and a fixed sidebar showing loyalty leaders
/// and credit accounts — mirrors DesktopInventoryView / DesktopProductsView.
class DesktopCustomersView extends StatefulWidget {
  const DesktopCustomersView({super.key});

  @override
  State<DesktopCustomersView> createState() => _DesktopCustomersViewState();
}

class _DesktopCustomersViewState extends State<DesktopCustomersView> {
  final ScrollController _scrollCtrl = ScrollController();
  final TextEditingController _searchCtrl = TextEditingController();
  bool _isRequestingMore = false;
  Timer? _loadMoreDebounce;
  String _query = '';
  _DesktopFilter _filter = _DesktopFilter.all;

  @override
  void initState() {
    super.initState();
    context.read<CustomersBloc>().add(const OnCustomersInitial());
    _scrollCtrl.addListener(_onScroll);
    _searchCtrl.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    final q = _searchCtrl.text.trim().toLowerCase();
    if (q != _query) {
      setState(() => _query = q);
      context.read<CustomersBloc>().add(OnCustomerSearchChanged(q));
    }
  }

  void _selectFilter(_DesktopFilter filter) {
    if (_filter == filter) return;
    setState(() => _filter = filter);
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

    final pos = _scrollCtrl.position;
    if (pos.pixels < pos.maxScrollExtent - 320) return;

    _isRequestingMore = true;
    context.read<CustomersBloc>().add(const OnLoadMoreCustomers());

    _loadMoreDebounce?.cancel();
    _loadMoreDebounce = Timer(const Duration(milliseconds: 500), () {
      _isRequestingMore = false;
    });
  }

  Future<void> _refresh() async {
    context.read<CustomersBloc>().add(const OnCustomersInitial());
  }

  @override
  void dispose() {
    _loadMoreDebounce?.cancel();
    _scrollCtrl.removeListener(_onScroll);
    _scrollCtrl.dispose();
    _searchCtrl.removeListener(_onSearchChanged);
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return BlocListener<CustomersBloc, CustomersState>(
      listenWhen: (prev, curr) => prev.submitStatus != curr.submitStatus,
      listener: (context, state) {
        if (state.submitStatus == CustomerSubmitStatus.success) {
          Navigator.of(context).maybePop();
          GlobalSnackBar.show(
            message: context.tr.customerUpdatedSuccess,
            isInfo: true,
          );
          context.read<CustomersBloc>().add(const OnAcknowledgeCustomerSubmit());
        }

        if (state.submitStatus == CustomerSubmitStatus.failure) {
          GlobalSnackBar.show(
            message: state.submitError ?? context.tr.somethingWentWrong,
            isError: true,
            isAutoDismiss: false,
          );
          context.read<CustomersBloc>().add(const OnAcknowledgeCustomerSubmit());
        }
      },
      child: Scaffold(
        backgroundColor: colors.background,
        body: SafeArea(
          child: Column(
            children: [
              DesktopCustomersTopBar(
                searchCtrl: _searchCtrl,
                onRefresh: _refresh,
              ),
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: _kMaxContentWidth,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(AppDims.s6),
                      child: BlocBuilder<CustomersBloc, CustomersState>(
                        builder: (context, state) {
                          return switch (state.status) {
                            CustomersStatus.initial ||
                            CustomersStatus.loading =>
                              const _DesktopCustomersSkeleton(),

                            CustomersStatus.failure => _DesktopCustomersError(
                              message: state.responseError,
                              onRetry: _refresh,
                            ),

                            _ => _DesktopCustomersContent(
                              state: state,
                              query: _query,
                              filter: _filter,
                              onFilterChanged: _selectFilter,
                              scrollCtrl: _scrollCtrl,
                              onClearSearch: _searchCtrl.clear,
                            ),
                          };
                        },
                      ),
                    ),
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

// ── Filter enum ───────────────────────────────────────────────────────────────

enum _DesktopFilter { all, active, inactive, credit, withPhone }

// ── Content ────────────────────────────────────────────────────────────────

class _DesktopCustomersContent extends StatelessWidget {
  final CustomersState state;
  final String query;
  final _DesktopFilter filter;
  final ValueChanged<_DesktopFilter> onFilterChanged;
  final ScrollController scrollCtrl;
  final VoidCallback onClearSearch;

  const _DesktopCustomersContent({
    required this.state,
    required this.query,
    required this.filter,
    required this.onFilterChanged,
    required this.scrollCtrl,
    required this.onClearSearch,
  });

  List<CustomerData> _applyFilter(List<CustomerData> customers) {
    switch (filter) {
      case _DesktopFilter.all:
        return customers;
      case _DesktopFilter.active:
        return customers.where((c) => c.isActive == true).toList();
      case _DesktopFilter.inactive:
        return customers.where((c) => c.isActive == false).toList();
      case _DesktopFilter.credit:
        return customers.where((c) => _creditAmount(c) > 0).toList();
      case _DesktopFilter.withPhone:
        return customers
            .where((c) => c.phone?.trim().isNotEmpty == true)
            .toList();
    }
  }

  List<CustomerData> _applySearch(List<CustomerData> customers) {
    if (query.isEmpty) return customers;
    return customers.where((c) {
      final name = (c.name ?? '').toLowerCase();
      final phone = (c.phone ?? '').toLowerCase();
      final email = (c.email ?? '').toLowerCase();
      return name.contains(query) ||
          phone.contains(query) ||
          email.contains(query);
    }).toList();
  }

  static double _creditAmount(CustomerData c) {
    final raw = c.totalPurchases?.trim();
    if (raw == null || raw.isEmpty) return 0;
    return double.tryParse(raw) ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final allCustomers = state.customers;
    final filtered = _applyFilter(allCustomers);
    final visible = _applySearch(filtered);
    final isLoadingMore = state.status == CustomersStatus.loadingMore;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: CustomScrollView(
            controller: scrollCtrl,
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              SliverToBoxAdapter(
                child: _DesktopCustomersStatsRow(
                  customers: allCustomers,
                  selectedFilter: filter,
                  onFilterChanged: onFilterChanged,
                ).mAnimate().fadeIn(duration: 280.ms),
              ),
              const SliverToBoxAdapter(
                child: SizedBox(height: AppDims.s5),
              ),
              if (allCustomers.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _DesktopCustomersEmpty(
                    query: query,
                    filter: filter,
                    onAdd: () => showCustomerFormSheet(context),
                  ),
                )
              else if (visible.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _NoSearchResults(
                    query: query,
                    filter: filter,
                    onClear: onClearSearch,
                  ),
                )
              else
                SliverList.separated(
                  itemCount: visible.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: AppDims.s3),
                  itemBuilder: (context, index) {
                    return _DesktopCustomerRow(customer: visible[index])
                        .mAnimate(delay: (index % 20 * 20).ms)
                        .fadeIn(duration: 220.ms)
                        .slideY(begin: 0.04, end: 0, curve: Curves.easeOut);
                  },
                ),
              if (isLoadingMore)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: AppDims.s5),
                    child: Center(
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          color: context.appColors.primary,
                        ),
                      ),
                    ),
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: AppDims.s6)),
            ],
          ),
        ),
        const SizedBox(width: AppDims.s5),
        SizedBox(
          width: _kSidebarWidth,
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: AppDims.s6),
            child: DesktopCustomersSidebar(
              customers: allCustomers,
              onAddCustomer: () => showCustomerFormSheet(context),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Stats / filter cards row ──────────────────────────────────────────────────

class _DesktopCustomersStatsRow extends StatelessWidget {
  final List<CustomerData> customers;
  final _DesktopFilter selectedFilter;
  final ValueChanged<_DesktopFilter> onFilterChanged;

  const _DesktopCustomersStatsRow({
    required this.customers,
    required this.selectedFilter,
    required this.onFilterChanged,
  });

  static double _creditAmount(CustomerData c) {
    final raw = c.totalPurchases?.trim();
    if (raw == null || raw.isEmpty) return 0;
    return double.tryParse(raw) ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;

    final active = customers.where((c) => c.isActive == true).length;
    final inactive = customers.where((c) => c.isActive == false).length;
    final credit =
        customers.where((c) => _creditAmount(c) > 0).length;
    final withPhone =
        customers.where((c) => c.phone?.trim().isNotEmpty == true).length;

    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: SolarIconsOutline.usersGroupRounded,
            color: context.appColors.primary,
            value: '${customers.length}',
            label: tr.customerStatTotal,
            isSelected: selectedFilter == _DesktopFilter.all,
            onTap: () => onFilterChanged(_DesktopFilter.all),
          ),
        ),
        const SizedBox(width: AppDims.s3),
        Expanded(
          child: _StatCard(
            icon: SolarIconsOutline.checkCircle,
            color: const Color(0xFF16A34A),
            value: '$active',
            label: tr.customerStatActive,
            isSelected: selectedFilter == _DesktopFilter.active,
            onTap: () => onFilterChanged(_DesktopFilter.active),
          ),
        ),
        const SizedBox(width: AppDims.s3),
        Expanded(
          child: _StatCard(
            icon: SolarIconsOutline.pauseCircle,
            color: const Color(0xFF94A3B8),
            value: '$inactive',
            label: tr.customerStatInactive,
            isSelected: selectedFilter == _DesktopFilter.inactive,
            onTap: () => onFilterChanged(_DesktopFilter.inactive),
          ),
        ),
        const SizedBox(width: AppDims.s3),
        Expanded(
          child: _StatCard(
            icon: SolarIconsOutline.walletMoney,
            color: const Color(0xFFEA580C),
            value: '$credit',
            label: tr.customerStatCredit,
            isSelected: selectedFilter == _DesktopFilter.credit,
            onTap: () => onFilterChanged(_DesktopFilter.credit),
          ),
        ),
        const SizedBox(width: AppDims.s3),
        Expanded(
          child: _StatCard(
            icon: SolarIconsOutline.phoneRounded,
            color: const Color(0xFF0EA5E9),
            value: '$withPhone',
            label: tr.customerStatPhone,
            isSelected: selectedFilter == _DesktopFilter.withPhone,
            onTap: () => onFilterChanged(_DesktopFilter.withPhone),
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatefulWidget {
  final IconData icon;
  final Color color;
  final String value;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _StatCard({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_StatCard> createState() => _StatCardState();
}

class _StatCardState extends State<_StatCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final elevated = widget.isSelected || _hovered;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppDims.rXl),
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(AppDims.rXl),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            height: 136,
            padding: const EdgeInsets.all(AppDims.s4),
            decoration: BoxDecoration(
              color: widget.isSelected
                  ? widget.color.withValues(alpha: 0.10)
                  : colors.surface,
              borderRadius: BorderRadius.circular(AppDims.rXl),
              border: Border.all(
                width: widget.isSelected ? 1.5 : 1,
                color: widget.isSelected
                    ? widget.color.withValues(alpha: 0.45)
                    : colors.border,
              ),
              boxShadow: elevated
                  ? [
                      BoxShadow(
                        color: widget.color.withValues(alpha: 0.12),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: widget.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppDims.rMd),
                  ),
                  child: Icon(widget.icon, size: 18, color: widget.color),
                ),
                const Spacer(),
                Text(
                  widget.value,
                  style: AppTextStyles.bs700(context).copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  widget.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.sm300(context).copyWith(
                    color: widget.isSelected
                        ? widget.color
                        : colors.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Desktop customer row ──────────────────────────────────────────────────────

class _DesktopCustomerRow extends StatefulWidget {
  final CustomerData customer;

  const _DesktopCustomerRow({required this.customer});

  @override
  State<_DesktopCustomerRow> createState() => _DesktopCustomerRowState();
}

class _DesktopCustomerRowState extends State<_DesktopCustomerRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final customer = widget.customer;
    final isActive = customer.isActive ?? true;
    final name = customer.name?.trim().isNotEmpty == true
        ? customer.name!.trim()
        : 'Customer';

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        decoration: BoxDecoration(
          color: _hovered ? colors.surfaceSoft : colors.surface,
          borderRadius: BorderRadius.circular(AppDims.rLg),
          border: Border.all(
            color: _hovered
                ? colors.border.withValues(alpha: 0.8)
                : colors.border,
          ),
          boxShadow: _hovered
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(AppDims.rLg),
          child: InkWell(
            onTap: () => showCustomerFormSheet(context, customer: customer),
            borderRadius: BorderRadius.circular(AppDims.rLg),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDims.s4,
                vertical: AppDims.s3,
              ),
              child: Row(
                children: [
                  // Avatar
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: colors.primaryContainer,
                    child: Text(
                      name.characters.first.toUpperCase(),
                      style: AppTextStyles.bs400(context).copyWith(
                        color: colors.primary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppDims.s3),

                  // Name + status
                  Expanded(
                    flex: 3,
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
                                style: AppTextStyles.bs300(context).copyWith(
                                  color: colors.textPrimary,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                            if (!isActive) ...[
                              const SizedBox(width: AppDims.s2),
                              _Pill(
                                label: 'Inactive',
                                color: colors.textHint,
                              ),
                            ],
                          ],
                        ),
                        if (customer.email?.trim().isNotEmpty == true) ...[
                          const SizedBox(height: 2),
                          Text(
                            customer.email!.trim(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.sm300(context).copyWith(
                              color: colors.textHint,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: AppDims.s4),

                  // Phone
                  Expanded(
                    flex: 2,
                    child: Text(
                      customer.phone?.trim().isNotEmpty == true
                          ? customer.phone!.trim()
                          : '—',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bs200(context).copyWith(
                        color: colors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppDims.s4),

                  // Loyalty points
                  _Pill(
                    label: '${customer.loyaltyPoints ?? 0} pts',
                    color: const Color(0xFF8B5CF6),
                  ),
                  const SizedBox(width: AppDims.s2),

                  // Total purchases
                  _Pill(
                    label: customer.totalPurchases?.trim().isNotEmpty == true
                        ? customer.totalPurchases!.trim()
                        : '0.00',
                    color: const Color(0xFF16A34A),
                  ),
                  const SizedBox(width: AppDims.s3),

                  // Actions menu
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
                        child: Text(context.tr.edit),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Text(context.tr.delete),
                      ),
                    ],
                    icon: Icon(
                      SolarIconsOutline.menuDots,
                      color: colors.textHint,
                      size: 18,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final Color color;

  const _Pill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppDims.s2, vertical: 4),
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

// ── Empty state ───────────────────────────────────────────────────────────────

class _DesktopCustomersEmpty extends StatelessWidget {
  final String query;
  final _DesktopFilter filter;
  final VoidCallback onAdd;

  const _DesktopCustomersEmpty({
    required this.query,
    required this.filter,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final tr = context.tr;

    final icon = switch (filter) {
      _DesktopFilter.all => SolarIconsOutline.usersGroupRounded,
      _DesktopFilter.active => SolarIconsOutline.checkCircle,
      _DesktopFilter.inactive => SolarIconsOutline.pauseCircle,
      _DesktopFilter.credit => SolarIconsOutline.walletMoney,
      _DesktopFilter.withPhone => SolarIconsOutline.phoneRounded,
    };

    final title = switch (filter) {
      _DesktopFilter.all => tr.customersEmptyAll,
      _DesktopFilter.active => tr.customersEmptyActive,
      _DesktopFilter.inactive => tr.customersEmptyInactive,
      _DesktopFilter.credit => tr.customersEmptyCredit,
      _DesktopFilter.withPhone => tr.customersEmptyPhone,
    };

    final message = switch (filter) {
      _DesktopFilter.all => tr.customersEmptyAllMsg,
      _DesktopFilter.active => tr.customersEmptyActiveMsg,
      _DesktopFilter.inactive => tr.customersEmptyInactiveMsg,
      _DesktopFilter.credit => tr.customersEmptyCreditMsg,
      _DesktopFilter.withPhone => tr.customersEmptyPhoneMsg,
    };

    return Center(
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
            child: Icon(icon, size: 34, color: colors.textSecondary),
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
          if (filter == _DesktopFilter.all) ...[
            const SizedBox(height: AppDims.s4),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(SolarIconsOutline.userPlus),
              label: Text(tr.addCustomer),
            ),
          ],
        ],
      ),
    );
  }
}

// ── No search / filter results ────────────────────────────────────────────────

class _NoSearchResults extends StatelessWidget {
  final String query;
  final _DesktopFilter filter;
  final VoidCallback onClear;

  const _NoSearchResults({
    required this.query,
    required this.filter,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final tr = context.tr;

    final hasQuery = query.trim().isNotEmpty;
    final title = hasQuery ? tr.customersNoMatchTitle : tr.customersNoMatchTitle;
    final message = hasQuery
        ? tr.customersNoMatchMsg(query.trim())
        : tr.customersNoMatchMsg('this filter');

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: colors.surfaceSoft,
              shape: BoxShape.circle,
            ),
            child: Icon(
              SolarIconsOutline.magnifier,
              size: 28,
              color: colors.textHint,
            ),
          ),
          const SizedBox(height: AppDims.s4),
          Text(
            title,
            style: AppTextStyles.bs300(context).copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            style: AppTextStyles.sm300(context).copyWith(
              color: colors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppDims.s4),
          TextButton(
            onPressed: onClear,
            child: Text(
              'Clear search',
              style: AppTextStyles.bs200(context).copyWith(
                color: colors.primary,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Error state ────────────────────────────────────────────────────────────────

class _DesktopCustomersError extends StatelessWidget {
  final String? message;
  final Future<void> Function() onRetry;

  const _DesktopCustomersError({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;

    return Center(
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
            icon: const Icon(SolarIconsOutline.refresh, size: 16),
            label: Text(tr.retry),
          ),
        ],
      ),
    );
  }
}

// ── Loading skeleton ──────────────────────────────────────────────────────────

class _DesktopCustomersSkeleton extends StatelessWidget {
  const _DesktopCustomersSkeleton();

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Stats row skeleton
              Row(
                children: [
                  for (var i = 0; i < 5; i++) ...[
                    if (i != 0) const SizedBox(width: AppDims.s3),
                    Expanded(
                      child: Container(
                        height: 136,
                        decoration: BoxDecoration(
                          color: colors.surface,
                          borderRadius: BorderRadius.circular(AppDims.rXl),
                          border: Border.all(color: colors.border),
                        ),
                        padding: const EdgeInsets.all(AppDims.s4),
                        child: const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Shimmer(width: 38, height: 38, radius: AppDims.rMd),
                            Spacer(),
                            Shimmer(width: 48, height: 22, radius: 6),
                            SizedBox(height: 8),
                            Shimmer(width: 64, height: 11, radius: 4),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: AppDims.s5),
              // Customer rows skeleton
              for (var i = 0; i < 8; i++) ...[
                if (i != 0) const SizedBox(height: AppDims.s3),
                Container(
                  height: 64,
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(AppDims.rLg),
                    border: Border.all(color: colors.border),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDims.s4,
                    vertical: AppDims.s3,
                  ),
                  child: Row(
                    children: const [
                      Shimmer(width: 44, height: 44, radius: 22),
                      SizedBox(width: AppDims.s3),
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Shimmer(width: 140, height: 13, radius: 4),
                            SizedBox(height: 6),
                            Shimmer(width: 100, height: 10, radius: 4),
                          ],
                        ),
                      ),
                      SizedBox(width: AppDims.s4),
                      Expanded(
                        flex: 2,
                        child: Shimmer(width: 90, height: 13, radius: 4),
                      ),
                      SizedBox(width: AppDims.s4),
                      Shimmer(width: 60, height: 22, radius: 999),
                      SizedBox(width: AppDims.s2),
                      Shimmer(width: 60, height: 22, radius: 999),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: AppDims.s5),
        // Sidebar skeleton
        SizedBox(
          width: _kSidebarWidth,
          child: Column(
            children: [
              for (var i = 0; i < 3; i++) ...[
                if (i != 0) const SizedBox(height: AppDims.s4),
                Container(
                  height: i == 0 ? 110 : 220,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(AppDims.rXl),
                    border: Border.all(color: colors.border),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
