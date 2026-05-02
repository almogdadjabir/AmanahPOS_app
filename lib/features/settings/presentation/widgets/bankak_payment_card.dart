import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/widgets/field_label.dart';
import 'package:amana_pos/widgets/form_field.dart';
import 'package:flutter/material.dart';

class BankakPaymentCard extends StatefulWidget {
  final TextEditingController controller;

  const BankakPaymentCard({
    super.key,
    required this.controller,
  });

  @override
  State<BankakPaymentCard> createState() => _BankakPaymentCardState();
}

class _BankakPaymentCardState extends State<BankakPaymentCard> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    super.dispose();
  }

  void _onControllerChanged() {
    if (mounted) setState(() {});
  }

  void _openBankakSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return _BankakAccountSheet(
          initialValue: widget.controller.text,
          onSave: (value) {
            widget.controller.text = value;
          },
          onRemove: () {
            widget.controller.clear();
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final account = widget.controller.text.trim();
    final hasAccount = account.isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDims.s4),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppDims.rLg),
        border: Border.all(
          color: hasAccount
              ? const Color(0xFF16A34A).withValues(alpha: 0.35)
              : colors.border,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              const _BankakLogo(),
              const SizedBox(width: AppDims.s3),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bankak Payments',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bs500(context).copyWith(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      hasAccount
                          ? 'Ready to accept Bankak sales'
                          : 'Accept Bankak payments in POS',
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

              _StatusPill(configured: hasAccount),
            ],
          ),

          const SizedBox(height: AppDims.s4),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppDims.s3),
            decoration: BoxDecoration(
              color: colors.surfaceSoft,
              borderRadius: BorderRadius.circular(AppDims.rMd),
            ),
            child: Row(
              children: [
                Icon(
                  hasAccount
                      ? Icons.account_balance_wallet_outlined
                      : Icons.info_outline_rounded,
                  size: 20,
                  color: hasAccount
                      ? const Color(0xFF16A34A)
                      : colors.textHint,
                ),
                const SizedBox(width: AppDims.s2),
                Expanded(
                  child: Text(
                    hasAccount
                        ? 'Account ${_maskAccount(account)}'
                        : 'No Bankak account added yet',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bs300(context).copyWith(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppDims.s3),

          SizedBox(
            width: double.infinity,
            height: 46,
            child: hasAccount
                ? OutlinedButton.icon(
              onPressed: _openBankakSheet,
              icon: const Icon(Icons.edit_rounded, size: 18),
              label: const Text('Change Bankak Account'),
              style: OutlinedButton.styleFrom(
                foregroundColor: colors.textPrimary,
                side: BorderSide(color: colors.border),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDims.rMd),
                ),
                textStyle: AppTextStyles.bs300(context).copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
            )
                : FilledButton.icon(
              onPressed: _openBankakSheet,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Add Bankak Account'),
              style: FilledButton.styleFrom(
                backgroundColor: colors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDims.rMd),
                ),
                textStyle: AppTextStyles.bs300(context).copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _maskAccount(String value) {
    if (value.length <= 4) return value;
    return '•••• ${value.substring(value.length - 4)}';
  }
}

class _BankakLogo extends StatelessWidget {
  const _BankakLogo();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 54,
      height: 54,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDims.rMd),
        border: Border.all(color: context.appColors.border),
      ),
      child: Image.asset(
        'assets/images/bankak_logo.png',
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) {
          return Icon(
            Icons.account_balance_wallet_outlined,
            color: context.appColors.primary,
            size: 28,
          );
        },
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final bool configured;

  const _StatusPill({
    required this.configured,
  });

  @override
  Widget build(BuildContext context) {
    final color = configured
        ? const Color(0xFF16A34A)
        : context.appColors.textHint;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDims.s2,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        configured ? 'Active' : 'Not set',
        maxLines: 1,
        style: AppTextStyles.bs100(context).copyWith(
          color: color,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _BankakAccountSheet extends StatefulWidget {
  final String initialValue;
  final ValueChanged<String> onSave;
  final VoidCallback onRemove;

  const _BankakAccountSheet({
    required this.initialValue,
    required this.onSave,
    required this.onRemove,
  });

  @override
  State<_BankakAccountSheet> createState() => _BankakAccountSheetState();
}

class _BankakAccountSheetState extends State<_BankakAccountSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _accountCtrl;

  @override
  void initState() {
    super.initState();
    _accountCtrl = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _accountCtrl.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    widget.onSave(_accountCtrl.text.trim());
    Navigator.of(context).pop();
  }

  void _remove() {
    widget.onRemove();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final hasExisting = widget.initialValue.trim().isNotEmpty;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          AppDims.s4,
          AppDims.s3,
          AppDims.s4,
          AppDims.s4,
        ),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppDims.rXl),
          ),
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colors.border,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),

              const SizedBox(height: AppDims.s4),

              Row(
                children: [
                  const _BankakLogo(),
                  const SizedBox(width: AppDims.s3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          hasExisting
                              ? 'Update Bankak Account'
                              : 'Add Bankak Account',
                          style: AppTextStyles.bs600(context).copyWith(
                            color: colors.textPrimary,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Used for Bankak sales tracking and reports.',
                          style: AppTextStyles.bs200(context).copyWith(
                            color: colors.textSecondary,
                            fontWeight: FontWeight.w600,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppDims.s4),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppDims.s3),
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(AppDims.rMd),
                  border: Border.all(
                    color: colors.primary.withValues(alpha: 0.12),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      size: 18,
                      color: colors.primary,
                    ),
                    const SizedBox(width: AppDims.s2),
                    Expanded(
                      child: Text(
                        'When cashier chooses Bankak in POS, AmanaPOS records the sale under this account.',
                        style: AppTextStyles.bs200(context).copyWith(
                          color: colors.textSecondary,
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
                onSubmitted: (_) => _save(),
                validator: (v) {
                  final value = v?.trim() ?? '';

                  if (value.isEmpty) {
                    return 'Bankak account number is required';
                  }

                  if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
                    return 'Only numbers are allowed';
                  }

                  if (value.length < 6) {
                    return 'Account number is too short';
                  }

                  if (value.length > 20) {
                    return 'Account number is too long';
                  }

                  return null;
                },
              ),

              const SizedBox(height: AppDims.s4),

              Row(
                children: [
                  if (hasExisting) ...[
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _remove,
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
                    child: FilledButton(
                      onPressed: _save,
                      style: FilledButton.styleFrom(
                        backgroundColor: colors.primary,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(0, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppDims.rMd),
                        ),
                      ),
                      child: Text(
                        hasExisting ? 'Save Changes' : 'Add Account',
                        style: AppTextStyles.bs500(context).copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppDims.s2),
            ],
          ),
        ),
      ),
    );
  }
}