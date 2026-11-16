import 'package:amana_pos/common/auth_bloc/auth_bloc.dart' hide BusinessStatus;
import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/config/router/route_strings.dart';
import 'package:amana_pos/features/business/data/models/responses/business_response_dto.dart';
import 'package:amana_pos/features/business/presentation/bloc/business_bloc.dart';
import 'package:amana_pos/features/business/presentation/widgets/settings/business_form_parts.dart';
import 'package:amana_pos/features/business/presentation/widgets/settings/business_helpers.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/utilities/extension.dart';
import 'package:amana_pos/utilities/global_snackbar.dart';
import 'package:amana_pos/widgets/app_form_group.dart';
import 'package:amana_pos/widgets/app_large_title.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Business profile and tax settings (owner). One form, Save in the bar.
class BusinessSettingsScreen extends StatefulWidget {
  const BusinessSettingsScreen({super.key});

  @override
  State<BusinessSettingsScreen> createState() => _BusinessSettingsScreenState();
}

class _Snapshot {
  final String name;
  final String phone;
  final String email;
  final String address;
  final bool taxOn;
  final String taxName;
  final String taxRate;
  final bool inclusive;

  const _Snapshot({
    required this.name,
    required this.phone,
    required this.email,
    required this.address,
    required this.taxOn,
    required this.taxName,
    required this.taxRate,
    required this.inclusive,
  });
}

String _rateText(String? raw) {
  final v = double.tryParse(raw ?? '');
  if (v == null) return '';
  return v % 1 == 0 ? v.toStringAsFixed(0) : v.toString();
}

