import 'package:amana_pos/features/users/data/models/responses/user_response_dto.dart';
import 'package:amana_pos/features/users/presentation/bloc/users_bloc.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/utilities/global_snackbar.dart';
import 'package:amana_pos/widgets/field_label.dart';
import 'package:amana_pos/widgets/form_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

void showEditUserSheet(BuildContext context, {required UserData user}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => BlocProvider.value(
      value: context.read<UserBloc>(),
      child: _EditUserSheet(user: user),
    ),
  );
}

// Roles the API accepts
const _kRoles = ['cashier', 'manager', 'admin'];

class _EditUserSheet extends StatefulWidget {
  final UserData user;
  const _EditUserSheet({required this.user});

  @override
  State<_EditUserSheet> createState() => _EditUserSheetState();
}

class _EditUserSheetState extends State<_EditUserSheet> {
  final _formKey   = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late String _selectedRole;

  bool get _hasChanges =>
      _nameCtrl.text.trim() != (widget.user.fullName ?? '') ||
          _selectedRole != (widget.user.role ?? '');

  @override
  void initState() {
    super.initState();
    _nameCtrl     = TextEditingController(text: widget.user.fullName ?? '');
    _selectedRole = widget.user.role ?? 'cashier';
    _nameCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (!_hasChanges) return;
    context.read<UserBloc>().add(OnEditUser(
      userId:   widget.user.id!,
      fullName: _nameCtrl.text.trim(),
      role:     _selectedRole,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<UserBloc, UserState>(
      listenWhen: (prev, curr) => prev.submitStatus != curr.submitStatus,
      listener: (context, state) {
        if (state.submitStatus == UserSubmitStatus.success) {
          Navigator.of(context).pop();
          GlobalSnackBar.show(message: 'User updated', isInfo: true);
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
              // ── Handle ──────────────────────────────────────────────
              const SizedBox(height: AppDims.s3),
              Container(
                width: 36, height: 4,
                decoration: BoxDecoration(
                  color: context.appColors.border,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),

              // ── Header ───────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppDims.s4, AppDims.s4, AppDims.s4, 0),
                child: Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Edit User',
                          style: AppTextStyles.bs600(context).copyWith(
                            fontWeight: FontWeight.w800,
                            color: context.appColors.textPrimary,
                          ),
                        ),
                        Text(
                          widget.user.fullName ?? '',
                          style: AppTextStyles.bs300(context)
                              .copyWith(color: context.appColors.textHint),
                        ),
                      ],
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

              // ── Form ─────────────────────────────────────────────────
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppDims.s4),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Full name ──────────────────────────────────
                        FieldLabel(label: 'Full Name', required: true),
                        const SizedBox(height: AppDims.s1),
                        AppFormField(
                          controller: _nameCtrl,
                          hint: 'Ali Hassan',
                          prefixIcon: Icons.person_outline_rounded,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Name is required';
                            }
                            if (v.trim().length < 2) {
                              return 'Name must be at least 2 characters';
                            }
                            return null;
                          }, focusNode: null,
                        ),
                        const SizedBox(height: AppDims.s4),

                        // ── Role picker ────────────────────────────────
                        FieldLabel(label: 'Role', required: true),
                        const SizedBox(height: AppDims.s2),
                        Row(
                          children: _kRoles.map((role) {
                            final selected = _selectedRole == role;
                            final color = switch (role) {
                              'admin'   => const Color(0xFF8B5CF6),
                              'manager' => const Color(0xFF0EA5E9),
                              _         => const Color(0xFF0D9488),
                            };
                            return Expanded(
                              child: GestureDetector(
                                onTap: () =>
                                    setState(() => _selectedRole = role),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 150),
                                  margin: EdgeInsets.only(
                                    right: role != _kRoles.last
                                        ? AppDims.s2
                                        : 0,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                      vertical: AppDims.s3),
                                  decoration: BoxDecoration(
                                    color: selected
                                        ? color.withOpacity(0.12)
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
                                          'admin'   => Icons.shield_outlined,
                                          'manager' => Icons.manage_accounts_outlined,
                                          _         => Icons.point_of_sale_rounded,
                                        },
                                        size: 20,
                                        color: selected
                                            ? color
                                            : context.appColors.textHint,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        role,
                                        style: TextStyle(
                                          fontFamily: 'NunitoSans',
                                          fontSize: 11,
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
                        const SizedBox(height: AppDims.s5),

                        // ── Submit ──────────────────────────────────────
                        BlocBuilder<UserBloc, UserState>(
                          buildWhen: (prev, curr) =>
                          prev.submitStatus != curr.submitStatus,
                          builder: (context, state) {
                            final isLoading = state.submitStatus ==
                                UserSubmitStatus.loading;
                            final canSave = _hasChanges && !isLoading;

                            return SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: FilledButton(
                                onPressed: canSave ? _submit : null,
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
                                  'Save Changes',
                                  style: TextStyle(
                                    fontFamily: 'NunitoSans',
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    color: canSave
                                        ? Colors.white
                                        : context.appColors.textHint,
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