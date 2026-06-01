import 'package:amana_pos/common/auth_bloc/auth_bloc.dart';
import 'package:amana_pos/common/localization/app_localizations_extension.dart';
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
  final userBloc = context.read<UserBloc>();
  final authBloc = context.read<AuthBloc>();

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => MultiBlocProvider(
      providers: [
        BlocProvider.value(value: userBloc),
        BlocProvider.value(value: authBloc),
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

  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;

  late final FocusNode _nameFocus;
  late final FocusNode _phoneFocus;

  late final List<ShopData> _shops;

  bool _phoneError = false;
  String _selectedRole = 'cashier';
  String? _selectedShopId;

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

    _nameCtrl = TextEditingController();
    _phoneCtrl = TextEditingController();

    _nameFocus = FocusNode();
    _phoneFocus = FocusNode();

    _shops = _activeShopsFromAuth();

    if (_shops.length == 1) {
      _selectedShopId = _shops.first.id;
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

  List<ShopData> _activeShopsFromAuth() {
    final shops = context.read<AuthBloc>().state.defaultBusiness?.shops;

    if (shops == null || shops.isEmpty) {
      return const [];
    }

    final activeShops = <ShopData>[];

    for (final shop in shops) {
      final id = shop.id?.trim();
      final isActive = shop.isActive ?? true;

      if (id != null && id.isNotEmpty && isActive) {
        activeShops.add(shop);
      }
    }

    return List.unmodifiable(activeShops);
  }

  void _onRoleSelected(String role) {
    if (!_kAddRoles.contains(role)) return;

    setState(() {
      _selectedRole = role;

      if (role != 'cashier') {
        _selectedShopId = null;
        return;
      }

      if (_shops.length == 1) {
        _selectedShopId = _shops.first.id;
      }
    });
  }

  void _submit() {
    final tr = context.tr;

    final formState = _formKey.currentState;
    if (formState == null || !formState.validate()) return;

    if (!_isPhoneValid) {
      setState(() => _phoneError = true);
      return;
    }

    if (!_kAddRoles.contains(_selectedRole)) {
      GlobalSnackBar.show(
        message: tr.invalidRoleSelected,
        isError: true,
      );
      return;
    }

    if (_isCashier && _shops.length >= 2 && _selectedShopId == null) {
      GlobalSnackBar.show(
        message: tr.assignCashierToShopRequired,
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
    final tr = context.tr;

    return BlocListener<UserBloc, UserState>(
      listenWhen: (prev, curr) => prev.submitStatus != curr.submitStatus,
      listener: (context, state) {
        if (state.submitStatus == UserSubmitStatus.success) {
          Navigator.of(context).pop();

          GlobalSnackBar.show(
            message: context.tr.userAddedSuccessfully,
            isInfo: true,
          );
          return;
        }

        if (state.submitStatus == UserSubmitStatus.failure) {
          GlobalSnackBar.show(
            message: state.submitError ?? context.tr.somethingWentWrong,
            isError: true,
            isAutoDismiss: false,
          );
        }
      },
      child: ProductSheetShell(
        title: tr.newUser,
        body: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _InfoBanner(
                icon: SolarIconsOutline.userPlus,
                title: tr.createStaffAccount,
                message: tr.createStaffAccountMessage,
                color: context.appColors.primary,
              ),

              const SizedBox(height: AppDims.s4),

              FieldLabel(
                label: tr.fieldFullName,
                required: true,
              ),
              const SizedBox(height: AppDims.s1),
              AppFormField(
                controller: _nameCtrl,
                focusNode: _nameFocus,
                nextFocus: _phoneFocus,
                hint: tr.fullNameHint,
                prefixIcon: SolarIconsOutline.user,
                textInputAction: TextInputAction.next,
                validator: (value) {
                  final text = value?.trim() ?? '';

                  if (text.isEmpty) {
                    return tr.fullNameRequired;
                  }

                  if (text.length < 2) {
                    return tr.nameMustBeAtLeast2Characters;
                  }

                  return null;
                },
              ),

              const SizedBox(height: AppDims.s3),

              FieldLabel(
                label: tr.fieldPhone,
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
                child: _phoneError
                    ? const _PhoneError()
                    : const SizedBox.shrink(),
              ),

              const SizedBox(height: AppDims.s3),

              FieldLabel(
                label: tr.fieldRole,
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
                  label: tr.fieldAssignedShop,
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
                  shopName: _shops.first.name?.trim().isNotEmpty == true
                      ? _shops.first.name!.trim()
                      : tr.shop,
                ),
                const SizedBox(height: AppDims.s4),
              ],

              BlocSelector<UserBloc, UserState, UserSubmitStatus>(
                selector: (state) => state.submitStatus,
                builder: (context, submitStatus) {
                  final isLoading = submitStatus == UserSubmitStatus.loading;

                  return UserSubmitButton(
                    label: tr.createUser,
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
        Expanded(
          child: Text(
            context.tr.enterValidPhoneNumber,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.sm200(
              context,
              color: colors.danger,
            ).copyWith(
              fontWeight: FontWeight.w700,
            ),
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

    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppDims.rLg),
        border: Border.all(
          color: color.withValues(alpha: 0.20),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppDims.s3),
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
                context.tr.autoAssignCashierToShop(shopName),
                style: AppTextStyles.bs200(context).copyWith(
                  color: colors.textSecondary,
                  fontWeight: FontWeight.w700,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
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
    final tr = context.tr;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceSoft,
        borderRadius: BorderRadius.circular(AppDims.rMd),
        border: Border.all(color: colors.border),
      ),
      child: SizedBox(
        height: 54,
        child: Padding(
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppDims.s3,
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String?>(
              value: selectedShopId,
              isExpanded: true,
              hint: Text(
                tr.selectShop,
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
                final shopName = shop.name?.trim();

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
                          shopName?.isNotEmpty == true
                              ? shopName!
                              : tr.shop,
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
              }).toList(growable: false),
              onChanged: onChanged,
            ),
          ),
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
    if (selectedShopId == null) {
      return _InfoBanner(
        icon: SolarIconsOutline.dangerTriangle,
        title: context.tr.shopRequired,
        message: context.tr.cashierShopRequiredMessage,
        color: const Color(0xFFF59E0B),
      );
    }

    final shopName = _findShopName(context, selectedShopId, shops);

    return _InfoBanner(
      icon: SolarIconsOutline.checkCircle,
      title: context.tr.shopAssigned,
      message: context.tr.cashierAssignedToShop(shopName),
      color: const Color(0xFF16A34A),
    );
  }

  String _findShopName(
      BuildContext context,
      String? selectedShopId,
      List<ShopData> shops,
      ) {
    for (final shop in shops) {
      if (shop.id == selectedShopId) {
        final name = shop.name?.trim();
        return name?.isNotEmpty == true ? name! : context.tr.thisShop;
      }
    }

    return context.tr.thisShop;
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

    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppDims.rLg),
        border: Border.all(
          color: color.withValues(alpha: 0.16),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppDims.s3),
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
      ),
    );
  }
}