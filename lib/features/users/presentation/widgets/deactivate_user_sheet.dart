import 'package:amana_pos/features/users/data/models/responses/user_response_dto.dart';
import 'package:amana_pos/features/users/presentation/bloc/users_bloc.dart';
import 'package:amana_pos/utilities/global_snackbar.dart';
import 'package:amana_pos/widgets/app_deactivate_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

void showDeactivateUserSheet(
    BuildContext context,
    UserData user,
    ) {
  AppDeactivateBottomSheet.show(
    context: context,
    child: BlocProvider.value(
      value: context.read<UserBloc>(),
      child: BlocConsumer<UserBloc, UserState>(
        listenWhen: (previous, current) =>
        previous.submitStatus != current.submitStatus,
        listener: (context, state) {
          if (state.submitStatus == UserSubmitStatus.success) {
            Navigator.of(context)
              ..pop()
              ..pop();

            GlobalSnackBar.show(
              message: 'User deactivated',
              isInfo: true,
            );
          }

          if (state.submitStatus == UserSubmitStatus.failure) {
            Navigator.of(context).pop();

            GlobalSnackBar.show(
              message: state.submitError ?? 'Something went wrong',
              isError: true,
              isAutoDismiss: false,
            );
          }
        },
        buildWhen: (previous, current) =>
        previous.submitStatus != current.submitStatus,
        builder: (context, state) {
          final isLoading = state.submitStatus == UserSubmitStatus.loading;

          return AppDeactivateBottomSheet(
            title: 'Deactivate User?',
            description: '"${user.fullName}" will lose access immediately. '
                'You can reactivate them later.',
            isLoading: isLoading,
            onConfirm: () {
              final userId = user.id;

              if (userId == null) {
                GlobalSnackBar.show(
                  message: 'Invalid user ID',
                  isError: true,
                );
                return;
              }

              context.read<UserBloc>().add(
                OnDeactivateUser(userId: userId),
              );
            },
          );
        },
      ),
    ),
  );
}