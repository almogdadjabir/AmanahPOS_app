import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/core/responsive/responsive.dart';
import 'package:amana_pos/features/users/data/models/responses/user_response_dto.dart';
import 'package:amana_pos/features/users/presentation/bloc/users_bloc.dart';
import 'package:amana_pos/features/users/presentation/widgets/add_user_sheet.dart';
import 'package:amana_pos/features/users/presentation/widgets/desktop_users_view.dart';
import 'package:amana_pos/features/users/presentation/widgets/user_card_skeleton.dart';
import 'package:amana_pos/features/users/presentation/widgets/user_empty_view.dart';
import 'package:amana_pos/features/users/presentation/widgets/user_error_view.dart';
import 'package:amana_pos/features/users/presentation/widgets/user_list.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/widgets/directional_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solar_icons/solar_icons.dart';

enum UserQuickFilter {
  all,
  active,
  cashiers,
  managers,
}

class UsersScreen extends StatefulWidget {
  final bool isWithAppbar;

  const UsersScreen({
    super.key,
    this.isWithAppbar = false,
  });

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized || context.isDesktop) return;
    _initialized = true;
    context.read<UserBloc>().add(OnUserInitial());
  }

  @override
  Widget build(BuildContext context) {
    if (context.isDesktop) return const DesktopUsersView();

    final colors = context.appColors;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: widget.isWithAppbar
          ? AppBar(
        elevation: 0,
        backgroundColor: colors.background,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          tooltip: context.tr.back,
          onPressed: () => Navigator.of(context).pop(),
          icon: DirectionalIcon(
            icon: SolarIconsOutline.altArrowLeft,
            color: colors.textPrimary,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsetsDirectional.only(end: AppDims.s2),
            child: TextButton.icon(
              onPressed: () => showAddUserSheet(context),
              style: TextButton.styleFrom(
                foregroundColor: colors.primary,
                padding: const EdgeInsetsDirectional.symmetric(
                  horizontal: AppDims.s2,
                ),
                minimumSize: const Size(0, 38),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              icon: const Icon(
                SolarIconsOutline.userPlus,
                size: 18,
              ),
              label: Text(
                context.tr.addCashier,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bs300(context).copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ],
      )
          : null,
      body: BlocBuilder<UserBloc, UserState>(
        buildWhen: (prev, curr) {
          return prev.userStatus != curr.userStatus ||
              prev.userList != curr.userList;
        },
        builder: (context, state) {
          return switch (state.userStatus) {
            UserStatus.initial || UserStatus.loading => const _LoadingView(),
            UserStatus.failure => UserErrorView(message: state.responseError),
            UserStatus.success => state.userList.isEmpty
                ? const UserEmptyView()
                : _CashierManagementContent(
              users: state.userList,
              isWithAppbar: widget.isWithAppbar,
            ),
          };
        },
      ),
    );
  }
}

class _CashierManagementContent extends StatefulWidget {
  final List<UserData> users;
  final bool isWithAppbar;

  const _CashierManagementContent({
    required this.users,
    required this.isWithAppbar,
  });

  @override
  State<_CashierManagementContent> createState() =>
      _CashierManagementContentState();
}

class _CashierManagementContentState extends State<_CashierManagementContent> {
  UserQuickFilter _selectedFilter = UserQuickFilter.all;

  void _onFilterChanged(UserQuickFilter filter) {
    if (_selectedFilter == filter) return;
    setState(() => _selectedFilter = filter);
  }

  List<UserData> get _filteredUsers {
    switch (_selectedFilter) {
      case UserQuickFilter.all:
        return widget.users;

      case UserQuickFilter.active:
        return widget.users.where((user) {
          return user.isActive == true;
        }).toList(growable: false);

      case UserQuickFilter.cashiers:
        return widget.users.where((user) {
          return user.role?.toLowerCase().trim() == 'cashier';
        }).toList(growable: false);

      case UserQuickFilter.managers:
        return widget.users.where((user) {
          final role = user.role?.toLowerCase().trim();
          return role == 'manager' || role == 'admin';
        }).toList(growable: false);
    }
  }

  String _sectionTitle(BuildContext context) {
    switch (_selectedFilter) {
      case UserQuickFilter.all:
        return context.tr.allUsers;
      case UserQuickFilter.active:
        return context.tr.activeUsers;
      case UserQuickFilter.cashiers:
        return context.tr.cashiers;
      case UserQuickFilter.managers:
        return context.tr.managers;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final filteredUsers = _filteredUsers;

    return RefreshIndicator(
      color: colors.primary,
      onRefresh: () async {
        context.read<UserBloc>().add(OnUserInitial());
      },
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        slivers: [
          SliverPadding(
            padding: const EdgeInsetsDirectional.fromSTEB(
              AppDims.s4,
              AppDims.s4,
              AppDims.s4,
              0,
            ),
            sliver: SliverToBoxAdapter(
              child: _UsersHeader(
                users: widget.users,
                selectedFilter: _selectedFilter,
                onFilterChanged: _onFilterChanged,
              )
                  .animate()
                  .fadeIn(duration: 280.ms)
                  .slideY(
                begin: 0.04,
                end: 0,
                duration: 280.ms,
                curve: Curves.easeOutCubic,
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsetsDirectional.fromSTEB(
              AppDims.s4,
              AppDims.s5,
              AppDims.s4,
              AppDims.s2,
            ),
            sliver: SliverToBoxAdapter(
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _sectionTitle(context),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bs700(context).copyWith(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w900,
                        height: 1.05,
                      ),
                    ),
                  ),

                  if (!widget.isWithAppbar) ...[
                    const SizedBox(width: AppDims.s2),
                    TextButton.icon(
                      onPressed: () => showAddUserSheet(context),
                      style: TextButton.styleFrom(
                        foregroundColor: colors.primary,
                        padding: const EdgeInsetsDirectional.symmetric(
                          horizontal: AppDims.s2,
                        ),
                        minimumSize: const Size(0, 38),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      icon: const Icon(
                        SolarIconsOutline.userPlus,
                        size: 18,
                      ),
                      label: Text(
                        context.tr.addUser,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bs300(context).copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          if (filteredUsers.isEmpty)
            SliverToBoxAdapter(
              child: _UserFilterEmptyView(filter: _selectedFilter),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.only(top: AppDims.s2),
              sliver: SliverToBoxAdapter(
                child: UserList(users: filteredUsers),
              ),
            ),

          const SliverToBoxAdapter(
            child: SizedBox(height: 120),
          ),
        ],
      ),
    );
  }
}

class _UsersHeader extends StatelessWidget {
  final List<UserData> users;
  final UserQuickFilter selectedFilter;
  final ValueChanged<UserQuickFilter> onFilterChanged;

  const _UsersHeader({
    required this.users,
    required this.selectedFilter,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    final stats = _UserHeaderStats.fromUsers(users);

    return _UsersHeaderContent(
      stats: stats,
      selectedFilter: selectedFilter,
      onFilterChanged: onFilterChanged,
    );
  }
}

class _UsersHeaderContent extends StatelessWidget {
  final _UserHeaderStats stats;
  final UserQuickFilter selectedFilter;
  final ValueChanged<UserQuickFilter> onFilterChanged;

  const _UsersHeaderContent({
    required this.stats,
    required this.selectedFilter,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final tr = context.tr;

    return DecoratedBox(
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
      child: Padding(
        padding: const EdgeInsets.all(AppDims.s4),
        child: Column(
          children: [
            Row(
              children: [
                _HeaderIcon(color: colors.primary),
                const SizedBox(width: AppDims.s3),
                Expanded(
                  child: _HeaderText(
                    title: tr.usersManagement,
                    subtitle: tr.usersManagementSubtitle,
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppDims.s4),

            Row(
              children: [
                Expanded(
                  child: _UserMiniStat(
                    label: tr.userStatTotal,
                    value: stats.total.toString(),
                    icon: SolarIconsOutline.usersGroupRounded,
                    color: colors.primary,
                    isSelected: selectedFilter == UserQuickFilter.all,
                    onTap: () => onFilterChanged(UserQuickFilter.all),
                  ),
                ),
                const SizedBox(width: AppDims.s2),
                Expanded(
                  child: _UserMiniStat(
                    label: tr.userStatActive,
                    value: stats.active.toString(),
                    icon: SolarIconsOutline.checkCircle,
                    color: const Color(0xFF16A34A),
                    isSelected: selectedFilter == UserQuickFilter.active,
                    onTap: () => onFilterChanged(UserQuickFilter.active),
                  ),
                ),
                const SizedBox(width: AppDims.s2),
                Expanded(
                  child: _UserMiniStat(
                    label: tr.userStatCashiers,
                    value: stats.cashiers.toString(),
                    icon: SolarIconsOutline.userSpeakRounded,
                    color: const Color(0xFF0EA5E9),
                    isSelected: selectedFilter == UserQuickFilter.cashiers,
                    onTap: () => onFilterChanged(UserQuickFilter.cashiers),
                  ),
                ),
                const SizedBox(width: AppDims.s2),
                Expanded(
                  child: _UserMiniStat(
                    label: tr.userStatManagers,
                    value: stats.managers.toString(),
                    icon: SolarIconsOutline.shieldUser,
                    color: const Color(0xFF8B5CF6),
                    isSelected: selectedFilter == UserQuickFilter.managers,
                    onTap: () => onFilterChanged(UserQuickFilter.managers),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderIcon extends StatelessWidget {
  final Color color;

  const _HeaderIcon({
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppDims.rLg),
        border: Border.all(
          color: color.withValues(alpha: 0.16),
        ),
      ),
      child: SizedBox(
        width: 60,
        height: 60,
        child: Icon(
          SolarIconsOutline.usersGroupRounded,
          color: color,
          size: 30,
        ),
      ),
    );
  }
}

class _HeaderText extends StatelessWidget {
  final String title;
  final String subtitle;

  const _HeaderText({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
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
          subtitle,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.bs300(context).copyWith(
            color: colors.textSecondary,
            fontWeight: FontWeight.w700,
            height: 1.35,
          ),
        ),
      ],
    );
  }
}

class _UserMiniStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _UserMiniStat({
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
                textAlign: TextAlign.center,
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

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(AppDims.s4),
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      itemCount: 5,
      separatorBuilder: (_, _) => const SizedBox(height: AppDims.s3),
      itemBuilder: (_, _) => const UserCardSkeleton(),
    );
  }
}

class _UserFilterEmptyView extends StatelessWidget {
  final UserQuickFilter filter;

  const _UserFilterEmptyView({
    required this.filter,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final content = _UserEmptyContent.fromFilter(context, filter);

    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppDims.s4,
        AppDims.s8,
        AppDims.s4,
        AppDims.s4,
      ),
      child: Column(
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: colors.surfaceSoft,
              borderRadius: BorderRadius.circular(AppDims.rXl),
              border: Border.all(color: colors.border),
            ),
            child: SizedBox(
              width: 72,
              height: 72,
              child: Icon(
                content.icon,
                size: 34,
                color: colors.textSecondary,
              ),
            ),
          ),
          const SizedBox(height: AppDims.s4),
          Text(
            content.title,
            textAlign: TextAlign.center,
            style: AppTextStyles.bs500(context).copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: AppDims.s2),
          Text(
            content.message,
            textAlign: TextAlign.center,
            style: AppTextStyles.bs300(context).copyWith(
              color: colors.textSecondary,
              fontWeight: FontWeight.w700,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _UserEmptyContent {
  final String title;
  final String message;
  final IconData icon;

  const _UserEmptyContent({
    required this.title,
    required this.message,
    required this.icon,
  });

  factory _UserEmptyContent.fromFilter(
      BuildContext context,
      UserQuickFilter filter,
      ) {
    final tr = context.tr;

    switch (filter) {
      case UserQuickFilter.all:
        return _UserEmptyContent(
          title: tr.noUsersYet,
          message: tr.noUsersYetMessage,
          icon: SolarIconsOutline.usersGroupRounded,
        );

      case UserQuickFilter.active:
        return _UserEmptyContent(
          title: tr.noActiveUsers,
          message: tr.noActiveUsersMessage,
          icon: SolarIconsOutline.checkCircle,
        );

      case UserQuickFilter.cashiers:
        return _UserEmptyContent(
          title: tr.noCashiersFound,
          message: tr.noCashiersFoundMessage,
          icon: SolarIconsOutline.userSpeakRounded,
        );

      case UserQuickFilter.managers:
        return _UserEmptyContent(
          title: tr.noManagersFound,
          message: tr.noManagersFoundMessage,
          icon: SolarIconsOutline.shieldUser,
        );
    }
  }
}

class _UserHeaderStats {
  final int total;
  final int active;
  final int cashiers;
  final int managers;

  const _UserHeaderStats({
    required this.total,
    required this.active,
    required this.cashiers,
    required this.managers,
  });

  factory _UserHeaderStats.fromUsers(List<UserData> users) {
    var active = 0;
    var cashiers = 0;
    var managers = 0;

    for (final user in users) {
      if (user.isActive == true) {
        active++;
      }

      final role = user.role?.toLowerCase().trim();

      if (role == 'cashier') {
        cashiers++;
      }

      if (role == 'manager' || role == 'admin') {
        managers++;
      }
    }

    return _UserHeaderStats(
      total: users.length,
      active: active,
      cashiers: cashiers,
      managers: managers,
    );
  }
}