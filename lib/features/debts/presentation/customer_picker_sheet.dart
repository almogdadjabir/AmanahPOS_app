import 'dart:async';

import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/features/customers/domain/customer_service.dart';
import 'package:amana_pos/features/shifts/presentation/shift_format.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/utilities/dependencies_provider.dart';
import 'package:amana_pos/widgets/app_button.dart';
import 'package:amana_pos/widgets/app_form_group.dart';
import 'package:amana_pos/widgets/app_sheet.dart';
import 'package:amana_pos/widgets/pressable.dart';
import 'package:flutter/material.dart';

import '../data/debt_reader.dart';

/// Picks the customer for the ticket. Returns null when cancelled. A customer
/// can also be created here; it is saved offline like any customer.
Future<PickCustomer?> showCustomerPicker(
  BuildContext context, {
  DebtReader? reader,
  CustomerService Function()? customers,
}) => showAppSheet<PickCustomer>(
  context,
  builder: (_) => CustomerPickerSheet(
    reader: reader ?? getIt<DebtReader>(),
    customers: customers ?? () => getIt<CustomerService>(),
  ),
);

class CustomerPickerSheet extends StatefulWidget {
  const CustomerPickerSheet({
    super.key,
    required this.reader,
    required this.customers,
  });

  final DebtReader reader;
  final CustomerService Function() customers;

  @override
  State<CustomerPickerSheet> createState() => _CustomerPickerSheetState();
}

class _CustomerPickerSheetState extends State<CustomerPickerSheet> {
  final _query = TextEditingController();
  List<PickCustomer> _rows = const [];
  bool _loaded = false;
  bool _creating = false;
  final _name = TextEditingController();
  final _phone = TextEditingController();
  bool _saving = false;
  int _gen = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _query.dispose();
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final gen = ++_gen;
    final r = await widget.reader.customers(_query.text);
    if (!mounted || gen != _gen) return;
    setState(() {
      _rows = r;
      _loaded = true;
    });
  }

  Future<void> _create() async {
    final name = _name.text.trim();
    if (name.isEmpty || _saving) return;
    setState(() => _saving = true);
    try {
      final id = await widget.customers().create(
        name: name,
        phone: _phone.text,
      );
      if (!mounted) return;
      Navigator.of(context).pop(
        PickCustomer(
          id: id,
          name: name,
          phone: _phone.text.trim(),
          owes: BigInt.zero,
        ),
      );
    } catch (_) {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    final colors = context.appColors;
    final text = Theme.of(context).textTheme;

    if (_creating) {
      return AppSheet(
        title: tr.dtNewCustomer,
        leadingAction: AppSheetAction(
          label: tr.cancel,
          onTap: () => setState(() => _creating = false),
        ),
        footer: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(
            AppDims.s4,
            AppDims.s2,
            AppDims.s4,
            AppDims.s4,
          ),
          child: AppButton.wide(
            label: tr.dtNewCustomer,
            isLoading: _saving,
            onPressed: _name.text.trim().isEmpty ? null : _create,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppDims.s4),
          child: AppFormGroup(
            children: [
              AppFormRow(
                label: tr.cuName,
                child: AppRowTextField(
                  controller: _name,
                  hint: tr.cuName,
                  textCapitalization: TextCapitalization.words,
                  onChanged: (_) => setState(() {}),
                ),
              ),
              AppFormRow(
                label: tr.cuPhone,
                child: AppRowTextField(
                  controller: _phone,
                  hint: tr.cuPhone,
                  keyboardType: TextInputType.phone,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return AppSheet(
      title: tr.dtCustomer,
      leadingAction: AppSheetAction(
        label: tr.cancel,
        onTap: () => Navigator.of(context).pop(),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppDims.s4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppFormGroup(
              children: [
                AppFormRow(
                  label: tr.dtSearch,
                  child: AppRowTextField(
                    controller: _query,
                    hint: tr.dtSearch,
                    onChanged: (_) => unawaited(_load()),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDims.s2),
            Pressable(
              onTap: () => setState(() => _creating = true),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppDims.s3),
                child: Text(
                  tr.dtNewCustomer,
                  style: text.titleSmall!.copyWith(
                    color: colors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            if (_loaded && _rows.isEmpty)
              Padding(
                padding: const EdgeInsets.all(AppDims.s4),
                child: Text(
                  tr.dtNoCustomers,
                  textAlign: TextAlign.center,
                  style: text.bodyMedium!.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 360),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _rows.length,
                itemBuilder: (context, i) {
                  final c = _rows[i];
                  return Pressable(
                    onTap: () => Navigator.of(context).pop(c),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppDims.s3,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  c.name,
                                  style: text.titleSmall!.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (c.phone.isNotEmpty)
                                  Text(
                                    c.phone,
                                    textDirection: TextDirection.ltr,
                                    style: text.bodySmall!.copyWith(
                                      color: colors.textSecondary,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          if (c.owes > BigInt.zero)
                            Text(
                              shiftMoney(c.owes),
                              textDirection: TextDirection.ltr,
                              style: text.titleSmall!.copyWith(
                                color: colors.danger,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
