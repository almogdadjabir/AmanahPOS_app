// lib/features/users/presentation/widgets/edit_user_sheet.dart
//
// Added: shop picker dropdown using business.shops
// Calls OnAssignUserShop when shop selection changes
// Shows "Unassigned" in amber when default_shop_id is null

import 'package:amana_pos/common/auth_bloc/auth_bloc.dart';
import 'package:amana_pos/features/business/data/models/responses/business_response_dto.dart';
import 'package:amana_pos/features/products/presentation/widgets/product_sheet_shell.dart';
import 'package:amana_pos/features/users/data/models/responses/user_response_dto.dart';
import 'package:amana_pos/features/users/presentation/bloc/users_bloc.dart';
import 'package:amana_pos/features/users/presentation/widgets/user_sheet_widgets.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/utilities/global_snackbar.dart';
import 'package:amana_pos/widgets/field_label.dart';
import 'package:amana_pos/widgets/form_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

const _kEditRoles = ['cashier', 'manager', 'admin'];

void showEditUserSheet(BuildContext context, {required UserData user}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => MultiBlocProvider(
      providers: [
        BlocProvider.value(value: context.read<UserBloc>()),
        BlocProvider.value(value: context.read<AuthBloc>()),
      ],
      child: _EditUserSheet(user: user),
    ),
  );
}

class _EditUserSheet extends StatefulWidget {
  final UserData user;
  const _EditUserSheet({required this.user});

  @override
  State<_EditUserSheet> createState() => _EditUserSheetState();
}

class _EditUserSheetState extends State<_EditUserSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late String  _selectedRole;
  String?      _selectedShopId;   // MULTI-SHOP
  bool         _shopChanged = false;

  // Shops available from the business
  List<ShopData> get _shops =>
      context.read<AuthBloc>().state.defaultBusiness?.shops
          ?.where((s) => s.id != null && (s.isActive ?? true))
          .toList() ??
          [];

  bool get _hasChanges =>
      _nameCtrl.text.trim() != (widget.user.fullName ?? '') ||
          _selectedRole != (widget.user.role ?? '') ||
          _shopChanged;

  @override
  void initState() {
    super.initState();
    _nameCtrl     = TextEditingController(text: widget.user.fullName ?? '');
    _selectedRole = widget.user.role ?? 'cashier';
    _selectedShopId = widget.user.defaultShopId; // pre-select current shop
    _nameCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (!_hasChanges) return;

    // Profile fields changed
    if (_nameCtrl.text.trim() != (widget.user.fullName ?? '') ||
        _selectedRole != (widget.user.role ?? '')) {
      context.read<UserBloc>().add(OnEditUser(
        userId:   widget.user.id!,
        fullName: _nameCtrl.text.trim(),
        role:     _selectedRole,
      ));
    }

    // Shop assignment changed
    if (_shopChanged) {
      context.read<UserBloc>().add(OnAssignUserShop(
        userId: widget.user.id!,
        shopId: _selectedShopId, // null = unassign
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<UserBloc, UserState>(
      listenWhen: (prev, curr) => prev.submitStatus != curr.submitStatus,
      listener: (context, state) {
        if (state.submitStatus == UserSubmitStatus.success) {
          Navigator.of(context).pop();
          GlobalSnackBar.show(message: 'User updated', isInfo: true);
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
        title:    'Edit User',
        subtitle: widget.user.fullName,
        body: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // Full name
              FieldLabel(label: 'Full Name', required: true),
              const SizedBox(height: AppDims.s1),
              AppFormField(
                controller: _nameCtrl,
                hint:       'Ali Hassan',
                prefixIcon: Icons.person_outline_rounded,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Name is required';
                  if (v.trim().length < 2)
                    return 'Name must be at least 2 characters';
                  return null;
                },
              ),
              const SizedBox(height: AppDims.s4),

              // Role picker
              FieldLabel(label: 'Role', required: true),
              const SizedBox(height: AppDims.s2),
              RolePicker(
                roles:        _kEditRoles,
                selectedRole: _selectedRole,
                onSelected:   (r) => setState(() => _selectedRole = r),
              ),
              const SizedBox(height: AppDims.s4),

              // MULTI-SHOP: shop assignment — only show when business has shops
              if (_shops.isNotEmpty) ...[
                FieldLabel(label: 'Assigned Shop'),
                const SizedBox(height: AppDims.s1),
                _ShopDropdown(
                  shops:          _shops,
                  selectedShopId: _selectedShopId,
                  onChanged:      (shopId) {
                    setState(() {
                      _selectedShopId = shopId;
                      _shopChanged    = true;
                    });
                  },
                ),
                const SizedBox(height: AppDims.s2),
                _ShopAssignmentHint(
                  selectedShopId: _selectedShopId,
                  shops:          _shops,
                ),
                const SizedBox(height: AppDims.s4),
              ],

              UserSubmitButton(
                label:     'Save Changes',
                onPressed: _submit,
                enabled:   _hasChanges,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Shop dropdown ─────────────────────────────────────────────────────────────

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
          value:    selectedShopId,
          isExpanded: true,
          icon: Icon(Icons.keyboard_arrow_down_rounded,
              color: colors.textHint),
          style: AppTextStyles.bs400(context).copyWith(
            color:      colors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
          items: [
            // Unassign option
            DropdownMenuItem<String?>(
              value: null,
              child: Row(
                children: [
                  Icon(Icons.store_outlined,
                      size: 18, color: colors.textHint),
                  const SizedBox(width: AppDims.s2),
                  Text(
                    'Unassigned',
                    style: AppTextStyles.bs400(context).copyWith(
                      color:      const Color(0xFFF59E0B),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            // One item per shop
            ...shops.map((shop) => DropdownMenuItem<String?>(
              value: shop.id,
              child: Row(
                children: [
                  Icon(Icons.storefront_rounded,
                      size: 18, color: colors.primary),
                  const SizedBox(width: AppDims.s2),
                  Expanded(
                    child: Text(
                      shop.name ?? 'Shop',
                      overflow:  TextOverflow.ellipsis,
                      style: AppTextStyles.bs400(context).copyWith(
                        color:      colors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            )),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}

// ── Shop assignment hint card ─────────────────────────────────────────────────

class _ShopAssignmentHint extends StatelessWidget {
  final String?       selectedShopId;
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
          color:        const Color(0xFFF59E0B).withValues(alpha: 0.08),
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
                'This cashier is not assigned to any shop and cannot process sales.',
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

    final shopName = shops
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
              'Assigned to ${shopName ?? 'shop'}. Cashier can process sales at this shop.',
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