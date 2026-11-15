import 'package:amana_pos/common/auth_bloc/auth_bloc.dart';
import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/features/products/presentation/widgets/product_form_widgets.dart';
import 'package:amana_pos/features/settings/data/models/update_profile_request_dto.dart';
import 'package:amana_pos/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/theme/phosphor_icons.dart';
import 'package:amana_pos/utilities/extension.dart';
import 'package:amana_pos/utilities/global_snackbar.dart';
import 'package:amana_pos/widgets/app_form_group.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Edit your name and email. Phone and role are read-only: sign-in is tied
/// to the phone number.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  late final String _initialName;
  late final String _initialEmail;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final profile = context.read<AuthBloc>().state.profile;
    _initialName = profile?.fullName?.trim() ?? '';
    _initialEmail = profile?.email?.trim() ?? '';
    _nameCtrl.text = _initialName;
    _emailCtrl.text = _initialEmail;
    _nameCtrl.addListener(_refresh);
    _emailCtrl.addListener(_refresh);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  bool get _canSave {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return false;
    return name != _initialName || _emailCtrl.text.trim() != _initialEmail;
  }

  Future<void> _save() async {
    if (_saving || !_canSave) return;
    final tr = context.tr;
    final bloc = context.read<SettingsBloc>();
    final bankak = context
        .read<AuthBloc>()
        .state
        .profile
        ?.bankakAccount
        ?.accountNumber;

    FocusScope.of(context).unfocus();
    setState(() => _saving = true);
    final result = bloc.stream.firstWhere(
      (s) =>
          s.submitStatus == SettingsSubmitStatus.success ||
          s.submitStatus == SettingsSubmitStatus.failure,
    );
    bloc.add(
      OnUpdateProfile(
        dto: UpdateProfileRequestDto(
          fullName: _nameCtrl.text.trim(),
          email: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
          bankakAccountNumber: bankak,
        ),
      ),
    );
    final state = await result;
    if (!mounted) return;

    if (state.submitStatus == SettingsSubmitStatus.success) {
      Navigator.of(context).pop();
      GlobalSnackBar.show(message: tr.profileUpdatedSuccess, isInfo: true);
      return;
    }

    setState(() => _saving = false);
    GlobalSnackBar.show(
      message: state.submitError ?? tr.profileUpdateFailed,
      isError: true,
      isAutoDismiss: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final tr = context.tr;
    final profile = context.read<AuthBloc>().state.profile;
    final perms = context.read<AuthBloc>().state.permissions;
    final name = _nameCtrl.text.trim();
    final role = perms.isOwner
        ? tr.mrRoleOwner
        : perms.isManager
        ? tr.mrRoleManager
        : tr.mrRoleCashier;

    Widget lock() =>
        Icon(PhosphorIconsRegular.lock, size: 16, color: colors.textHint);

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            FormNavBar(
              title: tr.prfTitle,
              onCancel: () => Navigator.of(context).maybePop(),
              onSave: _canSave ? _save : null,
              saving: _saving,
            ),
            Expanded(
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: EdgeInsets.fromLTRB(
                  AppDims.s4,
                  0,
                  AppDims.s4,
                  AppDims.s8 + MediaQuery.viewPaddingOf(context).bottom,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 6, bottom: 12),
                      child: Center(
                        child: Container(
                          width: 84,
                          height: 84,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: colors.primaryContainer,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            name.isEmpty ? '?' : name.initials,
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w600,
                              color: colors.primary,
                            ),
                          ),
                        ),
                      ),
                    ),
                    AppFormGroup(
                      children: [
                        AppFormRow(
                          child: Row(
                            children: [
                              ConstrainedBox(
                                constraints: const BoxConstraints(
                                  minWidth: 104,
                                ),
                                child: Text.rich(
                                  TextSpan(
                                    text: tr.prfFullName,
                                    children: [
                                      TextSpan(
                                        text: '*',
                                        style: TextStyle(color: colors.danger),
                                      ),
                                    ],
                                  ),
                                  maxLines: 1,
                                  softWrap: false,
                                  style: TextStyle(
                                    fontSize: 17,
                                    color: colors.textPrimary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppDims.s2),
                              Expanded(
                                child: AppRowTextField(
                                  controller: _nameCtrl,
                                  hint: tr.prfFullName,
                                  textCapitalization: TextCapitalization.words,
                                ),
                              ),
                            ],
                          ),
                        ),
                        AppFormRow(
                          label: tr.prfEmail,
                          child: AppRowTextField(
                            controller: _emailCtrl,
                            hint: tr.fmOptional,
                            numeric: true,
                            keyboardType: TextInputType.emailAddress,
                            textCapitalization: TextCapitalization.none,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    AppFormGroup(
                      footer: tr.prfPhoneFoot,
                      children: [
                        AppFormRow(
                          label: tr.prfPhone,
                          child: Row(
                            children: [
                              Expanded(
                                child: AppRowValue(
                                  profile?.phone?.trim() ?? '',
                                  numeric: true,
                                ),
                              ),
                              const SizedBox(width: 8),
                              lock(),
                            ],
                          ),
                        ),
                        AppFormRow(
                          label: tr.prfRole,
                          child: Row(
                            children: [
                              Expanded(child: AppRowValue(role)),
                              const SizedBox(width: 8),
                              lock(),
                            ],
                          ),
                        ),
                      ],
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
}
