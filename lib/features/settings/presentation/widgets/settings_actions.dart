import 'package:amana_pos/common/auth_bloc/auth_bloc.dart';
import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/utilities/dependencies_provider.dart';
import 'package:amana_pos/widgets/app_confirm_sheet.dart';
import 'package:flutter/material.dart';

/// Confirms, then signs out through the AuthBloc.
Future<void> confirmLogout(BuildContext context) async {
  final tr = context.tr;
  final confirmed = await showAppConfirmSheet(
    context,
    title: tr.mrSignOutTitle,
    message: tr.mrSignOutBody,
    confirmLabel: tr.mrSignOut,
  );

  if (confirmed) {
    getIt<AuthBloc>().add(const OnLogoutEvent());
  }
}
