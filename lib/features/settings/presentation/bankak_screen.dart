import 'package:amana_pos/common/auth_bloc/auth_bloc.dart';
import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/features/settings/data/models/update_profile_request_dto.dart';
import 'package:amana_pos/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:amana_pos/features/settings/presentation/widgets/settings_widgets.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/utilities/global_snackbar.dart';
import 'package:amana_pos/widgets/app_form_group.dart';
import 'package:amana_pos/widgets/app_large_title.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Set up, change or remove the Bankak account used for Bankak sales.
class BankakScreen extends StatefulWidget {
  const BankakScreen({super.key});

  @override
  State<BankakScreen> createState() => _BankakScreenState();
}

class _BankakScreenState extends State<BankakScreen> {
  final _ctrl = TextEditingController();
  late final String _initial;
  bool _saving = false;

  bool get _has => _initial.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _initial =
        context
            .read<AuthBloc>()
            .state
            .profile
            ?.bankakAccount
            ?.accountNumber
            ?.trim() ??
        '';
    _ctrl.text = _initial;
    _ctrl.addListener(_refresh);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  bool get _canSave {
    final v = _ctrl.text.trim();
    return v != _initial && v.length >= 6 && v.length <= 20;
  }

  Future<void> _submit(String number) async {
    if (_saving) return;
    final tr = context.tr;
    final bloc = context.read<SettingsBloc>();
    final profile = context.read<AuthBloc>().state.profile;
    final email = profile?.email?.trim() ?? '';

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
          fullName: profile?.fullName ?? '',
          email: email.isEmpty ? null : email,
          bankakAccountNumber: number,
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

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            SettingsNavBar(
              backLabel: tr.mrSettings,
              actionLabel: tr.save,
              onAction: _canSave ? () => _submit(_ctrl.text.trim()) : null,
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
                    AppLargeTitle(title: tr.bkTitle),
                    AppFormGroup(
                      footer: tr.bkFoot,
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
                                    text: tr.bkAccountNumber,
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
                                  controller: _ctrl,
                                  hint: '1234 5678',
                                  numeric: true,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                    LengthLimitingTextInputFormatter(20),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (_has) ...[
                      const SizedBox(height: 22),
                      AppFormGroup(
                        children: [
                          AppFormRow(
                            onTap: _saving ? null : () => _submit(''),
                            child: Center(
                              child: Text(
                                tr.bkRemove,
                                style: TextStyle(
                                  fontSize: 17,
                                  height: 1.3,
                                  fontWeight: FontWeight.w500,
                                  color: colors.danger,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
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
