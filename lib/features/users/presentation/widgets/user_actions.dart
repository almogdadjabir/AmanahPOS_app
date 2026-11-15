import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/features/users/data/models/responses/user_response_dto.dart';
import 'package:amana_pos/features/users/presentation/bloc/users_bloc.dart';
import 'package:amana_pos/features/users/presentation/widgets/user_format.dart';
import 'package:amana_pos/utilities/global_snackbar.dart';
import 'package:amana_pos/widgets/app_confirm_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Waits for the next finished submit on [bloc] (success or failure).
/// Ignores states left over from an earlier submit by waiting for loading.
Future<UserState> nextUserSubmit(UserBloc bloc) {
  return bloc.stream
      .skipWhile((s) => s.submitStatus != UserSubmitStatus.loading)
      .firstWhere(
        (s) =>
            s.submitStatus == UserSubmitStatus.success ||
            s.submitStatus == UserSubmitStatus.failure,
      );
}

/// Sends [event], waits for the result and reports a failure with a snackbar.
/// Shows [successMessage] (when given) on success. Resolves to true on success.
Future<bool> runUserSubmit(
  BuildContext context,
  UserEvent event, {
  String? successMessage,
}) async {
  final tr = context.tr;
  final bloc = context.read<UserBloc>();
  final result = nextUserSubmit(bloc);
  bloc.add(event);
  final state = await result;

  if (state.submitStatus == UserSubmitStatus.success) {
    if (successMessage != null) {
      GlobalSnackBar.show(message: successMessage, isInfo: true);
    }
    return true;
  }

  GlobalSnackBar.show(
    message: state.submitError ?? tr.somethingWentWrong,
    isError: true,
    isAutoDismiss: false,
  );
  return false;
}

/// Confirm sheet, then deactivate. Resolves to true when deactivated.
Future<bool> confirmDeactivateUser(BuildContext context, UserData user) async {
  final tr = context.tr;
  final id = user.id?.trim();
  if (id == null || id.isEmpty) return false;
  final name = user.displayName;

  final confirmed = await showAppConfirmSheet(
    context,
    title: tr.tmDeactivateTitle(name),
    message: tr.tmDeactivateBody(name),
    confirmLabel: tr.tmDeactivateConfirm,
  );
  if (!confirmed || !context.mounted) return false;

  return runUserSubmit(
    context,
    OnDeactivateUser(id),
    successMessage: tr.tmUpdated,
  );
}

Future<bool> reactivateUser(BuildContext context, UserData user) {
  final id = user.id?.trim();
  if (id == null || id.isEmpty) return Future.value(false);
  return runUserSubmit(
    context,
    OnReactivateUser(id),
    successMessage: context.tr.tmUpdated,
  );
}
