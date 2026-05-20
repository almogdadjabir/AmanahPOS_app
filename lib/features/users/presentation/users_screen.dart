import 'package:amana_pos/features/users/data/models/responses/user_response_dto.dart';
import 'package:amana_pos/features/users/presentation/bloc/users_bloc.dart';
import 'package:amana_pos/features/users/presentation/widgets/add_user_sheet.dart';
import 'package:amana_pos/features/users/presentation/widgets/user_card_skeleton.dart';
import 'package:amana_pos/features/users/presentation/widgets/user_empty_view.dart';
import 'package:amana_pos/features/users/presentation/widgets/user_error_view.dart';
import 'package:amana_pos/features/users/presentation/widgets/user_list.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
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
  @override
  void initState() {
    super.initState();
    context.read<UserBloc>().add(OnUserInitial());
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: widget.isWithAppbar
          ? AppBar(
        elevation: 0,
        backgroundColor: colors.background,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: Icon(
            SolarIconsOutline.altArrowLeft,
            color: colors.textPrimary,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppDims.s2),
            child: TextButton.icon(
              onPressed: () => showAddUserSheet(context),
              style: TextButton.styleFrom(
                foregroundColor: colors.primary,
                padding: const EdgeInsets.symmetric(
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
                'Add Cashier',
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

            UserStatus.failure => UserErrorView(
              message: state.responseError,
            ),

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

    setState(() {
      _selectedFilter = filter;
    });
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

  String get _sectionTitle {
    switch (_selectedFilter) {
      case UserQuickFilter.all:
        return 'All';
      case UserQuickFilter.active:
        return 'Active Users';
      case UserQuickFilter.cashiers:
        return 'Cashiers';
      case UserQuickFilter.managers:
        return 'Managers';
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
            padding: const EdgeInsets.fromLTRB(
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
            padding: const EdgeInsets.fromLTRB(
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
                      _sectionTitle,
                      style: AppTextStyles.bs700(context).copyWith(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w900,
                        height: 1.05,
                      ),
                    ),
                  ),
                  if(widget.isWithAppbar == false)
                  TextButton.icon(
                    onPressed: () => showAddUserSheet(context),
                    style: TextButton.styleFrom(
                      foregroundColor: colors.primary,
                      padding: const EdgeInsets.symmetric(
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
                      'Add User',
                      style: AppTextStyles.bs300(context).copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
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
    final colors = context.appColors;

    final active = users.where((user) => user.isActive == true).length;

    final cashiers = users.where((user) {
      return user.role?.toLowerCase().trim() == 'cashier';
    }).length;

    final managers = users.where((user) {
      final role = user.role?.toLowerCase().trim();
      return role == 'manager' || role == 'admin';
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
                      'Users Management',
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
                      'Manage staff accounts, roles, shop access, and POS permissions.',
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
                child: _UserMiniStat(
                  label: 'Total',
                  value: '${users.length}',
                  icon: SolarIconsOutline.usersGroupRounded,
                  color: colors.primary,
                  isSelected: selectedFilter == UserQuickFilter.all,
                  onTap: () => onFilterChanged(UserQuickFilter.all),
                ),
              ),
              const SizedBox(width: AppDims.s2),
              Expanded(
                child: _UserMiniStat(
                  label: 'Active',
                  value: '$active',
                  icon: SolarIconsOutline.checkCircle,
                  color: const Color(0xFF16A34A),
                  isSelected: selectedFilter == UserQuickFilter.active,
                  onTap: () => onFilterChanged(UserQuickFilter.active),
                ),
              ),
              const SizedBox(width: AppDims.s2),
              Expanded(
                child: _UserMiniStat(
                  label: 'Cashiers',
                  value: '$cashiers',
                  icon: SolarIconsOutline.userSpeakRounded,
                  color: const Color(0xFF0EA5E9),
                  isSelected: selectedFilter == UserQuickFilter.cashiers,
                  onTap: () => onFilterChanged(UserQuickFilter.cashiers),
                ),
              ),
              const SizedBox(width: AppDims.s2),
              Expanded(
                child: _UserMiniStat(
                  label: 'Managers',
                  value: '$managers',
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
      separatorBuilder: (_, __) => const SizedBox(height: AppDims.s3),
      itemBuilder: (_, __) => const UserCardSkeleton(),
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

    final title = switch (filter) {
      UserQuickFilter.all => 'No users yet',
      UserQuickFilter.active => 'No active users',
      UserQuickFilter.cashiers => 'No cashiers found',
      UserQuickFilter.managers => 'No managers found',
    };

    final message = switch (filter) {
      UserQuickFilter.all =>
      'Add your first user so your team can start using the POS.',
      UserQuickFilter.active =>
      'No users are currently active.',
      UserQuickFilter.cashiers =>
      'No cashier accounts are currently available.',
      UserQuickFilter.managers =>
      'No manager accounts are currently available.',
    };

    final icon = switch (filter) {
      UserQuickFilter.all => SolarIconsOutline.usersGroupRounded,
      UserQuickFilter.active => SolarIconsOutline.checkCircle,
      UserQuickFilter.cashiers => SolarIconsOutline.userSpeakRounded,
      UserQuickFilter.managers => SolarIconsOutline.shieldUser,
    };

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppDims.s4,
        AppDims.s8,
        AppDims.s4,
        AppDims.s4,
      ),
      child: Column(
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
          const SizedBox(height: AppDims.s4),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTextStyles.bs500(context).copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: AppDims.s2),
          Text(
            message,
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