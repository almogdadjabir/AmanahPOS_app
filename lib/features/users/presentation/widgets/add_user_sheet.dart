import 'package:amana_pos/common/auth_bloc/auth_bloc.dart';
import 'package:amana_pos/features/business/data/models/responses/business_response_dto.dart';
import 'package:amana_pos/features/products/presentation/widgets/product_sheet_shell.dart';
import 'package:amana_pos/features/users/presentation/bloc/users_bloc.dart';
import 'package:amana_pos/features/users/presentation/widgets/role_hint.dart';
import 'package:amana_pos/features/users/presentation/widgets/user_sheet_widgets.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/utilities/global_snackbar.dart';
import 'package:amana_pos/widgets/field_label.dart';
import 'package:amana_pos/widgets/form_field.dart';
import 'package:amana_pos/widgets/phone_number_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

const _kAddRoles = ['cashier', 'manager'];

void showAddUserSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => MultiBlocProvider(
      providers: [
        BlocProvider.value(value: context.read<UserBloc>()),
        BlocProvider.value(value: context.read<AuthBloc>()),
      ],
      child: const _AddUserSheet(),
    ),
  );
}

class _AddUserSheet extends StatefulWidget {
  const _AddUserSheet();

  @override
  State<_AddUserSheet> createState() => _AddUserSheetState();
}

class _AddUserSheetState extends State<_AddUserSheet> {
  final _formKey  = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _nameFocus  = FocusNode();
  final _phoneFocus = FocusNode();

  bool    _phoneError   = false;
  String  _selectedRole = 'cashier';
  String? _selectedShopId;

  // Active shops from the current business
  List<ShopData> get _shops =>
      context.read<AuthBloc>().state.defaultBusiness?.shops
          ?.where((s) => s.id != null && (s.isActive ?? true))
          .toList() ??
          [];

  bool get _isCashier => _selectedRole == 'cashier';

  // Show picker only when cashier + 2+ shops
  bool get _showShopPicker => _isCashier && _shops.length >= 2;

  // Single shop → auto-selected, show confirmation only
  bool get _showShopConfirmation => _isCashier && _shops.length == 1;

  @override
  void initState() {
    super.initState();
    // Auto-select if only one shop
    final shops = _shops;
    if (shops.length == 1) _selectedShopId = shops.first.id;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();   _phoneCtrl.dispose();
    _nameFocus.dispose();  _phoneFocus.dispose();
    super.dispose();
  }

  String get _fullPhone => '+249${_phoneCtrl.text.trim()}';

  bool get _isPhoneValid {
    final digits = _phoneCtrl.text.trim();
    return digits.length >= phoneMaxLength(digits);
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (!_isPhoneValid) {
      setState(() => _phoneError = true);
      return;
    }

    // Cashier with multiple shops must select a shop
    if (_isCashier && _shops.length >= 2 && _selectedShopId == null) {
      GlobalSnackBar.show(
        message: 'Please assign this cashier to a shop.',
        isError: true,
      );
      return;
    }

    context.read<UserBloc>().add(OnAddUser(
      phone:    _fullPhone,
      fullName: _nameCtrl.text.trim(),
      role:     _selectedRole,
      shopId:   _selectedShopId, // null for managers or auto-assigned single shop
    ));
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<UserBloc, UserState>(
      listenWhen: (prev, curr) => prev.submitStatus != curr.submitStatus,
      listener: (context, state) {
        if (state.submitStatus == UserSubmitStatus.success) {
          Navigator.of(context).pop();
          GlobalSnackBar.show(
              message: 'User added successfully', isInfo: true);
        }
        if (state.submitStatus == UserSubmitStatus.failure) {
          GlobalSnackBar.show(
            message:       state.submitError ?? 'Something went wrong',
            isError:       true,
            isAutoDismiss: false,
          );
        }
      },
      child: ProductSheetShell(
        title: 'New User',
        body: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // ── Full name ──────────────────────────────────────────
              FieldLabel(label: 'Full Name', required: true),
              const SizedBox(height: AppDims.s1),
              AppFormField(
                controller: _nameCtrl,
                focusNode:  _nameFocus,
                nextFocus:  _phoneFocus,
                hint:       'Ali Hassan',
                prefixIcon: Icons.person_outline_rounded,
                validator: (v) {
                  if (v == null || v.trim().isEmpty)
                    return 'Full name is required';
                  if (v.trim().length < 2)
                    return 'Name must be at least 2 characters';
                  return null;
                },
              ),
              const SizedBox(height: AppDims.s3),

              // ── Phone ──────────────────────────────────────────────
              FieldLabel(label: 'Phone', required: true),
              const SizedBox(height: AppDims.s1),
              PhoneNumberField(
                controller: _phoneCtrl,
                focusNode:  _phoneFocus,
                error:      _phoneError,
                onChanged:  (_) {
                  if (_phoneError) setState(() => _phoneError = false);
                },
              ),
              SizedBox(
                height: 24,
                child: _phoneError ? _PhoneError() : const SizedBox.shrink(),
              ),
              const SizedBox(height: AppDims.s3),

              // ── Role ───────────────────────────────────────────────
              FieldLabel(label: 'Role', required: true),
              const SizedBox(height: AppDims.s2),
              RolePicker(
                roles:        _kAddRoles,
                selectedRole: _selectedRole,
                onSelected:   (r) => setState(() {
                  _selectedRole   = r;
                  // Clear shop selection when switching to manager
                  if (r != 'cashier') _selectedShopId = null;
                  // Re-auto-select when switching back to cashier (single shop)
                  if (r == 'cashier' && _shops.length == 1) {
                    _selectedShopId = _shops.first.id;
                  }
                }),
              ),
              const SizedBox(height: AppDims.s2),
              RoleHint(role: _selectedRole),
              const SizedBox(height: AppDims.s4),

              // ── Shop assignment ────────────────────────────────────
              // Multi-shop picker: visible for cashier + 2+ shops
              if (_showShopPicker) ...[
                FieldLabel(label: 'Assigned Shop', required: true),
                const SizedBox(height: AppDims.s1),
                _ShopDropdown(
                  shops:          _shops,
                  selectedShopId: _selectedShopId,
                  onChanged: (shopId) =>
                      setState(() => _selectedShopId = shopId),
                ),
                const SizedBox(height: AppDims.s2),
                _ShopAssignmentHint(
                  selectedShopId: _selectedShopId,
                  shops:          _shops,
                ),
                const SizedBox(height: AppDims.s4),
              ],

              // Auto-assigned confirmation: visible for cashier + 1 shop
              if (_showShopConfirmation) ...[
                _AutoAssignedChip(shopName: _shops.first.name ?? 'Shop'),
                const SizedBox(height: AppDims.s4),
              ],

              UserSubmitButton(label: 'Create User', onPressed: _submit),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Phone error ───────────────────────────────────────────────────────────────

class _PhoneError extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.error_outline, size: 13, color: context.appColors.danger),
        const SizedBox(width: 4),
        Text(
          'Enter a valid phone number',
          style: AppTextStyles.sm200(context,
              color: context.appColors.danger),
        ),
      ],
    );
  }
}

