import 'package:amana_pos/features/settings/data/models/set_password_request_dto.dart';
import 'package:amana_pos/features/settings/data/models/update_profile_request_dto.dart';
import 'package:amana_pos/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/utilities/global_snackbar.dart';
import 'package:amana_pos/widgets/field_label.dart';
import 'package:amana_pos/widgets/form_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  void initState() {
    super.initState();
    context.read<SettingsBloc>().add(const OnSettingsInitial());
  }

  Future<void> _refresh() async {
    context.read<SettingsBloc>().add(const OnSettingsInitial());
    await Future<void>.delayed(const Duration(milliseconds: 350));
  }

  void _openProfileSheet(SettingsState state) {
    final profile = state.profile;
    if (profile == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: context.read<SettingsBloc>(),
        child: _EditProfileSheet(
          fullName: profile.fullName ?? '',
          email: profile.email ?? '',
          bankakAccountNumber: profile.bankakAccount?.accountNumber ?? '',
        ),
      ),
    );
  }

  void _openBankakSheet(SettingsState state) {
    final profile = state.profile;
    if (profile == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: context.read<SettingsBloc>(),
        child: _EditBankakSheet(
          fullName: profile.fullName ?? '',
          email: profile.email ?? '',
          currentAccountNumber: profile.bankakAccount?.accountNumber ?? '',
        ),
      ),
    );
  }

  void _openPasswordSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: context.read<SettingsBloc>(),
        child: const _SetPasswordSheet(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SettingsBloc, SettingsState>(
      listenWhen: (prev, curr) =>
      prev.submitStatus != curr.submitStatus ||
          prev.passwordStatus != curr.passwordStatus,
      listener: (context, state) {
        if (state.submitStatus == SettingsSubmitStatus.success) {
          Navigator.of(context).maybePop();

          GlobalSnackBar.show(
            message: 'Settings updated successfully',
            isInfo: true,
          );

          context.read<SettingsBloc>().add(const OnSettingsInitial());
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
            message: 'Password updated successfully',
            isInfo: true,
          );
        }

        if (state.passwordStatus == SettingsSubmitStatus.failure) {
          GlobalSnackBar.show(
            message: state.passwordError ?? 'Failed to update password',
            isError: true,
            isAutoDismiss: false,
          );
        }
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: context.appColors.background,
          body: switch (state.status) {
            SettingsStatus.initial ||
            SettingsStatus.loading => const _SettingsLoadingView(),

            SettingsStatus.failure => _SettingsErrorView(
              message: state.responseError,
              onRetry: _refresh,
            ),

            SettingsStatus.success => RefreshIndicator(
              color: context.appColors.primary,
              onRefresh: _refresh,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                slivers: [
                  const _SettingsAppBar(),

                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      AppDims.s4,
                      AppDims.s4,
                      AppDims.s4,
                      0,
                    ),
                    sliver: SliverToBoxAdapter(
                      child: _OwnerHeader(
                        fullName: state.profile?.fullName,
                        phone: state.profile?.phone,
                      ),
                    ),
                  ),

                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      AppDims.s4,
                      AppDims.s5,
                      AppDims.s4,
                      AppDims.s2,
                    ),
                    sliver: SliverToBoxAdapter(
                      child: _SectionHeader(
                        title: 'Account',
                        subtitle: 'Manage owner profile and business payment setup.',
                      ),
                    ),
                  ),

                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      AppDims.s4,
                      0,
                      AppDims.s4,
                      0,
                    ),
                    sliver: SliverToBoxAdapter(
                      child: Column(
                        children: [
                          _SettingsActionTile(
                            icon: Icons.person_outline_rounded,
                            iconColor: context.appColors.primary,
                            title: 'Owner Profile',
                            subtitle: _profileSubtitle(state),
                            trailingText: 'Edit',
                            onTap: () => _openProfileSheet(state),
                          ),
                          const SizedBox(height: AppDims.s3),
                          _SettingsActionTile(
                            icon: Icons.account_balance_wallet_outlined,
                            iconColor: const Color(0xFF16A34A),
                            title: 'Bankak Payments',
                            subtitle: _bankakSubtitle(state),
                            trailingText: _hasBankak(state) ? 'Active' : 'Setup',
                            logoAsset: 'assets/images/bankak_logo.png',
                            onTap: () => _openBankakSheet(state),
                          ),
                        ],
                      ),
                    ),
                  ),

                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      AppDims.s4,
                      AppDims.s5,
                      AppDims.s4,
                      AppDims.s2,
                    ),
                    sliver: SliverToBoxAdapter(
                      child: _SectionHeader(
                        title: 'Security',
                        subtitle: 'Keep your AmanaPOS owner account protected.',
                      ),
                    ),
                  ),

                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      AppDims.s4,
                      0,
                      AppDims.s4,
                      AppDims.s6,
                    ),
                    sliver: SliverToBoxAdapter(
                      child: _SettingsActionTile(
                        icon: Icons.lock_outline_rounded,
                        iconColor: const Color(0xFF8B5CF6),
                        title: 'Password',
                        subtitle: 'Set or update your login password',
                        trailingText: 'Change',
                        onTap: _openPasswordSheet,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          },
        );
      },
    );
  }

  bool _hasBankak(SettingsState state) {
    return state.profile?.bankakAccount?.accountNumber?.trim().isNotEmpty == true;
  }

  String _bankakSubtitle(SettingsState state) {
    final account = state.profile?.bankakAccount?.accountNumber?.trim();

    if (account == null || account.isEmpty) {
      return 'Not configured. Add Bankak to accept Bankak sales.';
    }

    return 'Account ${_maskAccount(account)} is ready for POS sales.';
  }

  String _profileSubtitle(SettingsState state) {
    final phone = state.profile?.phone?.trim();
    final email = state.profile?.email?.trim();

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

class _OwnerHeader extends StatelessWidget {
  final String? fullName;
  final String? phone;

  const _OwnerHeader({
    this.fullName,
    this.phone,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final name = fullName?.trim().isNotEmpty == true ? fullName!.trim() : 'Owner';

    return Container(
      padding: const EdgeInsets.all(AppDims.s4),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppDims.rLg),
        border: Border.all(color: colors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: colors.primaryContainer,
            child: Text(
              name.characters.first.toUpperCase(),
              style: AppTextStyles.bs600(context).copyWith(
                color: colors.primary,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: AppDims.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bs600(context).copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  phone?.trim().isNotEmpty == true
                      ? phone!.trim()
                      : 'AmanaPOS owner account',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bs200(context).copyWith(
                    color: colors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDims.s2,
              vertical: 5,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFF16A34A).withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              'Owner',
              style: AppTextStyles.bs100(context).copyWith(
                color: const Color(0xFF16A34A),
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionHeader({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.bs500(context).copyWith(
              color: context.appColors.textPrimary,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            subtitle,
            style: AppTextStyles.bs200(context).copyWith(
              color: context.appColors.textSecondary,
              fontWeight: FontWeight.w600,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsActionTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String trailingText;
  final String? logoAsset;
  final VoidCallback onTap;

  const _SettingsActionTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.trailingText,
    required this.onTap,
    this.logoAsset,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(AppDims.rLg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDims.rLg),
        child: Container(
          padding: const EdgeInsets.all(AppDims.s4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppDims.rLg),
            border: Border.all(color: colors.border),
          ),
          child: Row(
            children: [
              _TileIcon(
                icon: icon,
                color: iconColor,
                logoAsset: logoAsset,
              ),
              const SizedBox(width: AppDims.s3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bs400(context).copyWith(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bs200(context).copyWith(
                        color: colors.textSecondary,
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppDims.s2),
              Column(
                children: [
                  Text(
                    trailingText,
                    style: AppTextStyles.bs100(context).copyWith(
                      color: colors.textHint,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: colors.textHint,
                    size: 22,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TileIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String? logoAsset;

  const _TileIcon({
    required this.icon,
    required this.color,
    this.logoAsset,
  });

  @override
  Widget build(BuildContext context) {
    if (logoAsset != null) {
      return Container(
        width: 48,
        height: 48,
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppDims.rMd),
          border: Border.all(color: context.appColors.border),
        ),
        child: Image.asset(
          logoAsset!,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) {
            return Icon(icon, color: color, size: 24);
          },
        ),
      );
    }

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppDims.rMd),
      ),
      child: Icon(
        icon,
        color: color,
        size: 24,
      ),
    );
  }
}

class _EditProfileSheet extends StatefulWidget {
  final String fullName;
  final String email;
  final String bankakAccountNumber;

  const _EditProfileSheet({
    required this.fullName,
    required this.email,
    required this.bankakAccountNumber,
  });

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _fullNameCtrl;
  late final TextEditingController _emailCtrl;

  final _fullNameFocus = FocusNode();
  final _emailFocus = FocusNode();

  @override
  void initState() {
    super.initState();

    _fullNameCtrl = TextEditingController(text: widget.fullName);
    _emailCtrl = TextEditingController(text: widget.email);
  }

  @override
  void dispose() {
    _fullNameCtrl.dispose();
    _emailCtrl.dispose();
    _fullNameFocus.dispose();
    _emailFocus.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    context.read<SettingsBloc>().add(
      OnUpdateProfile(
        dto: UpdateProfileRequestDto(
          fullName: _fullNameCtrl.text.trim(),
          email: _emailCtrl.text.trim().isEmpty
              ? null
              : _emailCtrl.text.trim(),
          bankakAccountNumber: widget.bankakAccountNumber,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _AppBottomSheet(
      title: 'Edit Owner Profile',
      subtitle: 'Update the owner information used inside AmanaPOS.',
      icon: Icons.person_outline_rounded,
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            FieldLabel(label: 'Full Name', required: true),
            const SizedBox(height: AppDims.s1),
            AppFormField(
              controller: _fullNameCtrl,
              focusNode: _fullNameFocus,
              nextFocus: _emailFocus,
              hint: 'Owner full name',
              prefixIcon: Icons.person_outline_rounded,
              validator: (v) {
                final value = v?.trim() ?? '';
                if (value.isEmpty) return 'Full name is required';
                if (value.length < 2) return 'Name is too short';
                return null;
              },
            ),
            const SizedBox(height: AppDims.s3),
            FieldLabel(label: 'Email'),
            const SizedBox(height: AppDims.s1),
            AppFormField(
              controller: _emailCtrl,
              focusNode: _emailFocus,
              hint: 'email@example.com',
              prefixIcon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(),
              validator: (v) {
                final value = v?.trim() ?? '';
                if (value.isEmpty) return null;

                final isValid = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
                    .hasMatch(value);

                if (!isValid) return 'Enter a valid email';
                return null;
              },
            ),
            const SizedBox(height: AppDims.s5),
            BlocBuilder<SettingsBloc, SettingsState>(
              buildWhen: (prev, curr) => prev.submitStatus != curr.submitStatus,
              builder: (context, state) {
                return _PrimarySheetButton(
                  label: 'Save Profile',
                  isLoading: state.submitStatus == SettingsSubmitStatus.loading,
                  onPressed: _submit,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _EditBankakSheet extends StatefulWidget {
  final String fullName;
  final String email;
  final String currentAccountNumber;

  const _EditBankakSheet({
    required this.fullName,
    required this.email,
    required this.currentAccountNumber,
  });

  @override
  State<_EditBankakSheet> createState() => _EditBankakSheetState();
}

class _EditBankakSheetState extends State<_EditBankakSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _accountCtrl;

  @override
  void initState() {
    super.initState();
    _accountCtrl = TextEditingController(text: widget.currentAccountNumber);
  }

  @override
  void dispose() {
    _accountCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    context.read<SettingsBloc>().add(
      OnUpdateProfile(
        dto: UpdateProfileRequestDto(
          fullName: widget.fullName,
          email: widget.email.trim().isEmpty ? null : widget.email.trim(),
          bankakAccountNumber: _accountCtrl.text.trim(),
        ),
      ),
    );
  }

  void _remove() {
    context.read<SettingsBloc>().add(
      OnUpdateProfile(
        dto: UpdateProfileRequestDto(
          fullName: widget.fullName,
          email: widget.email.trim().isEmpty ? null : widget.email.trim(),
          bankakAccountNumber: '',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasExisting = widget.currentAccountNumber.trim().isNotEmpty;

    return _AppBottomSheet(
      title: hasExisting ? 'Change Bankak Account' : 'Add Bankak Account',
      subtitle: 'Used when cashier selects Bankak as payment method in POS.',
      icon: Icons.account_balance_wallet_outlined,
      logoAsset: 'assets/images/bankak_logo.png',
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppDims.s3),
              decoration: BoxDecoration(
                color: context.appColors.primary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(AppDims.rMd),
                border: Border.all(
                  color: context.appColors.primary.withValues(alpha: 0.12),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    color: context.appColors.primary,
                    size: 18,
                  ),
                  const SizedBox(width: AppDims.s2),
                  Expanded(
                    child: Text(
                      'AmanaPOS will record Bankak sales under this account for reporting. The customer still pays through the Bankak app.',
                      style: AppTextStyles.bs200(context).copyWith(
                        color: context.appColors.textSecondary,
                        fontWeight: FontWeight.w700,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppDims.s4),
            FieldLabel(label: 'Bankak Account Number', required: true),
            const SizedBox(height: AppDims.s1),
            AppFormField(
              controller: _accountCtrl,
              hint: 'Example: 1234567890',
              prefixIcon: Icons.numbers_rounded,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(),
              validator: (v) {
                final value = v?.trim() ?? '';

                if (value.isEmpty) return 'Bankak account number is required';
                if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
                  return 'Only numbers are allowed';
                }
                if (value.length < 6) return 'Account number is too short';
                if (value.length > 20) return 'Account number is too long';

                return null;
              },
            ),
            const SizedBox(height: AppDims.s5),
            BlocBuilder<SettingsBloc, SettingsState>(
              buildWhen: (prev, curr) => prev.submitStatus != curr.submitStatus,
              builder: (context, state) {
                final isLoading =
                    state.submitStatus == SettingsSubmitStatus.loading;

                return Row(
                  children: [
                    if (hasExisting) ...[
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: isLoading ? null : _remove,
                          icon: const Icon(Icons.delete_outline_rounded),
                          label: const Text('Remove'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFDC2626),
                            side: BorderSide(
                              color: const Color(0xFFDC2626)
                                  .withValues(alpha: 0.35),
                            ),
                            minimumSize: const Size(0, 50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppDims.rMd),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppDims.s3),
                    ],
                    Expanded(
                      flex: 2,
                      child: _PrimarySheetButton(
                        label: hasExisting ? 'Save Changes' : 'Add Account',
                        isLoading: isLoading,
                        onPressed: _submit,
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _SetPasswordSheet extends StatefulWidget {
  const _SetPasswordSheet();

  @override
  State<_SetPasswordSheet> createState() => _SetPasswordSheetState();
}

class _SetPasswordSheetState extends State<_SetPasswordSheet> {
  final _formKey = GlobalKey<FormState>();

  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  final _passwordFocus = FocusNode();
  final _confirmFocus = FocusNode();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    _passwordFocus.dispose();
    _confirmFocus.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    context.read<SettingsBloc>().add(
      OnSetPassword(
        dto: SetPasswordRequestDto(
          password: _passwordCtrl.text,
          passwordConfirm: _confirmCtrl.text,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _AppBottomSheet(
      title: 'Set Password',
      subtitle: 'Use a strong password to protect your AmanaPOS account.',
      icon: Icons.lock_outline_rounded,
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            FieldLabel(label: 'New Password', required: true),
            const SizedBox(height: AppDims.s1),
            _PasswordField(
              controller: _passwordCtrl,
              focusNode: _passwordFocus,
              nextFocus: _confirmFocus,
              hint: 'New password',
              obscureText: _obscurePassword,
              onToggle: () {
                setState(() => _obscurePassword = !_obscurePassword);
              },
              validator: (v) {
                final value = v ?? '';

                if (value.isEmpty) return 'Password is required';
                if (value.length < 8) {
                  return 'Password must be at least 8 characters';
                }

                return null;
              },
            ),
            const SizedBox(height: AppDims.s3),
            FieldLabel(label: 'Confirm Password', required: true),
            const SizedBox(height: AppDims.s1),
            _PasswordField(
              controller: _confirmCtrl,
              focusNode: _confirmFocus,
              hint: 'Confirm password',
              obscureText: _obscureConfirm,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(),
              onToggle: () {
                setState(() => _obscureConfirm = !_obscureConfirm);
              },
              validator: (v) {
                final value = v ?? '';

                if (value.isEmpty) return 'Please confirm password';
                if (value != _passwordCtrl.text) {
                  return 'Passwords do not match';
                }

                return null;
              },
            ),
            const SizedBox(height: AppDims.s5),
            BlocBuilder<SettingsBloc, SettingsState>(
              buildWhen: (prev, curr) =>
              prev.passwordStatus != curr.passwordStatus,
              builder: (context, state) {
                return _PrimarySheetButton(
                  label: 'Update Password',
                  isLoading:
                  state.passwordStatus == SettingsSubmitStatus.loading,
                  onPressed: _submit,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _AppBottomSheet extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Widget child;
  final String? logoAsset;

  const _AppBottomSheet({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.child,
    this.logoAsset,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.90,
        ),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppDims.rXl),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: AppDims.s3),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: colors.border,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppDims.s4,
                AppDims.s4,
                AppDims.s4,
                AppDims.s2,
              ),
              child: Row(
                children: [
                  _SheetIcon(
                    icon: icon,
                    logoAsset: logoAsset,
                  ),
                  const SizedBox(width: AppDims.s3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: AppTextStyles.bs600(context).copyWith(
                            color: colors.textPrimary,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          subtitle,
                          style: AppTextStyles.bs200(context).copyWith(
                            color: colors.textSecondary,
                            fontWeight: FontWeight.w600,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(
                      Icons.close_rounded,
                      color: colors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  AppDims.s4,
                  AppDims.s2,
                  AppDims.s4,
                  AppDims.s4,
                ),
                child: child,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SheetIcon extends StatelessWidget {
  final IconData icon;
  final String? logoAsset;

  const _SheetIcon({
    required this.icon,
    this.logoAsset,
  });

  @override
  Widget build(BuildContext context) {
    if (logoAsset != null) {
      return Container(
        width: 46,
        height: 46,
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppDims.rMd),
          border: Border.all(color: context.appColors.border),
        ),
        child: Image.asset(
          logoAsset!,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) {
            return Icon(
              icon,
              color: context.appColors.primary,
              size: 24,
            );
          },
        ),
      );
    }

    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: context.appColors.primary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppDims.rMd),
      ),
      child: Icon(
        icon,
        color: context.appColors.primary,
        size: 23,
      ),
    );
  }
}

class _PrimarySheetButton extends StatelessWidget {
  final String label;
  final bool isLoading;
  final VoidCallback onPressed;

  const _PrimarySheetButton({
    required this.label,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: FilledButton(
        onPressed: isLoading ? null : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: context.appColors.primary,
          disabledBackgroundColor: context.appColors.border,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDims.rMd),
          ),
        ),
        child: isLoading
            ? const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            color: Colors.white,
          ),
        )
            : Text(
          label,
          style: AppTextStyles.bs500(context).copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _PasswordField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final FocusNode? nextFocus;
  final String hint;
  final bool obscureText;
  final VoidCallback onToggle;
  final String? Function(String?)? validator;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onSubmitted;

  const _PasswordField({
    required this.controller,
    required this.hint,
    required this.obscureText,
    required this.onToggle,
    this.focusNode,
    this.nextFocus,
    this.validator,
    this.textInputAction = TextInputAction.next,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      obscureText: obscureText,
      validator: validator,
      textInputAction: textInputAction,
      onFieldSubmitted: onSubmitted ?? (_) => nextFocus?.requestFocus(),
      style: AppTextStyles.bs500(context).copyWith(
        fontWeight: FontWeight.w600,
        color: colors.textPrimary,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AppTextStyles.bs400(context).copyWith(
          color: colors.textHint,
        ),
        prefixIcon: Icon(
          Icons.lock_outline_rounded,
          size: 18,
          color: colors.textHint,
        ),
        suffixIcon: IconButton(
          onPressed: onToggle,
          icon: Icon(
            obscureText
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            size: 18,
            color: colors.textHint,
          ),
        ),
        filled: true,
        fillColor: colors.surfaceSoft,
        errorMaxLines: 2,
        errorStyle: AppTextStyles.sm200(context).copyWith(
          fontWeight: FontWeight.w600,
          color: colors.danger,
          height: 1.3,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDims.rMd),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDims.rMd),
          borderSide: BorderSide(color: colors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDims.rMd),
          borderSide: BorderSide(color: colors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDims.rMd),
          borderSide: BorderSide(color: colors.danger, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDims.rMd),
          borderSide: BorderSide(color: colors.danger, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppDims.s3,
          vertical: AppDims.s3,
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