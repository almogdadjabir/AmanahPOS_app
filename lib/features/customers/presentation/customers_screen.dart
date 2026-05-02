import 'package:amana_pos/features/customers/data/models/responses/customer_response_dto.dart';
import 'package:amana_pos/features/customers/presentation/bloc/customers_bloc.dart';
import 'package:amana_pos/features/customers/presentation/widgets/customer_form_sheet.dart';
import 'package:amana_pos/features/customers/presentation/widgets/delete_customer_sheet.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/utilities/global_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  final _scrollCtrl = ScrollController();
  final _searchCtrl = TextEditingController();

  bool _isRequestingMore = false;

  @override
  void initState() {
    super.initState();

    context.read<CustomersBloc>().add(const OnCustomersInitial());

    _scrollCtrl.addListener(_onScroll);
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

  @override
  void dispose() {
    _scrollCtrl.removeListener(_onScroll);
    _scrollCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<CustomersBloc, CustomersState>(
      listenWhen: (prev, curr) => prev.submitStatus != curr.submitStatus,
      listener: (context, state) {
        if (state.submitStatus == CustomerSubmitStatus.success) {
          Navigator.of(context).maybePop();

          GlobalSnackBar.show(
            message: 'Customer updated successfully',
            isInfo: true,
          );

          context.read<CustomersBloc>().add(
            const OnAcknowledgeCustomerSubmit(),
          );
        }

        if (state.submitStatus == CustomerSubmitStatus.failure) {
          GlobalSnackBar.show(
            message: state.submitError ?? 'Something went wrong',
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
                  return switch (state.status) {
                    CustomersStatus.initial ||
                    CustomersStatus.loading => const _CustomersLoading(),

                    CustomersStatus.failure => SliverFillRemaining(
                      hasScrollBody: false,
                      child: _CustomersError(
                        message: state.responseError,
                        onRetry: _refresh,
                      ),
                    ),

                    _ => state.filteredCustomers.isEmpty
                        ? SliverFillRemaining(
                      hasScrollBody: false,
                      child: _CustomersEmpty(
                        query: state.searchQuery,
                        onAdd: () => showCustomerFormSheet(context),
                      ),
                    )
                        : _CustomersList(
                      customers: state.filteredCustomers,
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
          icon: const Icon(Icons.person_add_alt_rounded, color: Colors.white),
          label: Text(
            'Add Customer',
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
    return SliverAppBar(
      automaticallyImplyLeading: false,
      pinned: true,
      elevation: 0,
      backgroundColor: context.appColors.background,
      surfaceTintColor: Colors.transparent,
      title: Text(
        'Customers',
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
            Icons.refresh_rounded,
            color: context.appColors.textPrimary,
          ),
        ),
      ],
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
          hintText: 'Search customers, phone, email...',
          hintStyle: AppTextStyles.bs300(context).copyWith(
            color: colors.textHint,
            fontWeight: FontWeight.w600,
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
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
                            label: 'Inactive',
                            color: colors.textHint,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      customer.phone?.trim().isNotEmpty == true
                          ? customer.phone!.trim()
                          : 'No phone',
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
                          label: '${customer.loyaltyPoints ?? 0} points',
                          color: const Color(0xFF8B5CF6),
                        ),
                        _SmallPill(
                          label: 'Sales ${customer.totalPurchases ?? '0.00'}',
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
                itemBuilder: (_) => const [
                  PopupMenuItem(
                    value: 'edit',
                    child: Text('Edit'),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Text('Delete'),
                  ),
                ],
                icon: Icon(
                  Icons.more_vert_rounded,
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
  final VoidCallback onAdd;

  const _CustomersEmpty({
    required this.query,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final hasQuery = query.trim().isNotEmpty;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDims.s5),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              hasQuery
                  ? Icons.search_off_rounded
                  : Icons.people_alt_outlined,
              size: 46,
              color: context.appColors.textHint,
            ),
            const SizedBox(height: AppDims.s3),
            Text(
              hasQuery ? 'No customers found' : 'No customers yet',
              style: AppTextStyles.bs500(context).copyWith(
                color: context.appColors.textPrimary,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: AppDims.s1),
            Text(
              hasQuery
                  ? 'Nothing matches "${query.trim()}".'
                  : 'Add your first customer to track loyalty and purchases.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bs200(context).copyWith(
                color: context.appColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (!hasQuery) ...[
              const SizedBox(height: AppDims.s4),
              FilledButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.person_add_alt_rounded),
                label: const Text('Add Customer'),
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDims.s5),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off_rounded,
              size: 46,
              color: context.appColors.textHint,
            ),
            const SizedBox(height: AppDims.s3),
            Text(
              'Failed to load customers',
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
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Retry'),
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