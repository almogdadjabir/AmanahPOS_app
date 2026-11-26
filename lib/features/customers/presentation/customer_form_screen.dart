import 'package:amana_pos/core/features/business_features.dart';
import 'package:amana_pos/features/debts/data/debt_reader.dart';
import 'package:amana_pos/features/shifts/presentation/shift_format.dart';
import 'package:amana_pos/utilities/dependencies_provider.dart';
import 'package:amana_pos/common/auth_bloc/auth_bloc.dart';
import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/common/motion/motion_route.dart';
import 'package:amana_pos/features/customers/data/models/requests/customer_request_dto.dart';
import 'package:amana_pos/features/customers/data/models/responses/customer_response_dto.dart';
import 'package:amana_pos/features/customers/presentation/bloc/customers_bloc.dart';
import 'package:amana_pos/features/products/presentation/widgets/product_form_widgets.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/theme/phosphor_icons.dart';
import 'package:amana_pos/utilities/global_snackbar.dart';
import 'package:amana_pos/widgets/app_confirm_sheet.dart';
import 'package:amana_pos/widgets/app_form_group.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Opens the new / edit customer screen. [customer] null = new customer.
Future<void> openCustomerForm(BuildContext context, {CustomerData? customer}) {
  final bloc = context.read<CustomersBloc>();

  return Navigator.of(context).push(
    motionPageRoute(
      BlocProvider.value(
        value: bloc,
        child: _CustomerFormScreen(customer: customer),
      ),
    ),
  );
}

/// Waits for the next finished submit on [bloc] (success or failure).
Future<CustomersState> _nextSubmitResult(CustomersBloc bloc) {
  return bloc.stream.firstWhere(
    (s) =>
        s.submitStatus == CustomerSubmitStatus.success ||
        s.submitStatus == CustomerSubmitStatus.failure,
  );
}

Future<bool> _setActive(
  BuildContext context,
  CustomerData customer,
  bool active,
) async {
  final tr = context.tr;
  final bloc = context.read<CustomersBloc>();
  final id = customer.id?.trim();

  if (id == null || id.isEmpty) {
    GlobalSnackBar.show(message: tr.somethingWentWrong, isError: true);
    return false;
  }

  final result = _nextSubmitResult(bloc);
  bloc.add(OnSetCustomerActive(customerId: id, isActive: active));
  final state = await result;

  if (state.submitStatus == CustomerSubmitStatus.success) {
    GlobalSnackBar.show(
      message: active ? tr.cuReactivated : tr.cuDeactivated,
      isInfo: true,
    );
    return true;
  }

  GlobalSnackBar.show(
    message: state.submitError ?? tr.somethingWentWrong,
    isError: true,
    isAutoDismiss: false,
  );
  return false;
}

/// Confirms, deactivates and reports the result with a snackbar.
/// Resolves to true when the customer was deactivated.
Future<bool> confirmDeactivateCustomer(
  BuildContext context,
  CustomerData customer,
) async {
  final tr = context.tr;
  final name = customer.name?.trim() ?? '';

  // A customer who still owes money gets a plain warning in the message.
  var owes = BigInt.zero;
  final id = customer.id;
  if (id != null && getIt<BusinessFeaturesService>().current.onAccount) {
    owes = await getIt<DebtReader>().balance(id);
  }
  if (!context.mounted) return false;

  final confirmed = await showAppConfirmSheet(
    context,
    title: tr.cuDeactivateTitle(name),
    message: owes > BigInt.zero
        ? '${tr.dtStillOwes(name, shiftMoney(owes))}\n\n${tr.cuDeactivateBody(name)}'
        : tr.cuDeactivateBody(name),
    confirmLabel: tr.cuDeactivateConfirm,
  );
  if (!confirmed || !context.mounted) return false;

  return _setActive(context, customer, false);
}

/// Reactivates right away (no confirm, it is the safe direction).
Future<bool> reactivateCustomer(BuildContext context, CustomerData customer) =>
    _setActive(context, customer, true);

class _CustomerFormScreen extends StatefulWidget {
  final CustomerData? customer;
  const _CustomerFormScreen({this.customer});

  @override
  State<_CustomerFormScreen> createState() => _CustomerFormScreenState();
}

