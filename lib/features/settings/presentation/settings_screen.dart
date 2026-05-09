import 'package:amana_pos/common/auth_bloc/auth_bloc.dart';
import 'package:amana_pos/features/login/data/models/otp_verify_response.dart';
import 'package:amana_pos/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:amana_pos/features/settings/presentation/widgets/edit_bankak_sheet.dart';
import 'package:amana_pos/features/settings/presentation/widgets/edit_profile_sheet.dart';
import 'package:amana_pos/features/settings/presentation/widgets/owner_header.dart';
import 'package:amana_pos/features/settings/presentation/widgets/set_password_sheet.dart';
import 'package:amana_pos/features/settings/presentation/widgets/setting_section_header.dart';
import 'package:amana_pos/features/settings/presentation/widgets/settings_action_tile.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/utilities/global_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _refresh(BuildContext context) async {
    context.read<AuthBloc>().add(const OnLoadProfileEvent());
    await Future<void>.delayed(const Duration(milliseconds: 350));
  }

  void _openProfileSheet(BuildContext context, User profile) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
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

  void _openBankakSheet(BuildContext context, User profile) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
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

  void _openPasswordSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: context.read<SettingsBloc>(),
        child: const SetPasswordSheet(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<SettingsBloc, SettingsState>(
      listenWhen: (prev, curr) =>
      prev.submitStatus   != curr.submitStatus ||
          prev.passwordStatus != curr.passwordStatus,
      listener: (context, state) {
        if (state.submitStatus == SettingsSubmitStatus.success) {
          Navigator.of(context).maybePop();
          GlobalSnackBar.show(
              message: 'Settings updated successfully', isInfo: true);
        }
        if (state.submitStatus == SettingsSubmitStatus.failure) {
          GlobalSnackBar.show(
            message: state.submitError ?? 'Failed to update settings',
            isError: true,
            isAutoDismiss: false,
          );
        }
        if (state.passwordStatus == SettingsSubmitStatus.success) {
          Navigator.of(context).maybePop();
          GlobalSnackBar.show(
              message: 'Password updated successfully', isInfo: true);
        }
        if (state.passwordStatus == SettingsSubmitStatus.failure) {
          GlobalSnackBar.show(
            message: state.passwordError ?? 'Failed to update password',
            isError: true,
            isAutoDismiss: false,
          );
        }
      },
      // Profile comes from AuthBloc — single source of truth
      child: BlocBuilder<AuthBloc, AuthState>(
        buildWhen: (prev, curr) =>
        prev.profile != curr.profile ||
            prev.authStatus != curr.authStatus,
        builder: (context, authState) {
          if (authState.profile == null ||
              authState.authStatus == AuthStatus.loading) {
            return const _SettingsLoadingView();
          }


          final profile = authState.profile!;
          final permissions = authState.permissions;
          final isOwner = permissions.isOwner;

          return Scaffold(
            backgroundColor: context.appColors.background,
            body: RefreshIndicator(
              color: context.appColors.primary,
              onRefresh: () => _refresh(context),
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                slivers: [
                  const _SettingsAppBar(),

                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                        AppDims.s4, AppDims.s4, AppDims.s4, 0),
                    sliver: SliverToBoxAdapter(
                      child: OwnerHeader(
                        fullName: profile.fullName,
                        phone: profile.phone,
                        role: profile.role,
                      ),
                    ),
                  ),

                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                        AppDims.s4, AppDims.s5, AppDims.s4, AppDims.s2),
                    sliver: SliverToBoxAdapter(
                      child:  SettingSectionHeader(
                        title: 'Account',
                        subtitle: isOwner
                            ? 'Manage your profile and business payment setup.'
                            : 'Manage your name and contact details.',
                      ),

                    ),
                  ),

                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                        AppDims.s4, 0, AppDims.s4, 0),
                    sliver: SliverToBoxAdapter(
                      child: Column(
                        children: [
                          SettingsActionTile(
                            icon: Icons.person_outline_rounded,
                            iconColor: context.appColors.primary,
                            title: 'Profile',
                            subtitle: _profileSubtitle(profile),
                            trailingText: 'Edit',
                            onTap: () => _openProfileSheet(context, profile),
                          ),
                          const SizedBox(height: AppDims.s3),
                          if (isOwner) ...[
                            const SizedBox(height: AppDims.s3),
                            SettingsActionTile(
                              icon: Icons.account_balance_wallet_outlined,
                              iconColor: const Color(0xFF16A34A),
                              title: 'Bankak Payments',
                              subtitle: _bankakSubtitle(profile),
                              trailingText: _hasBankak(profile) ? 'Active' : 'Setup',
                              logoAsset: 'assets/images/bankak_logo.png',
                              onTap: () => _openBankakSheet(context, profile),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                        AppDims.s4, AppDims.s5, AppDims.s4, AppDims.s2),
                    sliver: SliverToBoxAdapter(
                      child: SettingSectionHeader(
                        title: 'Security',
                        subtitle: 'Keep your AmanaPOS owner account protected.',
                      ),
                    ),
                  ),

                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                        AppDims.s4, 0, AppDims.s4, AppDims.s6),
                    sliver: SliverToBoxAdapter(
                      child: SettingsActionTile(
                        icon: Icons.lock_outline_rounded,
                        iconColor: const Color(0xFF8B5CF6),
                        title: 'Password',
                        subtitle: 'Set or update your login password',
                        trailingText: 'Change',
                        onTap: () => _openPasswordSheet(context),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  bool _hasBankak(User profile) =>
      profile.bankakAccount?.accountNumber?.trim().isNotEmpty == true;

  String _bankakSubtitle(User profile) {
    final account = profile.bankakAccount?.accountNumber?.trim();
    if (account == null || account.isEmpty) {
      return 'Not configured. Add Bankak to accept Bankak sales.';
    }
    return 'Account ${_maskAccount(account)} is ready for POS sales.';
  }

  String _profileSubtitle(User profile) {
    final email = profile.email?.trim();
    final phone = profile.phone?.trim();
    if (email != null && email.isNotEmpty) return email;
    if (phone != null && phone.isNotEmpty) return phone;
    return 'Owner name, email and account details';
  }

  String _maskAccount(String value) {
    if (value.length <= 4) return value;
    return '•••• ${value.substring(value.length - 4)}';
  }
}

class _SettingsAppBar extends StatelessWidget {
  const _SettingsAppBar();

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      elevation: 0,
      backgroundColor: context.appColors.background,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        onPressed: () => Navigator.of(context).pop(),
        icon: Icon(
          Icons.arrow_back_rounded,
          color: context.appColors.textPrimary,
        ),
      ),
      title: Text(
        'Profile & Settings',
        style: AppTextStyles.bs600(context).copyWith(
          color: context.appColors.textPrimary,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}


class _SettingsLoadingView extends StatelessWidget {
  const _SettingsLoadingView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: CircularProgressIndicator(
        color: context.appColors.primary,
      ),
    );
  }
}

class _SettingsErrorView extends StatelessWidget {
  final String? message;
  final Future<void> Function() onRetry;

  const _SettingsErrorView({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: context.appColors.primary,
      onRefresh: onRetry,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.all(AppDims.s5),
        children: [
          const SizedBox(height: 140),
          Icon(
            Icons.cloud_off_rounded,
            size: 48,
            color: context.appColors.textHint,
          ),
          const SizedBox(height: AppDims.s3),
          Text(
            'Failed to load settings',
            textAlign: TextAlign.center,
            style: AppTextStyles.bs500(context).copyWith(
              color: context.appColors.textPrimary,
              fontWeight: FontWeight.w900,
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: AppDims.s1),
            Text(
              message!,
              textAlign: TextAlign.center,
              style: AppTextStyles.bs200(context).copyWith(
                color: context.appColors.textSecondary,
              ),
            ),
          ],
          const SizedBox(height: AppDims.s4),
          Center(
            child: OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Retry'),
            ),
          ),
        ],
      ),
    );
  }
}