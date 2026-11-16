import 'dart:async';

import 'package:amana_pos/common/auth_bloc/auth_bloc.dart';
import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/features/customers/domain/repositories/customer_repository.dart';
import 'package:amana_pos/features/customers/presentation/bloc/customers_bloc.dart';
import 'package:amana_pos/features/customers/presentation/customer_form_screen.dart';
import 'package:amana_pos/features/customers/presentation/widgets/customer_row.dart';
import 'package:amana_pos/features/customers/presentation/widgets/customer_states.dart';
import 'package:amana_pos/features/main_screen/presentation/widgets/nav_shell.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/theme/phosphor_icons.dart';
import 'package:amana_pos/widgets/app_filter_chip.dart';
import 'package:amana_pos/widgets/app_large_title.dart';
import 'package:amana_pos/widgets/app_search_field.dart';
import 'package:amana_pos/widgets/directional_icon.dart';
import 'package:amana_pos/widgets/pressable.dart';
import 'package:flutter/cupertino.dart' show CupertinoSliverRefreshControl;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CustomersScreen extends StatefulWidget {
  /// True when pushed from More: shows Back and no tab bar underneath.
  final bool isWithAppbar;

  const CustomersScreen({super.key, this.isWithAppbar = false});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  final _scrollCtrl = ScrollController();
  final _searchCtrl = TextEditingController();

  bool _initialized = false;
  bool _isRequestingMore = false;
  Timer? _loadMoreTimer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    _scrollCtrl.addListener(_onScroll);
    context.read<CustomersBloc>().add(const OnCustomersInitial());
  }

  @override
  void dispose() {
    _loadMoreTimer?.cancel();
    _scrollCtrl.removeListener(_onScroll);
    _scrollCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollCtrl.hasClients) return;

    final state = context.read<CustomersBloc>().state;
    if (!state.hasMorePages) return;
    if (state.status == CustomersStatus.loading) return;
    if (state.status == CustomersStatus.loadingMore) return;
    if (_isRequestingMore) return;

    final position = _scrollCtrl.position;
    if (position.pixels < position.maxScrollExtent - 260) return;

    _isRequestingMore = true;
    context.read<CustomersBloc>().add(const OnLoadMoreCustomers());

    _loadMoreTimer?.cancel();
    _loadMoreTimer = Timer(const Duration(milliseconds: 500), () {
      _isRequestingMore = false;
    });
  }

  Future<void> _refresh() async {
    final done = Completer<void>();
    context.read<CustomersBloc>().add(
      OnCustomersInitial(silent: true, done: done),
    );
    try {
      await done.future.timeout(const Duration(seconds: 10));
    } catch (_) {
      // Timed out: the control settles, current rows stay on screen.
    }
  }

  void _setFilter(CustomerActiveFilter filter) {
    context.read<CustomersBloc>().add(OnCustomerFilterChanged(filter));
    if (_scrollCtrl.hasClients) _scrollCtrl.jumpTo(0);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final canManage = !context.select<AuthBloc, bool>(
      (b) => b.state.permissions.isCashier,
    );
    final bottomInset =
        (widget.isWithAppbar ? 0 : NavShell.contentHeight) +
        MediaQuery.viewPaddingOf(context).bottom +
        20;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _NavBar(showBack: widget.isWithAppbar),
            Expanded(
              child: BlocBuilder<CustomersBloc, CustomersState>(
                builder: (context, state) =>
                    _list(context, state, canManage, bottomInset),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _list(
    BuildContext context,
    CustomersState state,
    bool canManage,
    double bottomInset,
  ) {
    final colors = context.appColors;
    final tr = context.tr;

    final loading =
        state.status == CustomersStatus.initial ||
        state.status == CustomersStatus.loading;
    final failed = state.status == CustomersStatus.failure;
    final visible = state.visibleCustomers;
    final plainActive =
        state.filter == CustomerActiveFilter.active && !state.isSearching;
    // The chips only make sense once there is something to filter, or when
    // the Inactive chip is on (so the user can leave it).
    final showChips =
        canManage && !(plainActive && (loading || failed || visible.isEmpty));

    final Widget body;
    if (loading) {
      body = const CustomerSkeleton();
    } else if (failed && visible.isEmpty) {
      body = CustomerStateCard(
        icon: PhosphorIconsRegular.wifiSlash,
        tone: CustomerStateTone.danger,
        title: tr.cuErrorTitle,
        body: tr.cuErrorBody,
        actionLabel: tr.retry,
        onAction: () =>
            context.read<CustomersBloc>().add(const OnCustomersInitial()),
      );
    } else if (visible.isEmpty) {
      if (state.isSearching) {
        body = CustomerStateCard(
          icon: PhosphorIconsRegular.magnifyingGlass,
          title: tr.customersNoMatchTitle,
          body: tr.customersNoMatchMsg(state.searchQuery),
        );
      } else if (state.filter == CustomerActiveFilter.inactive) {
        body = CustomerStateCard(
          icon: PhosphorIconsRegular.addressBook,
          title: tr.customersEmptyInactive,
          body: tr.customersEmptyInactiveMsg,
        );
      } else {
        body = CustomerStateCard(
          icon: PhosphorIconsRegular.addressBook,
          title: tr.cuEmptyTitle,
          body: tr.cuEmptyBody,
          actionLabel: tr.cuEmptyAction,
          onAction: () => openCustomerForm(context),
        );
      }
    } else {
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CustomerListGroups(
            customers: visible,
            canManage: canManage,
            grouped: plainActive,
            flatTop: state.isSearching ? 20 : 12,
          ),
          if (state.status == CustomersStatus.loadingMore)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: AppDims.s5),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
        ],
      );
    }

    final showCount = !loading && !failed && visible.isNotEmpty;
    final countText = state.filter == CustomerActiveFilter.inactive
        ? tr.cuCountInactive(state.totalCount)
        : tr.cuCount(state.totalCount);

    return CustomScrollView(
      controller: _scrollCtrl,
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      slivers: [
        CupertinoSliverRefreshControl(onRefresh: _refresh),
        SliverPadding(
          key: const ValueKey('title'),
          padding: const EdgeInsets.symmetric(horizontal: AppDims.s4),
          sliver: SliverToBoxAdapter(child: AppLargeTitle(title: tr.cuTitle)),
        ),
        SliverPadding(
          key: const ValueKey('search'),
          padding: const EdgeInsets.symmetric(horizontal: AppDims.s4),
          sliver: SliverToBoxAdapter(
            child: AppSearchField(
              controller: _searchCtrl,
              hint: tr.cuSearch,
              onChanged: (q) =>
                  context.read<CustomersBloc>().add(OnCustomerSearchChanged(q)),
            ),
          ),
        ),
        if (showChips)
          SliverPersistentHeader(
            key: const ValueKey('chips'),
            pinned: true,
            delegate: _ChipsHeaderDelegate(
              background: colors.background,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppDims.s4,
                  12,
                  AppDims.s4,
                  10,
                ),
                child: Row(
                  children: [
                    AppFilterChip(
                      label: tr.cuChipActive,
                      selected: state.filter == CustomerActiveFilter.active,
                      onTap: () => _setFilter(CustomerActiveFilter.active),
                    ),
                    const SizedBox(width: AppDims.s2),
                    AppFilterChip(
                      label: tr.cuChipInactive,
                      selected: state.filter == CustomerActiveFilter.inactive,
                      onTap: () => _setFilter(CustomerActiveFilter.inactive),
                    ),
                  ],
                ),
              ),
            ),
          ),
        SliverPadding(
          key: const ValueKey('body'),
          padding: EdgeInsets.fromLTRB(
            AppDims.s4,
            showChips ? 0 : 12,
            AppDims.s4,
            bottomInset,
          ),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (showCount)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(4, 6, 4, 10),
                    child: Text(
                      countText,
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.3,
                        color: colors.textSecondary,
                      ),
                    ),
                  ),
                body,
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ChipsHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Color background;
  final Widget child;

  const _ChipsHeaderDelegate({required this.background, required this.child});

  static const double _height = 56;

  @override
  double get minExtent => _height;

  @override
  double get maxExtent => _height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) => ColoredBox(color: background, child: child);

  @override
  bool shouldRebuild(covariant _ChipsHeaderDelegate old) =>
      old.background != background || old.child != child;
}

class _NavBar extends StatelessWidget {
  final bool showBack;
  const _NavBar({required this.showBack});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return SizedBox(
      height: 44,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: [
            if (showBack)
              Pressable(
                onTap: () => Navigator.of(context).maybePop(),
                child: SizedBox(
                  height: 44,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(width: 4),
                      DirectionalIcon(
                        icon: PhosphorIconsRegular.caretLeft,
                        size: 24,
                        color: colors.primary,
                      ),
                      Text(
                        context.tr.back,
                        style: TextStyle(fontSize: 17, color: colors.primary),
                      ),
                      const SizedBox(width: 8),
                    ],
                  ),
                ),
              ),
            const Spacer(),
            Pressable(
              onTap: () => openCustomerForm(context),
              child: SizedBox(
                width: 44,
                height: 44,
                child: Icon(
                  PhosphorIconsRegular.plus,
                  size: 26,
                  color: colors.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
