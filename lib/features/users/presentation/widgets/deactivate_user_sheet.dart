import 'package:amana_pos/common/localization/app_localizations_extension.dart';
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
  final userBloc = context.read<UserBloc>();

  AppDeactivateBottomSheet.show(
    context: context,
    child: BlocProvider.value(
      value: userBloc,
      child: _DeactivateUserSheetContent(user: user),
    ),
  );
}

class _DeactivateUserSheetContent extends StatelessWidget {
  final UserData user;

  const _DeactivateUserSheetContent({
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;

    final userName = user.fullName?.trim();
    final displayName = userName?.isNotEmpty == true
        ? userName!
        : tr.thisUser;

    return BlocListener<UserBloc, UserState>(
      listenWhen: (previous, current) {
        return previous.submitStatus != current.submitStatus;
      },
      listener: (context, state) {
        if (state.submitStatus == UserSubmitStatus.success) {
          Navigator.of(context).pop();
          Navigator.of(context).maybePop();

          GlobalSnackBar.show(
            message: context.tr.userDeactivatedSuccessfully,
            isInfo: true,
          );
          return;
        }

        if (state.submitStatus == UserSubmitStatus.failure) {
          Navigator.of(context).pop();

          GlobalSnackBar.show(
            message: state.submitError ?? context.tr.somethingWentWrong,
            isError: true,
            isAutoDismiss: false,
          );
        }
      },
      child: BlocSelector<UserBloc, UserState, UserSubmitStatus>(
        selector: (state) => state.submitStatus,
        builder: (context, submitStatus) {
          final isLoading = submitStatus == UserSubmitStatus.loading;

          return AppDeactivateBottomSheet(
            title: tr.deactivateUser,
            description: tr.deactivateUserMessage(displayName),
            isLoading: isLoading,
            onConfirm: isLoading
                ? null
                : () {
              final userId = user.id?.trim();

              if (userId == null || userId.isEmpty) {
                GlobalSnackBar.show(
                  message: context.tr.invalidUserId,
                  isError: true,
                );
                return;
              }

              context.read<UserBloc>().add(
                OnDeactivateUser(userId),
              );
            },
          );
        },
      ),
    );
  }
}