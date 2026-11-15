import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/common/motion/motion_route.dart';
import 'package:amana_pos/features/products/presentation/widgets/product_form_widgets.dart';
import 'package:amana_pos/features/users/presentation/bloc/users_bloc.dart';
import 'package:amana_pos/features/users/presentation/widgets/user_actions.dart';
import 'package:amana_pos/features/users/presentation/widgets/user_format.dart';
import 'package:amana_pos/features/users/presentation/widgets/user_pickers.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/theme/phosphor_icons.dart';
import 'package:amana_pos/widgets/app_form_group.dart';
import 'package:amana_pos/widgets/app_segmented.dart';
import 'package:amana_pos/widgets/directional_icon.dart';
import 'package:amana_pos/widgets/pressable.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

const _dial = '+249';
const _prefix = '$_dial ';

/// Opens the full-screen "New team member" form.
Future<void> openUserForm(BuildContext context) {
  final bloc = context.read<UserBloc>();
  return Navigator.of(context).push(
    motionPageRoute(
      BlocProvider.value(value: bloc, child: const _UserFormScreen()),
    ),
  );
}

/// Keeps "+249 " in front and only digits after it (max 10, a leading 0 is
/// allowed and dropped on save).
class _PhoneFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var text = newValue.text;
    if (!text.startsWith(_prefix)) {
      final digits = text.replaceAll(RegExp(r'\D'), '');
      final rest = digits.startsWith('249') ? digits.substring(3) : digits;
      text = _prefix + rest;
    }
    var digits = text.substring(_prefix.length).replaceAll(RegExp(r'\D'), '');
    if (digits.length > 10) digits = digits.substring(0, 10);
    final out = _prefix + digits;
    return TextEditingValue(
      text: out,
      selection: TextSelection.collapsed(offset: out.length),
    );
  }
}

class _UserFormScreen extends StatefulWidget {
  const _UserFormScreen();

  @override
  State<_UserFormScreen> createState() => _UserFormScreenState();
}

class _UserFormScreenState extends State<_UserFormScreen> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController(text: _prefix);

  String _role = 'cashier';
  String? _shopId;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl.addListener(_refresh);
    _phoneCtrl.addListener(_refresh);
    final shops = activeShops(context);
    if (shops.isNotEmpty) _shopId = shops.first.id;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  String get _digits {
    var d = _phoneCtrl.text.substring(_prefix.length);
    if (d.startsWith('0')) d = d.substring(1);
    return d;
  }

  bool get _canSave => _nameCtrl.text.trim().isNotEmpty && _digits.length == 9;

  Future<void> _save() async {
    if (_saving || !_canSave) return;
    FocusScope.of(context).unfocus();
    final tr = context.tr;
    setState(() => _saving = true);
    final ok = await runUserSubmit(
      context,
      OnAddUser(
        phone: '$_dial$_digits',
        fullName: _nameCtrl.text.trim(),
        role: _role,
        shopId: _shopId,
      ),
      successMessage: tr.tmSaved,
    );
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop();
    } else {
      setState(() => _saving = false);
    }
  }

  Future<void> _pickBranch() async {
    final shops = activeShops(context);
    if (shops.isEmpty) return;
    final picked = await showBranchPicker(
      context,
      shops: shops,
      current: _shopId,
    );
    if (picked != null && mounted) setState(() => _shopId = picked);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final tr = context.tr;
    final multiShop = hasMultipleShops(context);
    final shops = activeShops(context);

    Widget label(String text) => ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 104),
      child: Text.rich(
        TextSpan(
          text: text,
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

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            FormNavBar(
              title: tr.tmNew,
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
                      footer: tr.tmSignFoot,
                      children: [
                        AppFormRow(
                          child: Row(
                            children: [
                              label(tr.tmFullName),
                              const SizedBox(width: AppDims.s2),
                              Expanded(
                                child: AppRowTextField(
                                  controller: _nameCtrl,
                                  hint: tr.tmFullName,
                                  textCapitalization: TextCapitalization.words,
                                ),
                              ),
                            ],
                          ),
                        ),
                        AppFormRow(
                          child: Row(
                            children: [
                              label(tr.tmPhone),
                              const SizedBox(width: AppDims.s2),
                              Expanded(
                                child: AppRowTextField(
                                  controller: _phoneCtrl,
                                  numeric: true,
                                  keyboardType: TextInputType.phone,
                                  textInputAction: TextInputAction.done,
                                  inputFormatters: [_PhoneFormatter()],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsetsDirectional.fromSTEB(
                        20,
                        22,
                        20,
                        7,
                      ),
                      child: Text(
                        tr.tmRole,
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.3,
                          color: colors.textHint,
                        ),
                      ),
                    ),
                    AppSegmented<String>(
                      segments: [
                        AppSegment(value: 'cashier', label: tr.tmRoleCashier),
                        AppSegment(value: 'manager', label: tr.tmRoleManager),
                      ],
                      selected: _role,
                      onChanged: (r) => setState(() => _role = r),
                    ),
                    Padding(
                      padding: const EdgeInsetsDirectional.fromSTEB(
                        20,
                        8,
                        20,
                        0,
                      ),
                      child: Text(
                        userRoleDesc(context, _role),
                        style: TextStyle(
                          fontSize: 13,
                          height: 18 / 13,
                          color: colors.textHint,
                        ),
                      ),
                    ),
                    if (multiShop) ...[
                      const SizedBox(height: 22),
                      AppFormGroup(
                        children: [
                          Pressable(
                            onTap: _pickBranch,
                            scale: 1,
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(minHeight: 50),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppDims.s4,
                                ),
                                child: Row(
                                  children: [
                                    Text(
                                      tr.tmBranch,
                                      style: TextStyle(
                                        fontSize: 17,
                                        height: 1.3,
                                        color: colors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(width: AppDims.s3),
                                    Expanded(
                                      child: Text(
                                        shopName(shops, _shopId) ?? '-',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        textAlign: TextAlign.end,
                                        style: TextStyle(
                                          fontSize: 17,
                                          height: 1.3,
                                          color: colors.textSecondary,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: AppDims.s2),
                                    DirectionalIcon(
                                      icon: PhosphorIconsRegular.caretRight,
                                      size: 18,
                                      color: colors.borderStrong,
                                    ),
                                  ],
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
