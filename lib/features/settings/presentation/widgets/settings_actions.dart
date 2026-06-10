import 'package:amana_pos/common/auth_bloc/auth_bloc.dart';
import 'package:amana_pos/common/locale_bloc/locale_bloc.dart';
import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/core/responsive/adaptive_sheet.dart';
import 'package:amana_pos/features/login/data/models/otp_verify_response.dart';
import 'package:amana_pos/features/main_screen/data/app_feature.dart';
import 'package:amana_pos/features/main_screen/presentation/bloc/navigation_bloc.dart';
import 'package:amana_pos/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:amana_pos/features/settings/presentation/widgets/edit_bankak_sheet.dart';
import 'package:amana_pos/features/settings/presentation/widgets/edit_profile_sheet.dart';
import 'package:amana_pos/features/settings/presentation/widgets/language_picker_sheet.dart';
import 'package:amana_pos/features/settings/presentation/widgets/set_password_sheet.dart';
import 'package:amana_pos/features/settings/presentation/widgets/settings_logout_dialog.dart';
import 'package:amana_pos/utilities/dependencies_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Shared profile/account helpers used by both the mobile and desktop
/// settings layouts so the two surfaces stay behaviourally identical.

bool hasBankakAccount(User profile) {
  return profile.bankakAccount?.accountNumber?.trim().isNotEmpty == true;
}

String bankakSubtitle(BuildContext context, User profile) {
  final tr = context.tr;
  final account = profile.bankakAccount?.accountNumber?.trim();

  if (account == null || account.isEmpty) {
    return tr.settingsBankakNotConfigured;
  }

  final masked = account.length > 4
      ? '•••• ${account.substring(account.length - 4)}'
      : account;

  return tr.settingsBankakReady(masked);
}

String profileSubtitle(BuildContext context, User profile) {
  final email = profile.email?.trim();

  if (email != null && email.isNotEmpty) {
    return email;
  }

  return profile.phone?.trim() ?? context.tr.settingsProfileSubtitleFallback;
}

void openProfileSheet(BuildContext context, User profile) {
  showAdaptivePanel(
    context,
    desktopWidth: 480,
    builder: (_) => BlocProvider.value(
      value: context.read<SettingsBloc>(),
      child: EditProfileSheet(
        fullName: profile.fullName ?? '',
        email: profile.email ?? '',
        bankakAccountNumber: profile.bankakAccount?.accountNumber ?? '',
      ),
    ),
  );
}

void openBankakSheet(BuildContext context, User profile) {
  showAdaptivePanel(
    context,
    desktopWidth: 480,
    builder: (_) => BlocProvider.value(
      value: context.read<SettingsBloc>(),
      child: EditBankakSheet(
        fullName: profile.fullName ?? '',
        email: profile.email ?? '',
        currentAccountNumber: profile.bankakAccount?.accountNumber ?? '',
      ),
    ),
  );
}

void openPasswordSheet(BuildContext context) {
  showAdaptivePanel(
    context,
    desktopWidth: 480,
    builder: (_) => BlocProvider.value(
      value: context.read<SettingsBloc>(),
      child: const SetPasswordSheet(),
    ),
  );
}

void openLanguageSheet(BuildContext context) {
  showAdaptivePanel(
    context,
    desktopWidth: 480,
    builder: (_) => BlocProvider.value(
      value: context.read<LocaleBloc>(),
      child: const LanguagePickerSheet(),
    ),
  );
}

void selectMainFeature(BuildContext context, AppFeature feature) {
  context.read<NavigationBloc>().add(NavigationFeatureSelected(feature));
  Navigator.of(context).pop();
}

Future<void> confirmLogout(BuildContext context) async {
  final confirmed = await showDialog<bool>(
    context: context,
    barrierDismissible: true,
    builder: (_) => const SettingsLogoutDialog(),
  );

  if (confirmed == true) {
    getIt<AuthBloc>().add(const OnLogoutEvent());
  }
}
