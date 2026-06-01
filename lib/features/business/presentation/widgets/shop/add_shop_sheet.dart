import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/features/business/presentation/bloc/business_bloc.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/utilities/global_snackbar.dart';
import 'package:amana_pos/widgets/field_label.dart';
import 'package:amana_pos/widgets/form_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solar_icons/solar_icons.dart';

void showAddShopSheet(BuildContext context, String? businessId) {
  if (businessId == null || businessId.isEmpty) return;

  final businessBloc = context.read<BusinessBloc>();

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => BlocProvider.value(
      value: businessBloc,
      child: _AddShopSheet(businessId: businessId),
    ),
  );
}

class _AddShopSheet extends StatefulWidget {
  final String businessId;

  const _AddShopSheet({
    required this.businessId,
  });

  @override
  State<_AddShopSheet> createState() => _AddShopSheetState();
}

class _AddShopSheetState extends State<_AddShopSheet> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameCtrl;
  late final TextEditingController _addressCtrl;
  late final TextEditingController _phoneCtrl;

  late final FocusNode _nameFocus;
  late final FocusNode _addressFocus;
  late final FocusNode _phoneFocus;

  static final RegExp _phoneRegex = RegExp(r'^\+?[0-9]{7,15}$');

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _addressCtrl = TextEditingController();
    _phoneCtrl = TextEditingController();

    _nameFocus = FocusNode();
    _addressFocus = FocusNode();
    _phoneFocus = FocusNode();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _addressCtrl.dispose();
    _phoneCtrl.dispose();

    _nameFocus.dispose();
    _addressFocus.dispose();
    _phoneFocus.dispose();

    super.dispose();
  }

  void _submit() {
    final formState = _formKey.currentState;
    if (formState == null || !formState.validate()) return;

    final name = _nameCtrl.text.trim();
    final address = _addressCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();

    context.read<BusinessBloc>().add(
      OnAddShop(
        businessId: widget.businessId,
        name: name,
        address: address.isEmpty ? null : address,
        phone: phone.isEmpty ? null : phone,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return BlocListener<BusinessBloc, BusinessState>(
      listenWhen: (prev, curr) => prev.submitStatus != curr.submitStatus,
      listener: (context, state) {
        if (state.submitStatus == BusinessSubmitStatus.success) {
          Navigator.of(context).pop();
          GlobalSnackBar.show(
            message: context.tr.shopAddedSuccessfully,
            isInfo: true,
          );
          return;
        }

        if (state.submitStatus == BusinessSubmitStatus.failure) {
          GlobalSnackBar.show(
            message: state.submitError ?? context.tr.somethingWentWrong,
            isError: true,
            isAutoDismiss: false,
          );
        }
      },
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomInset),
        child: DecoratedBox(
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
                padding: const EdgeInsetsDirectional.fromSTEB(
                  AppDims.s4,
                  AppDims.s4,
                  AppDims.s4,
                  0,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        context.tr.newShop,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bs600(context).copyWith(
                          fontWeight: FontWeight.w800,
                          color: colors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppDims.s2),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: IconButton.styleFrom(
                        backgroundColor: colors.surfaceSoft,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppDims.rSm),
                        ),
                        fixedSize: const Size(42, 42),
                        minimumSize: const Size(42, 42),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      icon: Icon(
                        SolarIconsOutline.closeCircle,
                        size: 24,
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              Flexible(
                child: SingleChildScrollView(
                  keyboardDismissBehavior:
                  ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.all(AppDims.s4),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FieldLabel(
                          label: context.tr.bizFieldShopName,
                          required: true,
                        ),
                        const SizedBox(height: AppDims.s1),
                        AppFormField(
                          controller: _nameCtrl,
                          focusNode: _nameFocus,
                          nextFocus: _addressFocus,
                          hint: context.tr.mainBranchHint,
                          prefixIcon: SolarIconsOutline.shop,
                          validator: (value) {
                            final name = value?.trim() ?? '';

                            if (name.isEmpty) {
                              return context.tr.shopNameRequired;
                            }

                            if (name.length < 2) {
                              return context.tr.nameMustBeAtLeast2Characters;
                            }

                            return null;
                          },
                        ),

                        const SizedBox(height: AppDims.s4),

                        _OptionalDivider(
                          label: context.tr.optional,
                        ),

                        const SizedBox(height: AppDims.s4),

                        FieldLabel(label: context.tr.bizFieldAddress),
                        const SizedBox(height: AppDims.s1),
                        AppFormField(
                          controller: _addressCtrl,
                          focusNode: _addressFocus,
                          nextFocus: _phoneFocus,
                          hint: context.tr.khartoumCentreHint,
                          prefixIcon: SolarIconsOutline.mapPoint,
                        ),

                        const SizedBox(height: AppDims.s3),

                        FieldLabel(label: context.tr.bizFieldPhone),
                        const SizedBox(height: AppDims.s1),
                        AppFormField(
                          controller: _phoneCtrl,
                          focusNode: _phoneFocus,
                          hint: '+249912345678',
                          prefixIcon: SolarIconsOutline.phone,
                          keyboardType: TextInputType.phone,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => _submit(),
                          validator: (value) {
                            final phone = value?.trim() ?? '';

                            if (phone.isEmpty) return null;

                            if (!_phoneRegex.hasMatch(phone)) {
                              return context.tr.enterValidPhoneNumber;
                            }

                            return null;
                          },
                        ),

                        const SizedBox(height: AppDims.s5),

                        _SubmitButton(onPressed: _submit),
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

class _OptionalDivider extends StatelessWidget {
  final String label;

  const _OptionalDivider({
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Row(
      children: [
        Expanded(child: Divider(color: colors.border)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppDims.s2),
          child: Text(
            label.toUpperCase(),
            style: AppTextStyles.bs300(context).copyWith(
              fontWeight: FontWeight.w800,
              color: colors.textHint,
              letterSpacing: 1.2,
            ),
          ),
        ),
        Expanded(child: Divider(color: colors.border)),
      ],
    );
  }
}

class _SubmitButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _SubmitButton({
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return BlocSelector<BusinessBloc, BusinessState, BusinessSubmitStatus>(
      selector: (state) => state.submitStatus,
      builder: (context, submitStatus) {
        final isLoading = submitStatus == BusinessSubmitStatus.loading;

        return SizedBox(
          width: double.infinity,
          height: 50,
          child: FilledButton(
            onPressed: isLoading ? null : onPressed,
            style: FilledButton.styleFrom(
              backgroundColor: colors.primary,
              disabledBackgroundColor: colors.border,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDims.rMd),
              ),
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: isLoading
                  ? const SizedBox(
                key: ValueKey('loading'),
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
                  : Text(
                context.tr.addShop,
                key: const ValueKey('label'),
                style: AppTextStyles.bs600(context).copyWith(
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}