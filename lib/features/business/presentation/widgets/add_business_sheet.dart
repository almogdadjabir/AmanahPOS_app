import 'package:amana_pos/features/business/presentation/bloc/business_bloc.dart';
import 'package:amana_pos/widgets/field_label.dart';
import 'package:amana_pos/widgets/form_field.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/utilities/global_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

void showAddBusinessSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => BlocProvider.value(
      value: context.read<BusinessBloc>(),
      child: const _AddBusinessSheet(),
    ),
  );
}

class _AddBusinessSheet extends StatefulWidget {
  const _AddBusinessSheet();

  @override
  State<_AddBusinessSheet> createState() => _AddBusinessSheetState();
}

class _AddBusinessSheetState extends State<_AddBusinessSheet> {
  final _formKey = GlobalKey<FormState>();

  final _nameCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();

  final _nameFocus = FocusNode();
  final _addressFocus = FocusNode();
  final _phoneFocus = FocusNode();
  final _emailFocus = FocusNode();

  @override
  void dispose() {
    _nameCtrl.dispose(); _addressCtrl.dispose();
    _phoneCtrl.dispose(); _emailCtrl.dispose();
    _nameFocus.dispose(); _addressFocus.dispose();
    _phoneFocus.dispose(); _emailFocus.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    context.read<BusinessBloc>().add(OnAddBusiness(
      name: _nameCtrl.text.trim(),
      address: _addressCtrl.text.trim().isEmpty ? null : _addressCtrl.text.trim(),
      phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
      email: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<BusinessBloc, BusinessState>(
      listenWhen: (prev, curr) => prev.submitStatus != curr.submitStatus,
      listener: (context, state) {
        if (state.submitStatus == BusinessSubmitStatus.success) {
          Navigator.of(context).pop();
          GlobalSnackBar.show(
            message: 'Business added successfully',
            isInfo: true,);
        }

        if (state.submitStatus == BusinessSubmitStatus.failure) {
          GlobalSnackBar.show(
            message: state.submitError ?? 'Something went wrong',
            isError: true,
            isAutoDismiss: false
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
                      'New Business',
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
                            size: 24, color: context.appColors.textSecondary),
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

                        FieldLabel(label: 'Business Name', required: true),
                        const SizedBox(height: AppDims.s1),
                        AppFormField(
                          controller: _nameCtrl,
                          focusNode: _nameFocus,
                          nextFocus: _addressFocus,
                          hint: 'Amana Store',
                          prefixIcon: Icons.store_outlined,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Business name is required';
                            }
                            if (v.trim().length < 2) {
                              return 'Name must be at least 2 characters';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: AppDims.s4),

                        Row(
                          children: [
                            Expanded(child: Divider(color: context.appColors.border)),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: AppDims.s2),
                              child: Text(
                                'OPTIONAL',
                                style: AppTextStyles.bs300(context).copyWith(
                                fontWeight: FontWeight.w800,
                                  color: context.appColors.textHint,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ),
                            Expanded(child: Divider(color: context.appColors.border)),
                          ],
                        ),
                        const SizedBox(height: AppDims.s4),

                        FieldLabel(label: 'Address'),
                        const SizedBox(height: AppDims.s1),
                        AppFormField(
                          controller: _addressCtrl,
                          focusNode: _addressFocus,
                          nextFocus: _phoneFocus,
                          hint: 'Khartoum, Sudan',
                          prefixIcon: Icons.location_on_outlined,
                        ),
                        const SizedBox(height: AppDims.s3),

                        FieldLabel(label: 'Phone'),
                        const SizedBox(height: AppDims.s1),
                        AppFormField(
                          controller: _phoneCtrl,
                          focusNode: _phoneFocus,
                          nextFocus: _emailFocus,
                          hint: '+249912345678',
                          prefixIcon: Icons.phone_outlined,
                          keyboardType: TextInputType.phone,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return null;
                            if (!RegExp(r'^\+?[0-9]{7,15}$').hasMatch(v.trim())) {
                              return 'Enter a valid phone number';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: AppDims.s3),

                        FieldLabel(label: 'Email'),
                        const SizedBox(height: AppDims.s1),
                        AppFormField(
                          controller: _emailCtrl,
                          focusNode: _emailFocus,
                          hint: 'store@example.com',
                          prefixIcon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => _submit(),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return null;
                            if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v.trim())) {
                              return 'Enter a valid email';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: AppDims.s5),

                        // ── Submit ─────────────────────────────────────
                        BlocBuilder<BusinessBloc, BusinessState>(
                          buildWhen: (prev, curr) =>
                          prev.submitStatus != curr.submitStatus,
                          builder: (context, state) {
                            final isLoading = state.submitStatus ==
                                BusinessSubmitStatus.loading;
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
                                    : const Text(
                                  'Create Business',
                                  style: TextStyle(
                                    fontFamily: 'NunitoSans', fontSize: 15,
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


