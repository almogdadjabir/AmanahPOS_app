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
import 'package:solar_icons/solar_icons.dart';

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
  final _formKey = GlobalKey<FormState>();

  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  final _nameFocus = FocusNode();
  final _phoneFocus = FocusNode();

  bool _phoneError = false;
  String _selectedRole = 'cashier';
  String? _selectedShopId;

  List<ShopData> get _shops {
    return context.read<AuthBloc>().state.defaultBusiness?.shops
        ?.where((shop) {
      final id = shop.id;
      final isActive = shop.isActive ?? true;
      return id != null && id.trim().isNotEmpty && isActive;
    }).toList() ??
        [];
  }

  bool get _isCashier => _selectedRole == 'cashier';

  bool get _showShopPicker => _isCashier && _shops.length >= 2;

  bool get _showShopConfirmation => _isCashier && _shops.length == 1;

  String get _fullPhone => '+249${_phoneCtrl.text.trim()}';

  bool get _isPhoneValid {
    final digits = _phoneCtrl.text.trim();
    return digits.length >= phoneMaxLength(digits);
  }

  @override
  void initState() {
    super.initState();

    final shops = _shops;
    if (shops.length == 1) {
      _selectedShopId = shops.first.id;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _nameFocus.dispose();
    _phoneFocus.dispose();
    super.dispose();
  }

  void _onRoleSelected(String role) {
    if (!_kAddRoles.contains(role)) return;

    setState(() {
      _selectedRole = role;

      if (role != 'cashier') {
        _selectedShopId = null;
        return;
      }

      final shops = _shops;
      if (shops.length == 1) {
        _selectedShopId = shops.first.id;
      }
    });
  }

  void _submit() {
    if (_formKey.currentState?.validate() != true) return;

    if (!_isPhoneValid) {
      setState(() => _phoneError = true);
      return;
    }

    if (!_kAddRoles.contains(_selectedRole)) {
      GlobalSnackBar.show(
        message: 'Invalid role selected',
        isError: true,
      );
      return;
    }

    if (_isCashier && _shops.length >= 2 && _selectedShopId == null) {
      GlobalSnackBar.show(
        message: 'Please assign this cashier to a shop.',
        isError: true,
      );
      return;
    }

    context.read<UserBloc>().add(
      OnAddUser(
        phone: _fullPhone,
        fullName: _nameCtrl.text.trim(),
        role: _selectedRole,
        shopId: _selectedShopId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<UserBloc, UserState>(
      listenWhen: (prev, curr) => prev.submitStatus != curr.submitStatus,
      listener: (context, state) {
        if (state.submitStatus == UserSubmitStatus.success) {
          Navigator.of(context).pop();

          GlobalSnackBar.show(
            message: 'User added successfully',
            isInfo: true,
          );
        }

        if (state.submitStatus == UserSubmitStatus.failure) {
          GlobalSnackBar.show(
            message: state.submitError ?? 'Something went wrong',
            isError: true,
            isAutoDismiss: false,
          );
        }
      },
      child: ProductSheetShell(
        title: 'New User',
        body: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _InfoBanner(
                icon: SolarIconsOutline.userPlus,
                title: 'Create staff account',
                message:
                'Only cashier and manager accounts can be created here.',
                color: context.appColors.primary,
              ),

              const SizedBox(height: AppDims.s4),

              FieldLabel(
                label: 'Full Name',
                required: true,
              ),
              const SizedBox(height: AppDims.s1),
              AppFormField(
                controller: _nameCtrl,
                focusNode: _nameFocus,
                nextFocus: _phoneFocus,
                hint: 'Ali Hassan',
                prefixIcon: SolarIconsOutline.user,
                textInputAction: TextInputAction.next,
                validator: (value) {
                  final text = value?.trim() ?? '';

                  if (text.isEmpty) {
                    return 'Full name is required';
                  }

                  if (text.length < 2) {
                    return 'Name must be at least 2 characters';
                  }

                  return null;
                },
              ),

              const SizedBox(height: AppDims.s3),

              FieldLabel(
                label: 'Phone',
                required: true,
              ),
              const SizedBox(height: AppDims.s1),
              PhoneNumberField(
                controller: _phoneCtrl,
                focusNode: _phoneFocus,
                error: _phoneError,
                onChanged: (_) {
                  if (_phoneError) {
                    setState(() => _phoneError = false);
                  }
                },
              ),
              SizedBox(
                height: 24,
                child: _phoneError ? const _PhoneError() : const SizedBox.shrink(),
              ),

              const SizedBox(height: AppDims.s3),

              FieldLabel(
                label: 'Role',
                required: true,
              ),
              const SizedBox(height: AppDims.s2),
              RolePicker(
                roles: _kAddRoles,
                selectedRole: _selectedRole,
                onSelected: _onRoleSelected,
              ),

              const SizedBox(height: AppDims.s2),
              RoleHint(role: _selectedRole),

              const SizedBox(height: AppDims.s4),

              if (_showShopPicker) ...[
                FieldLabel(
                  label: 'Assigned Shop',
                  required: true,
                ),
                const SizedBox(height: AppDims.s1),
                _ShopDropdown(
                  shops: _shops,
                  selectedShopId: _selectedShopId,
                  onChanged: (shopId) {
                    setState(() => _selectedShopId = shopId);
                  },
                ),
                const SizedBox(height: AppDims.s2),
                _ShopAssignmentHint(
                  selectedShopId: _selectedShopId,
                  shops: _shops,
                ),
                const SizedBox(height: AppDims.s4),
              ],

              if (_showShopConfirmation) ...[
                _AutoAssignedChip(
                  shopName: _shops.first.name ?? 'Shop',
                ),
                const SizedBox(height: AppDims.s4),
              ],

              BlocBuilder<UserBloc, UserState>(
                buildWhen: (prev, curr) {
                  return prev.submitStatus != curr.submitStatus;
                },
                builder: (context, state) {
                  final isLoading =
                      state.submitStatus == UserSubmitStatus.loading;

                  return UserSubmitButton(
                    label: isLoading ? 'Creating...' : 'Create User',
                    onPressed: isLoading ? null : _submit,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PhoneError extends StatelessWidget {
  const _PhoneError();

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Row(
      children: [
        Icon(
          SolarIconsOutline.dangerCircle,
          size: 14,
          color: colors.danger,
        ),
        const SizedBox(width: 5),
        Text(
          'Enter a valid phone number',
          style: AppTextStyles.sm200(
            context,
            color: colors.danger,
          ).copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _AutoAssignedChip extends StatelessWidget {
  final String shopName;

  const _AutoAssignedChip({
    required this.shopName,
  });

  @override
  Widget build(BuildContext context) {
    const color = Color(0xFF16A34A);
    final colors = context.appColors;

    return Container(
      padding: const EdgeInsets.all(AppDims.s3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppDims.rLg),
        border: Border.all(
          color: color.withValues(alpha: 0.20),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            SolarIconsOutline.shop,
            size: 18,
            color: color,
          ),
          const SizedBox(width: AppDims.s2),
          Expanded(
            child: Text(
              'Will be assigned to $shopName automatically.',
              style: AppTextStyles.bs200(context).copyWith(
                color: colors.textSecondary,
                fontWeight: FontWeight.w700,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ShopDropdown extends StatelessWidget {
  final List<ShopData> shops;
  final String? selectedShopId;
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
      height: 54,
      padding: const EdgeInsets.symmetric(horizontal: AppDims.s3),
      decoration: BoxDecoration(
        color: colors.surfaceSoft,
        borderRadius: BorderRadius.circular(AppDims.rMd),
        border: Border.all(
          color: colors.border,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: selectedShopId,
          isExpanded: true,
          hint: Text(
            'Select a shop',
            style: AppTextStyles.bs400(context).copyWith(
              color: colors.textHint,
              fontWeight: FontWeight.w600,
            ),
          ),
          icon: Icon(
            SolarIconsOutline.altArrowDown,
            color: colors.textHint,
            size: 19,
          ),
          style: AppTextStyles.bs400(context).copyWith(
            color: colors.textPrimary,
            fontWeight: FontWeight.w800,
          ),
          items: shops.map((shop) {
            return DropdownMenuItem<String?>(
              value: shop.id,
              child: Row(
                children: [
                  Icon(
                    SolarIconsOutline.shop,
                    size: 18,
                    color: colors.primary,
                  ),
                  const SizedBox(width: AppDims.s2),
                  Expanded(
                    child: Text(
                      shop.name ?? 'Shop',
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bs400(context).copyWith(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _ShopAssignmentHint extends StatelessWidget {
  final String? selectedShopId;
  final List<ShopData> shops;

  const _ShopAssignmentHint({
    required this.selectedShopId,
    required this.shops,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    if (selectedShopId == null) {
      return _InfoBanner(
        icon: SolarIconsOutline.dangerTriangle,
        title: 'Shop required',
        message: 'Cashiers must be assigned to a shop to process sales.',
        color: const Color(0xFFF59E0B),
      );
    }

    final shopName = shops
        .where((shop) => shop.id == selectedShopId)
        .map((shop) => shop.name ?? 'Shop')
        .firstOrNull;

    return _InfoBanner(
      icon: SolarIconsOutline.checkCircle,
      title: 'Shop assigned',
      message: 'Cashier will be assigned to ${shopName ?? 'this shop'}.',
      color: const Color(0xFF16A34A),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final Color color;

  const _InfoBanner({
    required this.icon,
    required this.title,
    required this.message,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDims.s3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppDims.rLg),
        border: Border.all(
          color: color.withValues(alpha: 0.16),
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: color,
            size: 21,
          ),
          const SizedBox(width: AppDims.s2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.bs300(context).copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  message,
                  style: AppTextStyles.bs200(context).copyWith(
                    color: colors.textSecondary,
                    fontWeight: FontWeight.w700,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}