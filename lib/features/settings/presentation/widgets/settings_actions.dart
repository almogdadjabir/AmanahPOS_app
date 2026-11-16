import 'package:amana_pos/common/auth_bloc/auth_bloc.dart';
import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/config/router/route_strings.dart';
import 'package:amana_pos/core/sync/outbox/outbox_store.dart';
import 'package:amana_pos/utilities/dependencies_provider.dart';
import 'package:amana_pos/widgets/app_confirm_sheet.dart';
import 'package:flutter/material.dart';

/// Confirms, then signs out through the AuthBloc.
Future<void> confirmLogout(BuildContext context) async {
  final tr = context.tr;
  // Unsynced outbox rows (rejected included) must be resolved first: retry
  // or discard (user-confirmed) on the pending sync screen.
  final unsynced = await getIt<OutboxStore>().unsyncedCount();
  if (unsynced > 0 && context.mounted) {
    final review = await showAppConfirmSheet(
      context,
      title: tr.syOxLogoutTitle,
      message: tr.syOxLogoutBody(unsynced),
      confirmLabel: tr.syOxLogoutReview,
    );
    if (review && context.mounted) {
      await Navigator.of(context).pushNamed(RouteStrings.pendingSyncScreen);
    }
    return;
  }
  if (!context.mounted) return;
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