class _CustomerFormScreenState extends State<_CustomerFormScreen> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  bool _saving = false;
  bool _showMore = false;

  bool get _isEdit => widget.customer != null;

  @override
  void initState() {
    super.initState();
    final c = widget.customer;
    _nameCtrl.text = c?.name?.trim() ?? '';
    _phoneCtrl.text = c?.phone?.trim() ?? '';
    _emailCtrl.text = c?.email?.trim() ?? '';
    _addressCtrl.text = c?.address?.trim() ?? '';
    _notesCtrl.text = c?.notes?.trim() ?? '';
    _showMore =
        _emailCtrl.text.isNotEmpty ||
        _addressCtrl.text.isNotEmpty ||
        _notesCtrl.text.isNotEmpty;
    _nameCtrl.addListener(_refresh);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _addressCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  bool get _canSave => _nameCtrl.text.trim().isNotEmpty;

  /// Create sends only what was filled; edit sends every field so a cleared
  /// one is cleared on the server too.
  CustomerRequestDto _dto() {
    String? field(TextEditingController c) {
      final v = c.text.trim();
      return v.isEmpty && !_isEdit ? null : v;
    }

    return CustomerRequestDto(
      name: _nameCtrl.text.trim(),
      phone: field(_phoneCtrl),
      email: field(_emailCtrl),
      address: field(_addressCtrl),
      notes: field(_notesCtrl),
    );
  }

  Future<void> _save() async {
    if (_saving || !_canSave) return;
    final tr = context.tr;
    final bloc = context.read<CustomersBloc>();
    final existing = widget.customer;

    String? id;
    if (existing != null) {
      id = existing.id?.trim();
      if (id == null || id.isEmpty) {
        GlobalSnackBar.show(message: tr.somethingWentWrong, isError: true);
        return;
      }
    }

    FocusScope.of(context).unfocus();
    setState(() => _saving = true);
    final result = _nextSubmitResult(bloc);
    bloc.add(
      id != null
          ? OnUpdateCustomer(customerId: id, dto: _dto())
          : OnCreateCustomer(dto: _dto()),
    );
    final state = await result;
    if (!mounted) return;

    if (state.submitStatus == CustomerSubmitStatus.success) {
      Navigator.of(context).pop();
      GlobalSnackBar.show(message: tr.cuSaved, isInfo: true);
      return;
    }

    setState(() => _saving = false);
    GlobalSnackBar.show(
      message: state.submitError ?? tr.somethingWentWrong,
      isError: true,
      isAutoDismiss: false,
    );
  }

  Future<void> _toggleActive(CustomerData customer, bool wasActive) async {
    final navigator = Navigator.of(context);
    final done = wasActive
        ? await confirmDeactivateCustomer(context, customer)
        : await reactivateCustomer(context, customer);
    if (!done || !mounted) return;
    navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final tr = context.tr;
    final canManage = !context.select<AuthBloc, bool>(
      (b) => b.state.permissions.isCashier,
    );

    // Latest copy from the bloc, so the Deactivate row follows live status.
    final customer = widget.customer == null
        ? null
        : context.select<CustomersBloc, CustomerData>((bloc) {
            for (final c in bloc.state.customers) {
              if (c.id == widget.customer!.id) return c;
            }
            return widget.customer!;
          });
    final active = customer?.isActive != false;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            FormNavBar(
              title: _isEdit ? tr.cuEditTitle : tr.cuNew,
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
                  0,
                  AppDims.s4,
                  AppDims.s8 + MediaQuery.viewPaddingOf(context).bottom,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AppFormGroup(
                      footer: tr.cuPhoneFoot,
                      children: [
                        AppFormRow(
                          child: Row(
                            children: [
                              _RequiredLabel(tr.cuName),
                              const SizedBox(width: AppDims.s2),
                              Expanded(
                                child: AppRowTextField(
                                  controller: _nameCtrl,
                                  hint: tr.cuName,
                                  textCapitalization: TextCapitalization.words,
                                ),
                              ),
                            ],
                          ),
                        ),
                        AppFormRow(
                          label: tr.cuPhone,
                          child: AppRowTextField(
                            controller: _phoneCtrl,
                            hint: tr.fmOptional,
                            numeric: true,
                            keyboardType: TextInputType.phone,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    if (_showMore)
                      AppFormGroup(
                        children: [
                          AppFormRow(
                            label: tr.cuEmail,
                            child: AppRowTextField(
                              controller: _emailCtrl,
                              hint: tr.fmOptional,
                              numeric: true,
                              keyboardType: TextInputType.emailAddress,
                              textCapitalization: TextCapitalization.none,
                            ),
                          ),
                          AppFormRow(
                            label: tr.cuAddress,
                            child: AppRowTextField(
                              controller: _addressCtrl,
                              hint: tr.fmOptional,
                            ),
                          ),
                          AppFormRow(
                            label: tr.cuNotes,
                            minHeight: 96,
                            align: CrossAxisAlignment.start,
                            child: AppRowTextField(
                              controller: _notesCtrl,
                              hint: tr.fmOptional,
                              maxLines: 4,
                              keyboardType: TextInputType.multiline,
                              textInputAction: TextInputAction.newline,
                            ),
                          ),
                        ],
                      )
                    else
                      AppFormGroup(
                        children: [
                          AppFormRow(
                            onTap: () => setState(() => _showMore = true),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    tr.cuMore,
                                    style: TextStyle(
                                      fontSize: 17,
                                      height: 1.3,
                                      fontWeight: FontWeight.w500,
                                      color: colors.primary,
                                    ),
                                  ),
                                ),
                                Icon(
                                  PhosphorIconsRegular.caretDown,
                                  size: 18,
                                  color: colors.primary,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    if (_isEdit && canManage && customer != null) ...[
                      const SizedBox(height: 22),
                      AppFormGroup(
                        children: [
                          AppFormRow(
                            onTap: _saving
                                ? null
                                : () => _toggleActive(customer, active),
                            child: Center(
                              child: Text(
                                active ? tr.cuDeactivate : tr.cuReactivate,
                                style: TextStyle(
                                  fontSize: 17,
                                  height: 1.3,
                                  fontWeight: FontWeight.w500,
                                  color: active
                                      ? colors.danger
                                      : colors.primary,
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

/// Form label with the red required mark, same width as [AppFormRow] labels.
class _RequiredLabel extends StatelessWidget {
  final String label;
  const _RequiredLabel(this.label);

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 104),
      child: Text.rich(
        TextSpan(
          text: label,
          children: [
            TextSpan(
              text: ' *',
              style: TextStyle(color: colors.danger),
            ),
          ],
        ),
        maxLines: 1,
        softWrap: false,
        style: TextStyle(fontSize: 17, height: 1.3, color: colors.textPrimary),
      ),
    );
  }
}