// ── Auto-assigned chip (single shop) ─────────────────────────────────────────

class _AutoAssignedChip extends StatelessWidget {
  final String shopName;
  const _AutoAssignedChip({required this.shopName});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsets.all(AppDims.s3),
      decoration: BoxDecoration(
        color:        const Color(0xFF16A34A).withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(AppDims.rMd),
        border: Border.all(
            color: const Color(0xFF16A34A).withValues(alpha: 0.20)),
      ),
      child: Row(
        children: [
          const Icon(Icons.storefront_rounded,
              size: 16, color: Color(0xFF16A34A)),
          const SizedBox(width: AppDims.s2),
          Expanded(
            child: Text(
              'Will be assigned to $shopName automatically.',
              style: AppTextStyles.bs200(context).copyWith(
                color:      colors.textSecondary,
                fontWeight: FontWeight.w600,
                height:     1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shop dropdown (shared style with edit sheet) ──────────────────────────────

class _ShopDropdown extends StatelessWidget {
  final List<ShopData>        shops;
  final String?               selectedShopId;
  final ValueChanged<String?> onChanged;

  const _ShopDropdown({
    required this.shops,
    required this.selectedShopId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
      height:  52,
      padding: const EdgeInsets.symmetric(horizontal: AppDims.s3),
      decoration: BoxDecoration(
        color:        colors.surfaceSoft,
        borderRadius: BorderRadius.circular(AppDims.rMd),
        border:       Border.all(color: colors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value:      selectedShopId,
          isExpanded: true,
          hint: Text(
            'Select a shop',
            style: AppTextStyles.bs400(context).copyWith(
              color: colors.textHint,
            ),
          ),
          icon: Icon(Icons.keyboard_arrow_down_rounded,
              color: colors.textHint),
          style: AppTextStyles.bs400(context).copyWith(
            color:      colors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
          items: shops.map((shop) => DropdownMenuItem<String?>(
            value: shop.id,
            child: Row(
              children: [
                Icon(Icons.storefront_rounded,
                    size: 18, color: colors.primary),
                const SizedBox(width: AppDims.s2),
                Expanded(
                  child: Text(
                    shop.name ?? 'Shop',
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bs400(context).copyWith(
                      color:      colors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          )).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

// ── Shop assignment hint ──────────────────────────────────────────────────────

class _ShopAssignmentHint extends StatelessWidget {
  final String?        selectedShopId;
  final List<ShopData> shops;

  const _ShopAssignmentHint({
    required this.selectedShopId,
    required this.shops,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    if (selectedShopId == null) {
      return Container(
        padding: const EdgeInsets.all(AppDims.s3),
        decoration: BoxDecoration(
          color: const Color(0xFFF59E0B).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppDims.rMd),
          border: Border.all(
              color: const Color(0xFFF59E0B).withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            const Icon(Icons.warning_amber_rounded,
                size: 16, color: Color(0xFFF59E0B)),
            const SizedBox(width: AppDims.s2),
            Expanded(
              child: Text(
                'Cashiers must be assigned to a shop to process sales.',
                style: AppTextStyles.bs200(context).copyWith(
                  color:      colors.textSecondary,
                  fontWeight: FontWeight.w600,
                  height:     1.4,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final name = shops
        .where((s) => s.id == selectedShopId)
        .map((s) => s.name ?? 'Shop')
        .firstOrNull;

    return Container(
      padding: const EdgeInsets.all(AppDims.s3),
      decoration: BoxDecoration(
        color: const Color(0xFF16A34A).withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(AppDims.rMd),
        border: Border.all(
            color: const Color(0xFF16A34A).withValues(alpha: 0.20)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline_rounded,
              size: 16, color: Color(0xFF16A34A)),
          const SizedBox(width: AppDims.s2),
          Expanded(
            child: Text(
              'Cashier will be assigned to ${name ?? 'this shop'}.',
              style: AppTextStyles.bs200(context).copyWith(
                color:      colors.textSecondary,
                fontWeight: FontWeight.w600,
                height:     1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
