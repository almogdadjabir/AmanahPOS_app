import 'package:amana_pos/features/users/presentation/bloc/users_bloc.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/utilities/global_snackbar.dart';
import 'package:amana_pos/widgets/field_label.dart';
import 'package:amana_pos/widgets/form_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

void showAddUserSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => BlocProvider.value(
      value: context.read<UserBloc>(),
      child: const _AddUserSheet(),
    ),
  );
}

const _kRoles = ['cashier', 'manager'];

class _AddUserSheet extends StatefulWidget {
  const _AddUserSheet();

  @override
  State<_AddUserSheet> createState() => _AddUserSheetState();
}

class _AddUserSheetState extends State<_AddUserSheet> {
  final _formKey   = GlobalKey<FormState>();
  final _nameCtrl  = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _nameFocus  = FocusNode();
  final _phoneFocus = FocusNode();

  String _selectedRole = 'cashier';

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _nameFocus.dispose();
    _phoneFocus.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    context.read<UserBloc>().add(OnAddUser(
      phone: _phoneCtrl.text.trim(),
      fullName: _nameCtrl.text.trim(),
      role: _selectedRole,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<UserBloc, UserState>(
      listenWhen: (prev, curr) => prev.submitStatus != curr.submitStatus,
      listener: (context, state) {
        if (state.submitStatus == UserSubmitStatus.success) {
          Navigator.of(context).pop();
          GlobalSnackBar.show(
            message: 'User added successfully',
            isInfo: true,
          );
        }
        if (state.submitStatus == UserSubmitStatus.failure) {
          GlobalSnackBar.show(
            message: state.submitError ?? 'Something went wrong',
            isError: true,
            isAutoDismiss: false,
          );
        }
      },
      child: Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: Container(
          decoration: BoxDecoration(
            color: context.appColors.surface,
            borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppDims.rXl)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [

              const SizedBox(height: AppDims.s3),
              Container(
                width: 36, height: 4,
                decoration: BoxDecoration(
                  color: context.appColors.border,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppDims.s4, AppDims.s4, AppDims.s4, 0),
                child: Row(
                  children: [
                    Text(
                      'New User',
                      style: AppTextStyles.bs600(context).copyWith(
                        fontWeight: FontWeight.w800,
                        color: context.appColors.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        width: 42, height: 42,
                        decoration: BoxDecoration(
                          color: context.appColors.surfaceSoft,
                          borderRadius: BorderRadius.circular(AppDims.rSm),
                        ),
                        child: Icon(Icons.close_rounded,
                            size: 24,
                            color: context.appColors.textSecondary),
                      ),
                    ),
                  ],
                ),
              ),

              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppDims.s4),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FieldLabel(label: 'Full Name', required: true),
                        const SizedBox(height: AppDims.s1),
                        AppFormField(
                          controller: _nameCtrl,
                          focusNode: _nameFocus,
                          nextFocus: _phoneFocus,
                          hint: 'Ali Hassan',
                          prefixIcon: Icons.person_outline_rounded,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Full name is required';
                            }
                            if (v.trim().length < 2) {
                              return 'Name must be at least 2 characters';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: AppDims.s3),

                        FieldLabel(label: 'Phone', required: true),
                        const SizedBox(height: AppDims.s1),
                        AppFormField(
                          controller: _phoneCtrl,
                          focusNode: _phoneFocus,
                          hint: '+249911111112',
                          prefixIcon: Icons.phone_outlined,
                          keyboardType: TextInputType.phone,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => _submit(),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Phone is required';
                            }
                            if (!RegExp(r'^\+?[0-9]{7,15}$')
                                .hasMatch(v.trim())) {
                              return 'Enter a valid phone number';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: AppDims.s4),

                        FieldLabel(label: 'Role', required: true),
                        const SizedBox(height: AppDims.s2),
                        Row(
                          children: _kRoles.map((role) {
                            final selected = _selectedRole == role;
                            final color = switch (role) {
                              'manager' => const Color(0xFF0EA5E9),
                              _=> const Color(0xFF0D9488),
                            };
                            final isLast = role == _kRoles.last;
                            return Expanded(
                              child: GestureDetector(
                                onTap: () =>
                                    setState(() => _selectedRole = role),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 150),
                                  margin: EdgeInsets.only(
                                      right: isLast ? 0 : AppDims.s2),
                                  padding: const EdgeInsets.symmetric(
                                      vertical: AppDims.s3),
                                  decoration: BoxDecoration(
                                    color: selected
                                        ? color.withValues(alpha: 0.12)
                                        : context.appColors.surfaceSoft,
                                    borderRadius:
                                    BorderRadius.circular(AppDims.rMd),
                                    border: Border.all(
                                      color: selected
                                          ? color
                                          : context.appColors.border,
                                      width: selected ? 1.5 : 1,
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      Icon(
                                        switch (role) {
                                          'manager' => Icons.manage_accounts_outlined,
                                          _ => Icons.point_of_sale_rounded,
                                        },
                                        size: 20,
                                        color: selected
                                            ? color
                                            : context.appColors.textHint,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        role,
                                        style: AppTextStyles.bs200(context).copyWith(
                                        fontWeight: FontWeight.w800,
                                          color: selected
                                              ? color
                                              : context.appColors.textHint,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),

                        const SizedBox(height: AppDims.s2),
                        _RoleHint(role: _selectedRole),
                        const SizedBox(height: AppDims.s5),

                        BlocBuilder<UserBloc, UserState>(
                          buildWhen: (prev, curr) =>
                          prev.submitStatus != curr.submitStatus,
                          builder: (context, state) {
                            final isLoading = state.submitStatus ==
                                UserSubmitStatus.loading;
                            return SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: FilledButton(
                                onPressed: isLoading ? null : _submit,
                                style: FilledButton.styleFrom(
                                  backgroundColor: context.appColors.primary,
                                  disabledBackgroundColor:
                                  context.appColors.border,
                                  shape: RoundedRectangleBorder(
                                    borderRadius:
                                    BorderRadius.circular(AppDims.rMd),
                                  ),
                                ),
                                child: isLoading
                                    ? const SizedBox(
                                  width: 20, height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Colors.white,
                                  ),
                                )
                                    : Text(
                                  'Create User',
                                  style: AppTextStyles.bs500(context).copyWith(
                                  fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


class _RoleHint extends StatelessWidget {
  final String role;
  const _RoleHint({required this.role});

  String get _hint => switch (role) {
    'manager' => 'Can view reports, manage inventory and orders.',
    _=> 'Can process sales and manage the POS terminal.',
  };

  IconData get _icon => switch (role) {
    'manager' => Icons.manage_accounts_outlined,
    _ => Icons.point_of_sale_rounded,
  };

  Color _color(BuildContext context) => switch (role) {
    'manager' => const Color(0xFF0EA5E9),
    _ => const Color(0xFF0D9488),
  };

  @override
  Widget build(BuildContext context) {
    final color = _color(context);
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: Container(
        key: ValueKey(role),
        width: double.infinity,
        padding: const EdgeInsets.all(AppDims.s3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(AppDims.rMd),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Icon(_icon, size: 16, color: color),
            const SizedBox(width: AppDims.s2),
            Expanded(
              child: Text(
                _hint,
                style: AppTextStyles.bs200(context).copyWith(
                fontWeight: FontWeight.w600,
                  color: color,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}