import 'package:amana_pos/features/business/data/models/responses/business_response_dto.dart';
import 'package:amana_pos/features/business/presentation/bloc/business_bloc.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/utilities/global_snackbar.dart';
import 'package:amana_pos/widgets/field_label.dart';
import 'package:amana_pos/widgets/form_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

void showEditShopSheet(
    BuildContext context, {
      required String businessId,
      required Shops shop,
    }) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => BlocProvider.value(
      value: context.read<BusinessBloc>(),
      child: _EditShopSheet(businessId: businessId, shop: shop),
    ),
  );
}

class _EditShopSheet extends StatefulWidget {
  final String businessId;
  final Shops shop;
  const _EditShopSheet({required this.businessId, required this.shop});

  @override
  State<_EditShopSheet> createState() => _EditShopSheetState();
}

class _EditShopSheetState extends State<_EditShopSheet> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameCtrl;
  late final TextEditingController _addressCtrl;
  late final TextEditingController _phoneCtrl;

  final _nameFocus    = FocusNode();
  final _addressFocus = FocusNode();
  final _phoneFocus   = FocusNode();

  bool get _hasChanges =>
      _nameCtrl.text.trim()    != (widget.shop.name    ?? '') ||
          _addressCtrl.text.trim() != (widget.shop.address ?? '') ||
          _phoneCtrl.text.trim()   != (widget.shop.phone   ?? '');

  @override
  void initState() {
    super.initState();
    _nameCtrl    = TextEditingController(text: widget.shop.name    ?? '');
    _addressCtrl = TextEditingController(text: widget.shop.address ?? '');
    _phoneCtrl   = TextEditingController(text: widget.shop.phone   ?? '');

    for (final c in [_nameCtrl, _addressCtrl, _phoneCtrl]) {
      c.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); _addressCtrl.dispose(); _phoneCtrl.dispose();
    _nameFocus.dispose(); _addressFocus.dispose(); _phoneFocus.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (!_hasChanges) return;
    context.read<BusinessBloc>().add(OnEditShop(
      businessId: widget.businessId,
      shopId:     widget.shop.id!,
      name:       _nameCtrl.text.trim(),
      address:    _addressCtrl.text.trim().isEmpty ? null : _addressCtrl.text.trim(),
      phone:      _phoneCtrl.text.trim().isEmpty   ? null : _phoneCtrl.text.trim(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<BusinessBloc, BusinessState>(
      listenWhen: (prev, curr) => prev.submitStatus != curr.submitStatus,
      listener: (context, state) {
        if (state.submitStatus == BusinessSubmitStatus.success) {
          Navigator.of(context).pop();
          GlobalSnackBar.show(message: 'Shop updated', isInfo: true);
        }
        if (state.submitStatus == BusinessSubmitStatus.failure) {
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
              // ── Handle ────────────────────────────────────────────────
              const SizedBox(height: AppDims.s3),
              Container(
                width: 36, height: 4,
                decoration: BoxDecoration(
                  color: context.appColors.border,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),

              // ── Header ────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppDims.s4, AppDims.s4, AppDims.s4, 0),
                child: Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Edit Shop',
                          style: AppTextStyles.bs600(context).copyWith(
                            fontWeight: FontWeight.w800,
                            color: context.appColors.textPrimary,
                          ),
                        ),
                        Text(
                          widget.shop.name ?? '',
                          style: AppTextStyles.bs300(context).copyWith(
                            color: context.appColors.textHint,
                          ),
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

              // ── Form ──────────────────────────────────────────────────
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppDims.s4),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FieldLabel(label: 'Shop Name', required: true),
                        const SizedBox(height: AppDims.s1),
                        AppFormField(
                          controller: _nameCtrl,
                          focusNode: _nameFocus,
                          nextFocus: _addressFocus,
                          hint: 'Main Branch',
                          prefixIcon: Icons.storefront_outlined,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Shop name is required';
                            }
                            if (v.trim().length < 2) {
                              return 'Name must be at least 2 characters';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: AppDims.s3),

                        FieldLabel(label: 'Address'),
                        const SizedBox(height: AppDims.s1),
                        AppFormField(
                          controller: _addressCtrl,
                          focusNode: _addressFocus,
                          nextFocus: _phoneFocus,
                          hint: 'Khartoum Centre',
                          prefixIcon: Icons.location_on_outlined,
                        ),
                        const SizedBox(height: AppDims.s3),

                        FieldLabel(label: 'Phone'),
                        const SizedBox(height: AppDims.s1),
                        AppFormField(
                          controller: _phoneCtrl,
                          focusNode: _phoneFocus,
                          hint: '+249912345678',
                          prefixIcon: Icons.phone_outlined,
                          keyboardType: TextInputType.phone,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => _submit(),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return null;
                            if (!RegExp(r'^\+?[0-9]{7,15}$')
                                .hasMatch(v.trim())) {
                              return 'Enter a valid phone number';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: AppDims.s5),

                        // ── Submit ──────────────────────────────────────
                        BlocBuilder<BusinessBloc, BusinessState>(
                          buildWhen: (prev, curr) =>
                          prev.submitStatus != curr.submitStatus,
                          builder: (context, state) {
                            final isLoading = state.submitStatus ==
                                BusinessSubmitStatus.loading;
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