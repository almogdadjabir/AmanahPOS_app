import 'package:amana_pos/common/auth_bloc/auth_bloc.dart';
import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/core/responsive/adaptive_sheet.dart';
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
import 'package:solar_icons/solar_icons.dart';

const _kEditRoles = ['cashier', 'manager'];

void showEditUserSheet(BuildContext context, {required UserData user}) {
  final userBloc = context.read<UserBloc>();
  final authBloc = context.read<AuthBloc>();

  showAdaptivePanel(
    context,
    desktopWidth: 480,
    builder: (_) => MultiBlocProvider(
      providers: [
        BlocProvider.value(value: userBloc),
        BlocProvider.value(value: authBloc),
      ],
      child: _EditUserSheet(user: user),
    ),
  );
}

class _EditUserSheet extends StatefulWidget {
  final UserData user;

  const _EditUserSheet({
    required this.user,
  });

  @override
  State<_EditUserSheet> createState() => _EditUserSheetState();
}

class _EditUserSheetState extends State<_EditUserSheet> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameCtrl;
  late final List<ShopData> _shops;

  late final String _initialName;
  late final String _initialRole;
  late final String? _initialShopId;

  late String _selectedRole;
  String? _selectedShopId;

  bool get _isCashier => _selectedRole == 'cashier';

  bool get _hasChanges {
    final currentName = _nameCtrl.text.trim();

    return currentName != _initialName ||
        _selectedRole != _initialRole ||
        _selectedShopId != _initialShopId;
  }

  @override
  void initState() {
    super.initState();

    _initialName = widget.user.fullName?.trim() ?? '';
    _initialRole = _safeInitialRole(widget.user.role);
    _initialShopId = widget.user.defaultShopId?.trim();

    _nameCtrl = TextEditingController(text: _initialName);
    _selectedRole = _initialRole;
    _selectedShopId = _initialShopId;

    _shops = _activeShopsFromAuth();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
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

  String _safeInitialRole(String? role) {
    final normalized = role?.toLowerCase().trim();

    if (normalized == 'manager') return 'manager';
    if (normalized == 'cashier') return 'cashier';

    return 'cashier';
  }

  void _onRoleSelected(String role) {
    final normalized = role.toLowerCase().trim();

    if (!_kEditRoles.contains(normalized)) {
      GlobalSnackBar.show(
        message: context.tr.adminRoleCannotBeAssigned,
        isError: true,
      );
      return;
    }

    setState(() {
      _selectedRole = normalized;

      if (normalized != 'cashier') {
        _selectedShopId = null;
      }
    });
  }

  void _submit() {
    final tr = context.tr;

    final formState = _formKey.currentState;
    if (formState == null || !formState.validate()) return;
    if (!_hasChanges) return;

    final userId = widget.user.id?.trim();

    if (userId == null || userId.isEmpty) {
      GlobalSnackBar.show(
        message: tr.invalidUserSelected,
        isError: true,
      );
      return;
    }

    if (!_kEditRoles.contains(_selectedRole)) {
      GlobalSnackBar.show(
        message: tr.adminRoleCannotBeAssigned,
        isError: true,
      );
      return;
    }

    final currentName = _nameCtrl.text.trim();
    final nameChanged = currentName != _initialName;
    final roleChanged = _selectedRole != _initialRole;
    final shopChanged = _selectedShopId != _initialShopId;

    if (nameChanged || roleChanged) {
      context.read<UserBloc>().add(
        OnEditUser(
          userId: userId,
          fullName: currentName,
          role: _selectedRole,
        ),
      );
    }

    if (shopChanged) {
      context.read<UserBloc>().add(
        OnAssignUserShop(
          userId: userId,
          shopId: _isCashier ? _selectedShopId : null,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    final subtitle = widget.user.fullName?.trim();

    return BlocListener<UserBloc, UserState>(
      listenWhen: (prev, curr) => prev.submitStatus != curr.submitStatus,
      listener: (context, state) {
        if (state.submitStatus == UserSubmitStatus.success) {
          Navigator.of(context).pop();

          GlobalSnackBar.show(
            message: context.tr.userUpdatedSuccessfully,
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
        title: tr.editUser,
        subtitle: subtitle?.isNotEmpty == true ? subtitle : null,
        body: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _InfoBanner(
                icon: SolarIconsOutline.penNewSquare,
                title: tr.editStaffAccount,
                message: tr.editStaffAccountMessage,
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
                hint: tr.fullNameHint,
                prefixIcon: SolarIconsOutline.user,
                textInputAction: TextInputAction.next,
                validator: (value) {
                  final text = value?.trim() ?? '';

                  if (text.isEmpty) {
                    return tr.nameRequired;
                  }

                  if (text.length < 2) {
                    return tr.nameMustBeAtLeast2Characters;
                  }

                  return null;
                },
              ),

              const SizedBox(height: AppDims.s4),

              FieldLabel(
                label: tr.fieldRole,
                required: true,
              ),
              const SizedBox(height: AppDims.s2),
              RolePicker(
                roles: _kEditRoles,
                selectedRole: _selectedRole,
                onSelected: _onRoleSelected,
              ),

              const SizedBox(height: AppDims.s4),

              if (_shops.isNotEmpty && _isCashier) ...[
                FieldLabel(label: tr.fieldAssignedShop),
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

              if (!_isCashier) ...[
                _InfoBanner(
                  icon: SolarIconsOutline.shieldUser,
                  title: tr.managerAccess,
                  message: tr.managerAccessMessage,
                  color: const Color(0xFF0EA5E9),
                ),
                const SizedBox(height: AppDims.s4),
              ],

              AnimatedBuilder(
                animation: _nameCtrl,
                builder: (context, _) {
                  return BlocSelector<UserBloc, UserState, UserSubmitStatus>(
                    selector: (state) => state.submitStatus,
                    builder: (context, submitStatus) {
                      final isLoading = submitStatus == UserSubmitStatus.loading;

                      return UserSubmitButton(
                        label: tr.saveChanges,
                        onPressed: isLoading ? null : _submit,
                        enabled: _hasChanges && !isLoading,
                      );
                    },
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
              icon: Icon(
                SolarIconsOutline.altArrowDown,
                color: colors.textHint,
                size: 19,
              ),
              style: AppTextStyles.bs400(context).copyWith(
                color: colors.textPrimary,
                fontWeight: FontWeight.w800,
              ),
              items: [
                DropdownMenuItem<String?>(
                  value: null,
                  child: Row(
                    children: [
                      Icon(
                        SolarIconsOutline.shop,
                        size: 18,
                        color: colors.textHint,
                      ),
                      const SizedBox(width: AppDims.s2),
                      Expanded(
                        child: Text(
                          tr.unassigned,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.bs400(context).copyWith(
                            color: const Color(0xFFF59E0B),
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                ...shops.map((shop) {
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
                }),
              ],
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
        title: context.tr.unassignedCashier,
        message: context.tr.unassignedCashierMessage,
        color: const Color(0xFFF59E0B),
      );
    }

    final shopName = _findShopName(context, selectedShopId, shops);

    return _InfoBanner(
      icon: SolarIconsOutline.checkCircle,
      title: context.tr.shopAssigned,
      message: context.tr.cashierAssignedToShopDetailed(shopName),
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
        return name?.isNotEmpty == true ? name! : context.tr.shop;
      }
    }

    return context.tr.shop;
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