import 'package:amana_pos/features/users/presentation/bloc/users_bloc.dart';
import 'package:amana_pos/features/users/presentation/widgets/add_user_sheet.dart';
import 'package:amana_pos/features/users/presentation/widgets/user_card_skeleton.dart';
import 'package:amana_pos/features/users/presentation/widgets/user_empty_view.dart';
import 'package:amana_pos/features/users/presentation/widgets/user_error_view.dart';
import 'package:amana_pos/features/users/presentation/widgets/user_list.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  @override
  void initState() {
    super.initState();
    context.read<UserBloc>().add(const OnUserInitial());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appColors.background,
      body: BlocBuilder<UserBloc, UserState>(
        buildWhen: (prev, curr) => prev.userStatus != curr.userStatus ||
        prev.userList != curr.userList,
        builder: (context, state) {
          return switch (state.userStatus) {
            UserStatus.initial ||
            UserStatus.loading => const _LoadingView(),
            UserStatus.failure  => UserErrorView(message: state.responseError),
            UserStatus.success  => state.userList.isEmpty
                ? const UserEmptyView()
                : UserList(users: state.userList),
          };
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showAddUserSheet(context),
        backgroundColor: context.appColors.primary,
        icon: const Icon(Icons.person_add_rounded, color: Colors.white),
        label: const Text(
          'Add User',
          style: TextStyle(
            fontFamily: 'NunitoSans', fontSize: 13,
            fontWeight: FontWeight.w800, color: Colors.white,
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
      itemCount: 5,
      separatorBuilder: (_, __) => const SizedBox(height: AppDims.s3),
      itemBuilder: (_, __) => const UserCardSkeleton(),
    );
  }
}