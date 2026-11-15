import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/features/business/data/models/responses/business_response_dto.dart';
import 'package:amana_pos/features/business/presentation/bloc/business_bloc.dart';
import 'package:amana_pos/features/business/presentation/widgets/settings/business_form_parts.dart';
import 'package:amana_pos/features/business/presentation/widgets/settings/business_helpers.dart';
import 'package:amana_pos/features/products/presentation/widgets/product_form_widgets.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/utilities/global_snackbar.dart';
import 'package:amana_pos/widgets/app_confirm_sheet.dart';
import 'package:amana_pos/widgets/app_form_group.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// New / edit shop. [shop] null = new shop.
class ShopFormScreen extends StatefulWidget {
  final String businessId;
  final ShopData? shop;

  const ShopFormScreen({super.key, required this.businessId, this.shop});

  @override
  State<ShopFormScreen> createState() => _ShopFormScreenState();
}

class _ShopFormScreenState extends State<ShopFormScreen> {
  final _nameCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  late bool _active;
  bool _saving = false;

  bool get _isEdit => widget.shop != null;

  @override
  void initState() {
    super.initState();
    final s = widget.shop;
    _nameCtrl.text = s?.name?.trim() ?? '';
    _addressCtrl.text = s?.address?.trim() ?? '';
    _phoneCtrl.text = s?.phone?.trim() ?? '';
    _active = s?.isActive != false;
    _nameCtrl.addListener(_refresh);
    _addressCtrl.addListener(_refresh);
    _phoneCtrl.addListener(_refresh);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _addressCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  bool get _hasName => _nameCtrl.text.trim().length >= 2;

  bool get _changed {
    final s = widget.shop;
    if (s == null) return true;
    return _nameCtrl.text.trim() != (s.name?.trim() ?? '') ||
        _addressCtrl.text.trim() != (s.address?.trim() ?? '') ||
        _phoneCtrl.text.trim() != (s.phone?.trim() ?? '') ||
        _active != (s.isActive != false);
  }

  bool get _canSave => _hasName && _changed;

  Future<void> _save() async {
    if (_saving || !_canSave) return;
    final tr = context.tr;
    final bloc = context.read<BusinessBloc>();
    final name = _nameCtrl.text.trim();
    final address = _addressCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();

    FocusScope.of(context).unfocus();
    setState(() => _saving = true);
    final result = nextBusinessSubmit(bloc);

    final shop = widget.shop;
    if (shop == null) {
      bloc.add(
        OnAddShop(
          businessId: widget.businessId,
          name: name,
          address: address.isEmpty ? null : address,
          phone: phone.isEmpty ? null : phone,
        ),
      );
    } else {
      final id = shop.id?.trim();
      if (id == null || id.isEmpty) {
        setState(() => _saving = false);
        GlobalSnackBar.show(message: tr.somethingWentWrong, isError: true);
        return;
      }
      bloc.add(
        OnEditShop(
          businessId: widget.businessId,
          shopId: id,
          name: name,
          address: address,
          phone: phone,
          isActive: _active,
        ),
      );
    }

    final state = await result;
    if (!mounted) return;

    if (state.submitStatus == BusinessSubmitStatus.success) {
      Navigator.of(context).pop();
      GlobalSnackBar.show(
        message: _isEdit ? tr.shSaved : tr.shAdded,
        isInfo: true,
      );
      return;
    }

    setState(() => _saving = false);
    GlobalSnackBar.show(
      message: state.submitError ?? tr.somethingWentWrong,
      isError: true,
      isAutoDismiss: false,
    );
  }

  Future<void> _toggleActive(bool value) async {
    if (value) {
      setState(() => _active = true);
      return;
    }
    final tr = context.tr;
    final name = _nameCtrl.text.trim().isNotEmpty
        ? _nameCtrl.text.trim()
        : tr.shop;
    final confirmed = await showAppConfirmSheet(
      context,
      title: tr.shDeactivateTitle(name),
      message: tr.shDeactivateBody,
      confirmLabel: tr.shDeactivateAction,
    );
    if (confirmed && mounted) setState(() => _active = false);
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
            FormNavBar(
              title: _isEdit ? tr.shEdit : tr.shNew,
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
                  AppDims.s4,
                  AppDims.s4,
                  AppDims.s8 + MediaQuery.viewPaddingOf(context).bottom,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AppFormGroup(
                      children: [
                        AppFormRow(
                          child: Row(
                            children: [
                              BizRequiredLabel(tr.shName),
                              const SizedBox(width: AppDims.s2),
                              Expanded(
                                child: AppRowTextField(
                                  controller: _nameCtrl,
                                  hint: tr.shName,
                                  textCapitalization: TextCapitalization.words,
                                ),
                              ),
                            ],
                          ),
                        ),
                        AppFormRow(
                          label: tr.shAddress,
                          child: AppRowTextField(
                            controller: _addressCtrl,
                            hint: tr.optional,
                            textCapitalization: TextCapitalization.words,
                          ),
                        ),
                        AppFormRow(
                          label: tr.shPhone,
                          child: AppRowTextField(
                            controller: _phoneCtrl,
                            hint: tr.optional,
                            numeric: true,
                            keyboardType: TextInputType.phone,
                            textInputAction: TextInputAction.done,
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'[0-9+ ]'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (_isEdit) ...[
                      const SizedBox(height: 22),
                      AppFormGroup(
                        footer: tr.shOpenFoot,
                        children: [
                          AppSwitchRow(
                            title: tr.shOpenForSales,
                            value: _active,
                            onChanged: _toggleActive,
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
