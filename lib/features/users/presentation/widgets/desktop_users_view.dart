import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/features/users/data/models/responses/user_response_dto.dart';
import 'package:amana_pos/features/users/presentation/bloc/users_bloc.dart';
import 'package:amana_pos/features/users/presentation/users_screen.dart';
import 'package:amana_pos/features/users/presentation/widgets/add_user_sheet.dart';
import 'package:amana_pos/features/users/presentation/widgets/desktop_user_detail_drawer.dart';
import 'package:amana_pos/features/users/presentation/widgets/desktop_users_sidebar.dart';
import 'package:amana_pos/features/users/presentation/widgets/desktop_users_top_bar.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/utilities/extension.dart';
import 'package:amana_pos/widgets/shimmer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:amana_pos/common/motion/motion_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solar_icons/solar_icons.dart';

const double _kSidebarWidth = 300;
const double _kMaxContentWidth = 1800;

class DesktopUsersView extends StatefulWidget {
  const DesktopUsersView({super.key});

  @override
  State<DesktopUsersView> createState() => _DesktopUsersViewState();
}

class _DesktopUsersViewState extends State<DesktopUsersView>
    with SingleTickerProviderStateMixin {
  // Drawer state
  UserData? _drawerUser;
  UserData? _lastDrawerUser;
  late final AnimationController _drawerCtrl;
  late final Animation<double> _drawerAnim;
  OverlayEntry? _overlayEntry;

  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';
  UserQuickFilter _filter = UserQuickFilter.all;

  @override
  void initState() {
    super.initState();
    _drawerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _drawerAnim = CurvedAnimation(
      parent: _drawerCtrl,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    context.read<UserBloc>().add(OnUserInitial());
    _searchCtrl.addListener(_onSearchChanged);
  }

  void _openDrawer(UserData user) {
    setState(() {
      _drawerUser = user;
      _lastDrawerUser = user;
    });
    if (_overlayEntry == null) {
      _overlayEntry = OverlayEntry(builder: _buildOverlayContent);
      Overlay.of(context).insert(_overlayEntry!);
    } else {
      _overlayEntry!.markNeedsBuild();
    }
    _drawerCtrl.forward();
  }

  void _closeDrawer() {
    setState(() => _drawerUser = null);
    _overlayEntry?.markNeedsBuild();
    _drawerCtrl.reverse().then((_) {
      _overlayEntry?.remove();
      _overlayEntry = null;
      if (mounted) setState(() => _lastDrawerUser = null);
    });
  }

  Widget _buildOverlayContent(BuildContext overlayCtx) {
    final user = _lastDrawerUser;
    if (user == null) return const SizedBox.shrink();
    return Material(
      type: MaterialType.transparency,
      child: BlocProvider.value(
        value: context.read<UserBloc>(),
        child: AnimatedBuilder(
          animation: _drawerAnim,
          builder: (ctx, child) {
            final isRTL = Directionality.of(ctx) == TextDirection.rtl;
            final dx = (isRTL ? -1.0 : 1.0) *
                kDesktopUserDrawerWidth *
                (1 - _drawerAnim.value);
            return Stack(
              children: [
                IgnorePointer(
                  ignoring: _drawerUser == null,
                  child: GestureDetector(
                    onTap: _closeDrawer,
                    child: ColoredBox(
                      color: Colors.black
                          .withValues(alpha: _drawerAnim.value * 0.35),
                      child: const SizedBox.expand(),
                    ),
                  ),
                ),
                PositionedDirectional(
                  top: 0,
                  bottom: 0,
                  end: 0,
                  width: kDesktopUserDrawerWidth,
                  child: IgnorePointer(
                    ignoring: _drawerUser == null,
                    child: Transform.translate(
                      offset: Offset(dx, 0),
                      child: child,
                    ),
                  ),
                ),
              ],
            );
          },
          child: DesktopUserDetailDrawer(
            user: user,
            onClose: _closeDrawer,
          ),
        ),
      ),
    );
  }

  void _onSearchChanged() {
    final q = _searchCtrl.text.trim().toLowerCase();
    if (q != _query) setState(() => _query = q);
  }

  void _selectFilter(UserQuickFilter filter) {
    if (_filter == filter) return;
    setState(() => _filter = filter);
  }

  Future<void> _refresh() async {
    context.read<UserBloc>().add(OnUserInitial());
  }

  @override
  void dispose() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    _drawerCtrl.dispose();
    _searchCtrl.removeListener(_onSearchChanged);
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Column(
          children: [
            DesktopUsersTopBar(
              searchCtrl: _searchCtrl,
              onRefresh: _refresh,
            ),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: _kMaxContentWidth),
                  child: Padding(
                    padding: const EdgeInsets.all(AppDims.s6),
                    child: BlocBuilder<UserBloc, UserState>(
                      buildWhen: (prev, curr) =>
                          prev.userStatus != curr.userStatus ||
                          prev.userList != curr.userList,
                      builder: (context, state) {
                        return switch (state.userStatus) {
                          UserStatus.initial ||
                          UserStatus.loading =>
                            const _DesktopUsersSkeleton(),

                          UserStatus.failure => _DesktopUsersError(
                              message: state.responseError,
                              onRetry: _refresh,
                            ),

                          UserStatus.success => _DesktopUsersContent(
                              users: state.userList,
                              query: _query,
                              filter: _filter,
                              onFilterChanged: _selectFilter,
                              onClearSearch: _searchCtrl.clear,
                              onUserTap: _openDrawer,
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
    );
  }
}

// ── Content ────────────────────────────────────────────────────────────────────

class _DesktopUsersContent extends StatelessWidget {
  final List<UserData> users;
  final String query;
  final UserQuickFilter filter;
  final ValueChanged<UserQuickFilter> onFilterChanged;
  final VoidCallback onClearSearch;
  final ValueChanged<UserData> onUserTap;

  const _DesktopUsersContent({
    required this.users,
    required this.query,
    required this.filter,
    required this.onFilterChanged,
    required this.onClearSearch,
    required this.onUserTap,
  });

  List<UserData> _applyFilter(List<UserData> users) {
    switch (filter) {
      case UserQuickFilter.all:
        return users;
      case UserQuickFilter.active:
        return users.where((u) => u.isActive == true).toList();
      case UserQuickFilter.cashiers:
        return users
            .where((u) => u.role?.toLowerCase().trim() == 'cashier')
            .toList();
      case UserQuickFilter.managers:
        return users.where((u) {
          final role = u.role?.toLowerCase().trim();
          return role == 'manager' || role == 'admin';
        }).toList();
    }
  }

  List<UserData> _applySearch(List<UserData> users) {
    if (query.isEmpty) return users;
    return users.where((u) {
      final name = (u.fullName ?? '').toLowerCase();
      final phone = (u.phone ?? '').toLowerCase();
      final role = (u.role ?? '').toLowerCase();
      return name.contains(query) ||
          phone.contains(query) ||
          role.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _applyFilter(users);
    final visible = _applySearch(filtered);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              SliverToBoxAdapter(
                child: _DesktopUsersStatsRow(
                  users: users,
                  selectedFilter: filter,
                  onFilterChanged: onFilterChanged,
                ).mAnimate().fadeIn(duration: 280.ms),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: AppDims.s5)),
              if (users.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _DesktopUsersEmpty(filter: filter),
                )
              else if (visible.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _NoSearchResults(
                    query: query,
                    onClear: onClearSearch,
                  ),
                )
              else
                SliverList.separated(
                  itemCount: visible.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: AppDims.s3),
                  itemBuilder: (context, index) {
                    return _DesktopUserRow(
                      user: visible[index],
                      onTap: () => onUserTap(visible[index]),
                    )
                        .mAnimate(delay: (index % 20 * 20).ms)
                        .fadeIn(duration: 220.ms)
                        .slideY(begin: 0.04, end: 0, curve: Curves.easeOut);
                  },
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
            child: DesktopUsersSidebar(
              users: users,
              onAddUser: () => showAddUserSheet(context),
              onUserTap: onUserTap,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Stats / filter cards row ───────────────────────────────────────────────────

class _DesktopUsersStatsRow extends StatelessWidget {
  final List<UserData> users;
  final UserQuickFilter selectedFilter;
  final ValueChanged<UserQuickFilter> onFilterChanged;

  const _DesktopUsersStatsRow({
    required this.users,
    required this.selectedFilter,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;

    var active = 0;
    var cashiers = 0;
    var managers = 0;

    for (final u in users) {
      if (u.isActive == true) active++;
      final role = u.role?.toLowerCase().trim();
      if (role == 'cashier') cashiers++;
      if (role == 'manager' || role == 'admin') managers++;
    }

    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: SolarIconsOutline.usersGroupRounded,
            color: context.appColors.primary,
            value: '${users.length}',
            label: tr.userStatTotal,
            isSelected: selectedFilter == UserQuickFilter.all,
            onTap: () => onFilterChanged(UserQuickFilter.all),
          ),
        ),
        const SizedBox(width: AppDims.s3),
        Expanded(
          child: _StatCard(
            icon: SolarIconsOutline.checkCircle,
            color: const Color(0xFF16A34A),
            value: '$active',
            label: tr.userStatActive,
            isSelected: selectedFilter == UserQuickFilter.active,
            onTap: () => onFilterChanged(UserQuickFilter.active),
          ),
        ),
        const SizedBox(width: AppDims.s3),
        Expanded(
          child: _StatCard(
            icon: SolarIconsOutline.userSpeakRounded,
            color: const Color(0xFF0EA5E9),
            value: '$cashiers',
            label: tr.userStatCashiers,
            isSelected: selectedFilter == UserQuickFilter.cashiers,
            onTap: () => onFilterChanged(UserQuickFilter.cashiers),
          ),
        ),
        const SizedBox(width: AppDims.s3),
        Expanded(
          child: _StatCard(
            icon: SolarIconsOutline.shieldUser,
            color: const Color(0xFF8B5CF6),
            value: '$managers',
            label: tr.userStatManagers,
            isSelected: selectedFilter == UserQuickFilter.managers,
            onTap: () => onFilterChanged(UserQuickFilter.managers),
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

// ── Desktop user row ───────────────────────────────────────────────────────────

class _DesktopUserRow extends StatefulWidget {
  final UserData user;
  final VoidCallback onTap;

  const _DesktopUserRow({required this.user, required this.onTap});

  @override
  State<_DesktopUserRow> createState() => _DesktopUserRowState();
}

class _DesktopUserRowState extends State<_DesktopUserRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final user = widget.user;
    final isActive = user.isActive ?? false;
    final name = user.fullName?.trim().isNotEmpty == true
        ? user.fullName!.trim()
        : 'User';
    final roleColor = _roleColor(user.role);

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
            onTap: widget.onTap,
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
                    backgroundColor: roleColor.withValues(alpha: 0.10),
                    child: Text(
                      user.fullName?.initials ?? '?',
                      style: AppTextStyles.bs300(context).copyWith(
                        color: roleColor,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppDims.s3),

                  // Name + phone
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.bs300(context).copyWith(
                            color: colors.textPrimary,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        if (user.phone?.trim().isNotEmpty == true) ...[
                          const SizedBox(height: 2),
                          Text(
                            user.phone!.trim(),
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

                  // Shop
                  Expanded(
                    flex: 2,
                    child: Text(
                      user.defaultShopName?.trim().isNotEmpty == true
                          ? user.defaultShopName!.trim()
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

                  // Role badge
                  _Pill(
                    label: _roleLabel(context, user.role),
                    color: roleColor,
                  ),
                  const SizedBox(width: AppDims.s2),

                  // Status badge
                  _Pill(
                    label: isActive
                        ? context.tr.active
                        : context.tr.inactive,
                    color: isActive
                        ? const Color(0xFF16A34A)
                        : colors.textHint,
                  ),
                  const SizedBox(width: AppDims.s3),

                  // Arrow
                  Icon(
                    SolarIconsOutline.altArrowRight,
                    size: 16,
                    color: colors.textHint,
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

Color _roleColor(String? role) {
  return switch (role?.toLowerCase().trim()) {
    'manager' => const Color(0xFF0EA5E9),
    'cashier' => const Color(0xFF0D9488),
    'admin' => const Color(0xFF8B5CF6),
    _ => const Color(0xFF94A3B8),
  };
}

String _roleLabel(BuildContext context, String? role) {
  return switch (role?.toLowerCase().trim()) {
    'manager' => context.tr.manager,
    'cashier' => context.tr.cashier,
    'admin' => context.tr.admin,
    _ => role ?? '—',
  };
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

// ── Empty states ───────────────────────────────────────────────────────────────

class _DesktopUsersEmpty extends StatelessWidget {
  final UserQuickFilter filter;

  const _DesktopUsersEmpty({required this.filter});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final tr = context.tr;

    final (icon, title, message) = switch (filter) {
      UserQuickFilter.all => (
          SolarIconsOutline.usersGroupRounded,
          tr.noUsersYet,
          tr.noUsersYetMessage,
        ),
      UserQuickFilter.active => (
          SolarIconsOutline.checkCircle,
          tr.noActiveUsers,
          tr.noActiveUsersMessage,
        ),
      UserQuickFilter.cashiers => (
          SolarIconsOutline.userSpeakRounded,
          tr.noCashiersFound,
          tr.noCashiersFoundMessage,
        ),
      UserQuickFilter.managers => (
          SolarIconsOutline.shieldUser,
          tr.noManagersFound,
          tr.noManagersFoundMessage,
        ),
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
          if (filter == UserQuickFilter.all) ...[
            const SizedBox(height: AppDims.s4),
            FilledButton.icon(
              onPressed: () => showAddUserSheet(context),
              icon: const Icon(SolarIconsOutline.userPlus),
              label: Text(tr.addUser),
            ),
          ],
        ],
      ),
    );
  }
}

class _NoSearchResults extends StatelessWidget {
  final String query;
  final VoidCallback onClear;

  const _NoSearchResults({required this.query, required this.onClear});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

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
            'No results for "$query"',
            style: AppTextStyles.bs300(context).copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Try a different name, phone or role',
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

class _DesktopUsersError extends StatelessWidget {
  final String? message;
  final Future<void> Function() onRetry;

  const _DesktopUsersError({required this.message, required this.onRetry});

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
            tr.somethingWentWrong,
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

// ── Loading skeleton ───────────────────────────────────────────────────────────

class _DesktopUsersSkeleton extends StatelessWidget {
  const _DesktopUsersSkeleton();

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
                  for (var i = 0; i < 4; i++) ...[
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
              // User rows skeleton
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
                  child: const Row(
                    children: [
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
                  height: i == 0 ? 110 : 200,
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