class _BusinessSettingsScreenState extends State<BusinessSettingsScreen> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _taxNameCtrl = TextEditingController();
  final _taxRateCtrl = TextEditingController();

  bool _taxOn = false;
  bool _inclusive = false;
  bool _saving = false;
  String? _loadedId;
  _Snapshot? _base;

  @override
  void initState() {
    super.initState();
    for (final c in [
      _nameCtrl,
      _phoneCtrl,
      _emailCtrl,
      _addressCtrl,
      _taxNameCtrl,
      _taxRateCtrl,
    ]) {
      c.addListener(_refresh);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _addressCtrl.dispose();
    _taxNameCtrl.dispose();
    _taxRateCtrl.dispose();
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  /// Fills the form once from the loaded business.
  void _load(BusinessData b) {
    if (_loadedId == b.id) return;
    _loadedId = b.id;
    _nameCtrl.text = b.name?.trim() ?? '';
    _phoneCtrl.text = b.phone?.trim() ?? '';
    _emailCtrl.text = b.email?.trim() ?? '';
    _addressCtrl.text = b.address?.trim() ?? '';
    _taxOn = b.taxEnabled == true;
    _inclusive = b.taxInclusive == true;
    _taxNameCtrl.text = b.taxName?.trim() ?? '';
    _taxRateCtrl.text = _rateText(b.taxRate);
    _base = _current();
  }

  _Snapshot _current() => _Snapshot(
    name: _nameCtrl.text.trim(),
    phone: _phoneCtrl.text.trim(),
    email: _emailCtrl.text.trim(),
    address: _addressCtrl.text.trim(),
    taxOn: _taxOn,
    taxName: _taxNameCtrl.text.trim(),
    taxRate: _taxRateCtrl.text.trim(),
    inclusive: _inclusive,
  );

  bool get _changed {
    final b = _base;
    if (b == null) return false;
    final c = _current();
    if (c.name != b.name ||
        c.phone != b.phone ||
        c.email != b.email ||
        c.address != b.address ||
        c.taxOn != b.taxOn) {
      return true;
    }
    // Tax detail only matters while tax is on.
    return c.taxOn &&
        (c.taxName != b.taxName ||
            c.taxRate != b.taxRate ||
            c.inclusive != b.inclusive);
  }

  double? get _rate => double.tryParse(_taxRateCtrl.text.trim());

  bool get _canSave => _nameCtrl.text.trim().isNotEmpty && _changed;

  Future<void> _save(String businessId) async {
    if (_saving || !_canSave) return;
    final tr = context.tr;

    final rate = _rate;
    if (_taxOn && (rate == null || rate < 0 || rate > 100)) {
      GlobalSnackBar.show(message: tr.bsTaxRateInvalid, isError: true);
      return;
    }

    final bloc = context.read<BusinessBloc>();
    FocusScope.of(context).unfocus();
    setState(() => _saving = true);
    final result = nextBusinessSubmit(bloc);
    bloc.add(
      OnEditBusiness(
        businessId: businessId,
        name: _nameCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        address: _addressCtrl.text.trim(),
        taxEnabled: _taxOn,
        taxName: _taxOn ? _taxNameCtrl.text.trim() : null,
        taxRate: _taxOn ? rate : null,
        taxInclusive: _taxOn ? _inclusive : null,
      ),
    );
    final state = await result;
    if (!mounted) return;

    if (state.submitStatus == BusinessSubmitStatus.success) {
      setState(() {
        _saving = false;
        _base = _current();
      });
      GlobalSnackBar.show(message: tr.bsSaved, isInfo: true);
      return;
    }

    setState(() => _saving = false);
    GlobalSnackBar.show(
      message: state.submitError ?? tr.somethingWentWrong,
      isError: true,
      isAutoDismiss: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final tr = context.tr;
    final fallback = context.select<AuthBloc, BusinessData?>(
      (b) => b.state.defaultBusiness,
    );
    final business = context.select<BusinessBloc, BusinessData?>(
      (b) => currentBusiness(b.state, fallback),
    );
    if (business != null) _load(business);
    final id = business?.id;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            BizNavBar(
              backLabel: tr.mrSettings,
              trailing: BizNavText(
                label: tr.save,
                busy: _saving,
                onTap: id != null && _canSave ? () => _save(id) : null,
              ),
            ),
            Expanded(
              child: business == null
                  ? Center(
                      child: CircularProgressIndicator(color: colors.primary),
                    )
                  : _form(context, business),
            ),
          ],
        ),
      ),
    );
  }

  Widget _form(BuildContext context, BusinessData business) {
    final colors = context.appColors;
    final tr = context.tr;
    final shopCount = business.shopCount ?? business.shops?.length ?? 0;
    final name = business.name?.trim() ?? '';

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: EdgeInsets.fromLTRB(
        AppDims.s4,
        0,
        AppDims.s4,
        AppDims.s8 + MediaQuery.viewPaddingOf(context).bottom,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppLargeTitle(title: tr.bsTitle),
          Center(
            child: Container(
              width: 92,
              height: 92,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: colors.primaryContainer,
                borderRadius: BorderRadius.circular(24),
              ),
              alignment: Alignment.center,
              child: business.logo != null
                  ? Image.network(
                      business.logo!,
                      width: 92,
                      height: 92,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => _Initials(name),
                    )
                  : _Initials(name),
            ),
          ),
          const SizedBox(height: AppDims.s4),
          AppFormGroup(
            children: [
              AppFormRow(
                child: Row(
                  children: [
                    BizRequiredLabel(tr.bsName),
                    const SizedBox(width: AppDims.s2),
                    Expanded(
                      child: AppRowTextField(
                        controller: _nameCtrl,
                        hint: tr.bsName,
                        textCapitalization: TextCapitalization.words,
                      ),
                    ),
                  ],
                ),
              ),
              AppFormRow(
                label: tr.bsPhone,
                child: AppRowTextField(
                  controller: _phoneCtrl,
                  hint: tr.optional,
                  numeric: true,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9+ ]')),
                  ],
                ),
              ),
              AppFormRow(
                label: tr.bsEmail,
                child: AppRowTextField(
                  controller: _emailCtrl,
                  hint: tr.optional,
                  numeric: true,
                  keyboardType: TextInputType.emailAddress,
                  textCapitalization: TextCapitalization.none,
                ),
              ),
              AppFormRow(
                label: tr.bsAddress,
                child: AppRowTextField(
                  controller: _addressCtrl,
                  hint: tr.optional,
                  textInputAction: TextInputAction.done,
                  textCapitalization: TextCapitalization.words,
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          AppFormGroup(
            header: tr.bsShops,
            children: [
              AppFormRow(
                label: tr.bsShops,
                chevron: true,
                onTap: () => Navigator.of(
                  context,
                ).pushNamed(RouteStrings.shopManagementScreen),
                child: Text(
                  tr.bsShopsCount(shopCount),
                  textAlign: TextAlign.end,
                  style: TextStyle(fontSize: 17, color: colors.textSecondary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          AppFormGroup(
            header: tr.bsTax,
            footer: _taxOn ? tr.bsTaxFootOn : tr.bsTaxFootOff,
            children: [
              AppSwitchRow(
                title: tr.bsChargeTax,
                value: _taxOn,
                onChanged: (v) => setState(() => _taxOn = v),
              ),
              if (_taxOn) ...[
                AppFormRow(
                  label: tr.bsTaxName,
                  child: AppRowTextField(
                    controller: _taxNameCtrl,
                    hint: 'VAT',
                    textCapitalization: TextCapitalization.characters,
                  ),
                ),
                AppFormRow(
                  label: tr.bsTaxRate,
                  child: AppRowTextField(
                    controller: _taxRateCtrl,
                    hint: '0',
                    numeric: true,
                    suffix: '%',
                    textInputAction: TextInputAction.done,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                    ],
                  ),
                ),
                AppSwitchRow(
                  title: tr.bsTaxInclusive,
                  value: _inclusive,
                  onChanged: (v) => setState(() => _inclusive = v),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _Initials extends StatelessWidget {
  final String name;
  const _Initials(this.name);

  @override
  Widget build(BuildContext context) {
    return Text(
      name.isEmpty ? '?' : name.initials,
      style: TextStyle(
        fontSize: 34,
        fontWeight: FontWeight.w700,
        color: context.appColors.primary,
      ),
    );
  }
}
