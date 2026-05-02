import 'package:amana_pos/features/customers/data/models/requests/customer_request_dto.dart';
import 'package:amana_pos/features/customers/data/models/responses/customer_response_dto.dart';
import 'package:amana_pos/features/customers/presentation/bloc/customers_bloc.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/widgets/field_label.dart';
import 'package:amana_pos/widgets/form_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

void showCustomerFormSheet(
    BuildContext context, {
      CustomerData? customer,
    }) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => BlocProvider.value(
      value: context.read<CustomersBloc>(),
      child: _CustomerFormSheet(customer: customer),
    ),
  );
}

class _CustomerFormSheet extends StatefulWidget {
  final CustomerData? customer;

  const _CustomerFormSheet({
    this.customer,
  });

  @override
  State<_CustomerFormSheet> createState() => _CustomerFormSheetState();
}

class _CustomerFormSheetState extends State<_CustomerFormSheet> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _addressCtrl;
  late final TextEditingController _notesCtrl;
  late final TextEditingController _pointsCtrl;

  final _nameFocus = FocusNode();
  final _phoneFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _addressFocus = FocusNode();
  final _notesFocus = FocusNode();
  final _pointsFocus = FocusNode();

  bool get _isEdit => widget.customer != null;

  @override
  void initState() {
    super.initState();

    final c = widget.customer;

    _nameCtrl = TextEditingController(text: c?.name ?? '');
    _phoneCtrl = TextEditingController(text: c?.phone ?? '');
    _emailCtrl = TextEditingController(text: c?.email ?? '');
    _addressCtrl = TextEditingController(text: c?.address ?? '');
    _notesCtrl = TextEditingController(text: c?.notes ?? '');
    _pointsCtrl = TextEditingController(
      text: c?.loyaltyPoints?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _addressCtrl.dispose();
    _notesCtrl.dispose();
    _pointsCtrl.dispose();

    _nameFocus.dispose();
    _phoneFocus.dispose();
    _emailFocus.dispose();
    _addressFocus.dispose();
    _notesFocus.dispose();
    _pointsFocus.dispose();

    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final dto = CustomerRequestDto(
      name: _nameCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      email: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
      address:
      _addressCtrl.text.trim().isEmpty ? null : _addressCtrl.text.trim(),
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      loyaltyPoints: _pointsCtrl.text.trim().isEmpty
          ? null
          : int.tryParse(_pointsCtrl.text.trim()),
    );

    if (_isEdit) {
      final customerId = widget.customer?.id;
      if (customerId == null) return;

      context.read<CustomersBloc>().add(
        OnUpdateCustomer(
          customerId: customerId,
          dto: dto,
        ),
      );
      return;
    }

    context.read<CustomersBloc>().add(
      OnCreateCustomer(dto: dto),
    );
  }

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
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: colors.primary.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(AppDims.rMd),
                    ),
                    child: Icon(
                      _isEdit
                          ? Icons.edit_outlined
                          : Icons.person_add_alt_rounded,
                      color: colors.primary,
                    ),
                  ),
                  const SizedBox(width: AppDims.s3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isEdit ? 'Edit Customer' : 'Add Customer',
                          style: AppTextStyles.bs600(context).copyWith(
                            color: colors.textPrimary,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          _isEdit
                              ? 'Update customer details and loyalty points.'
                              : 'Create a customer profile for sales and loyalty.',
                          style: AppTextStyles.bs200(context).copyWith(
                            color: colors.textSecondary,
                            fontWeight: FontWeight.w600,
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
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      FieldLabel(label: 'Customer Name', required: true),
                      const SizedBox(height: AppDims.s1),
                      AppFormField(
                        controller: _nameCtrl,
                        focusNode: _nameFocus,
                        nextFocus: _phoneFocus,
                        hint: 'Sara Ali',
                        prefixIcon: Icons.person_outline_rounded,
                        validator: (v) {
                          final value = v?.trim() ?? '';
                          if (value.isEmpty) return 'Name is required';
                          if (value.length < 2) return 'Name is too short';
                          return null;
                        },
                      ),

                      const SizedBox(height: AppDims.s3),

                      FieldLabel(label: 'Phone', required: true),
                      const SizedBox(height: AppDims.s1),
                      AppFormField(
                        controller: _phoneCtrl,
                        focusNode: _phoneFocus,
                        nextFocus: _emailFocus,
                        hint: '+249922222222',
                        prefixIcon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                        validator: (v) {
                          final value = v?.trim() ?? '';
                          if (value.isEmpty) return 'Phone is required';
                          if (value.length < 8) return 'Invalid phone number';
                          return null;
                        },
                      ),

                      const SizedBox(height: AppDims.s3),

                      FieldLabel(label: 'Email'),
                      const SizedBox(height: AppDims.s1),
                      AppFormField(
                        controller: _emailCtrl,
                        focusNode: _emailFocus,
                        nextFocus: _addressFocus,
                        hint: 'sara@example.com',
                        prefixIcon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) {
                          final value = v?.trim() ?? '';
                          if (value.isEmpty) return null;

                          final isValid =
                          RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
                              .hasMatch(value);

                          if (!isValid) return 'Enter a valid email';
                          return null;
                        },
                      ),

                      const SizedBox(height: AppDims.s3),

                      FieldLabel(label: 'Address'),
                      const SizedBox(height: AppDims.s1),
                      AppFormField(
                        controller: _addressCtrl,
                        focusNode: _addressFocus,
                        nextFocus: _notesFocus,
                        hint: 'Customer address',
                        prefixIcon: Icons.location_on_outlined,
                      ),

                      const SizedBox(height: AppDims.s3),

                      FieldLabel(label: 'Notes'),
                      const SizedBox(height: AppDims.s1),
                      AppFormField(
                        controller: _notesCtrl,
                        focusNode: _notesFocus,
                        nextFocus: _pointsFocus,
                        hint: 'Any customer notes',
                        prefixIcon: Icons.notes_rounded,
                        maxLines: 3,
                      ),

                      const SizedBox(height: AppDims.s3),

                      FieldLabel(label: 'Loyalty Points'),
                      const SizedBox(height: AppDims.s1),
                      AppFormField(
                        controller: _pointsCtrl,
                        focusNode: _pointsFocus,
                        hint: '0',
                        prefixIcon: Icons.stars_rounded,
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _submit(),
                        validator: (v) {
                          final value = v?.trim() ?? '';
                          if (value.isEmpty) return null;
                          final parsed = int.tryParse(value);
                          if (parsed == null) return 'Enter valid points';
                          if (parsed < 0) return 'Points cannot be negative';
                          return null;
                        },
                      ),

                      const SizedBox(height: AppDims.s5),

                      BlocBuilder<CustomersBloc, CustomersState>(
                        buildWhen: (prev, curr) =>
                        prev.submitStatus != curr.submitStatus,
                        builder: (context, state) {
                          final isLoading = state.submitStatus ==
                              CustomerSubmitStatus.loading;

                          return SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: FilledButton(
                              onPressed: isLoading ? null : _submit,
                              style: FilledButton.styleFrom(
                                backgroundColor: colors.primary,
                                disabledBackgroundColor: colors.border,
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                  BorderRadius.circular(AppDims.rMd),
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
                                _isEdit
                                    ? 'Save Changes'
                                    : 'Create Customer',
                                style: AppTextStyles.bs500(context)
                                    .copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
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
    );
  }
}