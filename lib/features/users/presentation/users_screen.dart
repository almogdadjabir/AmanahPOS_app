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
        title: Text(
          'Cashiers Management',
          style: AppTextStyles.bs600(context).copyWith(
            color: colors.textPrimary,
            fontWeight: FontWeight.w900,
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

            UserStatus.success => state.userList.isEmpty || 1==1
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

class _CashierManagementContent extends StatelessWidget {
  final List<UserData> users;
  final bool isWithAppbar;

  const _CashierManagementContent({
    required this.users,
    required this.isWithAppbar,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

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
          if (!isWithAppbar)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppDims.s4,
                AppDims.s4,
                AppDims.s4,
                0,
              ),
              sliver: SliverToBoxAdapter(
                child: _CashierHeader(users: users)
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
            padding: EdgeInsets.fromLTRB(
              AppDims.s4,
              isWithAppbar ? AppDims.s4 : AppDims.s4,
              AppDims.s4,
              0,
            ),
            sliver: SliverToBoxAdapter(
              child: _CashierStats(users: users)
                  .animate()
                  .fadeIn(delay: 60.ms, duration: 280.ms)
                  .slideY(
                begin: 0.04,
                end: 0,
                duration: 280.ms,
                curve: Curves.easeOutCubic,
              ),
            ),
          ),

          if (!isWithAppbar)
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
                        'Cashiers',
                        style: AppTextStyles.bs700(context).copyWith(
                          color: colors.textPrimary,
                          fontWeight: FontWeight.w900,
                          height: 1.05,
                        ),
                      ),
                    ),
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
                        'Add Cashier',
                        style: AppTextStyles.bs300(context).copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          SliverPadding(
            padding: EdgeInsets.only(
              top: isWithAppbar ? AppDims.s4 : AppDims.s5,
            ),
            sliver: SliverToBoxAdapter(
              child: UserList(users: users),
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

class _CashierHeader extends StatelessWidget {
  final List<UserData> users;

  const _CashierHeader({
    required this.users,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDims.s4),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppDims.rLg),
        border: Border.all(
          color: colors.border,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
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
                  'Cashier Management',
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
                  'Manage staff accounts, roles, and POS access.',
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
    );
  }
}

class _CashierStats extends StatelessWidget {
  final List<UserData> users;

  const _CashierStats({
    required this.users,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    final active = users.where((user) => user.isActive == true).length;
    final managers = users.where((user) {
      return user.role?.toLowerCase().trim() == 'manager';
    }).length;
    final cashiers = users.where((user) {
      return user.role?.toLowerCase().trim() == 'cashier';
    }).length;

    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: SolarIconsOutline.usersGroupRounded,
            label: 'Total',
            value: '${users.length}',
            color: colors.primary,
          ),
        ),
        const SizedBox(width: AppDims.s2),
        Expanded(
          child: _StatCard(
            icon: SolarIconsOutline.checkCircle,
            label: 'Active',
            value: '$active',
            color: const Color(0xFF16A34A),
          ),
        ),
        const SizedBox(width: AppDims.s2),
        Expanded(
          child: _StatCard(
            icon: SolarIconsOutline.userSpeakRounded,
            label: 'Cashiers',
            value: '$cashiers',
            color: const Color(0xFF0EA5E9),
          ),
        ),
        const SizedBox(width: AppDims.s2),
        Expanded(
          child: _StatCard(
            icon: SolarIconsOutline.shieldUser,
            label: 'Managers',
            value: '$managers',
            color: const Color(0xFF8B5CF6),
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDims.s2,
        vertical: AppDims.s3,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppDims.rMd),
        border: Border.all(
          color: color.withValues(alpha: 0.12),
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
              color: colors.textSecondary,
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          ),
        ],
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