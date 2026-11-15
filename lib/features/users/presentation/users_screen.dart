import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/config/router/route_strings.dart';
import 'package:amana_pos/features/main_screen/presentation/widgets/nav_shell.dart';
import 'package:amana_pos/features/users/presentation/bloc/users_bloc.dart';
import 'package:amana_pos/features/users/presentation/user_form_screen.dart';
import 'package:amana_pos/features/users/presentation/widgets/user_format.dart';
import 'package:amana_pos/features/users/presentation/widgets/user_row.dart';
import 'package:amana_pos/features/users/presentation/widgets/user_states.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/theme/phosphor_icons.dart';
import 'package:amana_pos/widgets/app_large_title.dart';
import 'package:amana_pos/widgets/directional_icon.dart';
import 'package:amana_pos/widgets/pressable.dart';
import 'package:flutter/cupertino.dart' show CupertinoSliverRefreshControl;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class UsersScreen extends StatefulWidget {
  /// True when pushed as its own route (back pops); false when it is a shell
  /// feature (back goes to More).
  final bool isWithAppbar;

  const UsersScreen({super.key, this.isWithAppbar = false});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    context.read<UserBloc>().add(const OnUserInitial());
  }

  Future<void> _refresh() async {
    final bloc = context.read<UserBloc>();
    bloc.add(const OnUserInitial(silent: true));
    try {
      await bloc.stream
          .firstWhere(
            (s) =>
                s.userStatus == UserStatus.failure ||
                s.userStatus == UserStatus.success,
          )
          .timeout(const Duration(seconds: 10));
    } catch (_) {
      // Timed out: let the control settle, current data stays on screen.
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final bottomInset = widget.isWithAppbar
        ? MediaQuery.viewPaddingOf(context).bottom + 24
        : NavShell.contentHeight +
              MediaQuery.viewPaddingOf(context).bottom +
              20;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _NavBar(isWithAppbar: widget.isWithAppbar),
            Expanded(
              child: BlocBuilder<UserBloc, UserState>(
                buildWhen: (prev, curr) =>
                    prev.userStatus != curr.userStatus ||
                    prev.userList != curr.userList ||
                    prev.responseError != curr.responseError,
                builder: (context, state) => CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  slivers: [
                    CupertinoSliverRefreshControl(onRefresh: _refresh),
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(
                        AppDims.s4,
                        0,
                        AppDims.s4,
                        bottomInset,
                      ),
                      sliver: SliverToBoxAdapter(child: _content(state)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _content(UserState state) {
    final tr = context.tr;
    final loading =
        state.userStatus == UserStatus.initial ||
        state.userStatus == UserStatus.loading;

    if (loading) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppLargeTitle(title: tr.tmTitle),
          const UserSkeleton(),
        ],
      );
    }

    if (state.userStatus == UserStatus.failure) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppLargeTitle(title: tr.tmTitle),
          UserStateCard(
            icon: PhosphorIconsRegular.wifiSlash,
            tone: UserStateTone.danger,
            title: tr.tmErrorTitle,
            body: state.responseError ?? tr.pcErrorBody,
            actionLabel: tr.retry,
            secondaryAction: true,
            onAction: () => context.read<UserBloc>().add(const OnUserInitial()),
          ),
        ],
      );
    }

    if (state.userList.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppLargeTitle(title: tr.tmTitle),
          UserStateCard(
            icon: PhosphorIconsRegular.usersThree,
            title: tr.tmEmptyTitle,
            body: tr.tmEmptyBody,
            actionLabel: tr.tmEmptyAction,
            onAction: () => openUserForm(context),
          ),
        ],
      );
    }

    final managers = state.userList.where((u) => u.isManager).toList();
    final cashiers = state.userList.where((u) => !u.isManager).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppLargeTitle(
          title: tr.tmTitle,
          subtitle: tr.tmCount(state.userList.length),
        ),
        if (managers.isNotEmpty) ...[
          UserSectionLabel(tr.tmManagers, first: true),
          UserListGroup(users: managers),
        ],
        if (cashiers.isNotEmpty) ...[
          UserSectionLabel(tr.tmCashiers, first: managers.isEmpty),
          UserListGroup(users: cashiers),
        ],
      ],
    );
  }
}

class _NavBar extends StatelessWidget {
  final bool isWithAppbar;
  const _NavBar({required this.isWithAppbar});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final tr = context.tr;

    return SizedBox(
      height: 44,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: [
            Pressable(
              onTap: () => isWithAppbar
                  ? Navigator.of(context).maybePop()
                  : Navigator.of(
                      context,
                    ).pushNamed(RouteStrings.settingsScreen),
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
                      isWithAppbar ? tr.back : tr.navMore,
                      style: TextStyle(
                        fontSize: 17,
                        height: 1.3,
                        color: colors.primary,
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                ),
              ),
            ),
            const Spacer(),
            Pressable(
              onTap: () => openUserForm(context),
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
