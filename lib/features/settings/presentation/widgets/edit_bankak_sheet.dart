import 'package:amana_pos/features/settings/data/models/update_profile_request_dto.dart';
import 'package:amana_pos/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:amana_pos/features/settings/presentation/widgets/app_bottom_sheet.dart';
import 'package:amana_pos/features/settings/presentation/widgets/primary_sheet_button.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/widgets/field_label.dart';
import 'package:amana_pos/widgets/form_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';


class EditBankakSheet extends StatefulWidget {
  final String fullName;
  final String email;
  final String currentAccountNumber;

  const EditBankakSheet({super.key,
    required this.fullName,
    required this.email,
    required this.currentAccountNumber,
  });

  @override
  State<EditBankakSheet> createState() => _EditBankakSheetState();
}

class _EditBankakSheetState extends State<EditBankakSheet> {
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

    return AppBottomSheet(
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
                      child: PrimarySheetButton(
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