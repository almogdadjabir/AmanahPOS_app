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
import 'package:solar_icons/solar_icons.dart';

const _kEditRoles = ['cashier', 'manager'];

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

  const _EditUserSheet({
    required this.user,
  });

  @override
  State<_EditUserSheet> createState() => _EditUserSheetState();
}

class _EditUserSheetState extends State<_EditUserSheet> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameCtrl;

  late String _selectedRole;
  String? _selectedShopId;
  bool _shopChanged = false;

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

  bool get _hasChanges {
    final originalName = widget.user.fullName?.trim() ?? '';
    final originalRole = _safeInitialRole(widget.user.role);
    final currentName = _nameCtrl.text.trim();

    return currentName != originalName ||
        _selectedRole != originalRole ||
        _shopChanged;
  }

  @override
  void initState() {
    super.initState();

    _nameCtrl = TextEditingController(text: widget.user.fullName ?? '');
    _selectedRole = _safeInitialRole(widget.user.role);
    _selectedShopId = widget.user.defaultShopId;

    _nameCtrl.addListener(_onNameChanged);
  }

  void _onNameChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _nameCtrl.removeListener(_onNameChanged);
    _nameCtrl.dispose();
    super.dispose();
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
        message: 'Admin role cannot be assigned from the app',
        isError: true,
      );
      return;
    }

    setState(() {
      _selectedRole = normalized;

      if (normalized != 'cashier') {
        _selectedShopId = null;
        _shopChanged = true;
      }
    });
  }

  void _submit() {
    if (_formKey.currentState?.validate() != true) return;
    if (!_hasChanges) return;

    final userId = widget.user.id;

    if (userId == null || userId.trim().isEmpty) {
      GlobalSnackBar.show(
        message: 'Invalid user selected',
        isError: true,
      );
      return;
    }

    if (!_kEditRoles.contains(_selectedRole)) {
      GlobalSnackBar.show(
        message: 'Admin role cannot be assigned from the app',
        isError: true,
      );
      return;
    }

    final originalName = widget.user.fullName?.trim() ?? '';
    final originalRole = _safeInitialRole(widget.user.role);
    final nameChanged = _nameCtrl.text.trim() != originalName;
    final roleChanged = _selectedRole != originalRole;

    if (nameChanged || roleChanged) {
      context.read<UserBloc>().add(
        OnEditUser(
          userId: userId,
          fullName: _nameCtrl.text.trim(),
          role: _selectedRole,
        ),
      );
    }

    if (_shopChanged) {
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
    return BlocListener<UserBloc, UserState>(
      listenWhen: (prev, curr) {
        return prev.submitStatus != curr.submitStatus;
      },
      listener: (context, state) {
        if (state.submitStatus == UserSubmitStatus.success) {
          Navigator.of(context).pop();

          GlobalSnackBar.show(
            message: 'User updated',
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
        title: 'Edit User',
        subtitle: widget.user.fullName,
        body: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _InfoBanner(
                icon: SolarIconsOutline.penNewSquare,
                title: 'Edit staff account',
                message:
                'Only cashier and manager roles can be assigned from here.',
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
                hint: 'Ali Hassan',
                prefixIcon: SolarIconsOutline.user,
                textInputAction: TextInputAction.next,
                validator: (value) {
                  final text = value?.trim() ?? '';

                  if (text.isEmpty) {
                    return 'Name is required';
                  }

                  if (text.length < 2) {
                    return 'Name must be at least 2 characters';
                  }

                  return null;
                },
              ),

              const SizedBox(height: AppDims.s4),

              FieldLabel(
                label: 'Role',
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
                FieldLabel(label: 'Assigned Shop'),
                const SizedBox(height: AppDims.s1),
                _ShopDropdown(
                  shops: _shops,
                  selectedShopId: _selectedShopId,
                  onChanged: (shopId) {
                    setState(() {
                      _selectedShopId = shopId;
                      _shopChanged = true;
                    });
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
                  title: 'Manager access',
                  message:
                  'Managers are not assigned to a single shop. They can manage business operations based on their permissions.',
                  color: const Color(0xFF0EA5E9),
                ),
                const SizedBox(height: AppDims.s4),
              ],

              UserSubmitButton(
                label: 'Save Changes',
                onPressed: _submit,
                enabled: _hasChanges,
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
                  Text(
                    'Unassigned',
                    style: AppTextStyles.bs400(context).copyWith(
                      color: const Color(0xFFF59E0B),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            ...shops.map((shop) {
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
            }),
          ],
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
    if (selectedShopId == null) {
      return _InfoBanner(
        icon: SolarIconsOutline.dangerTriangle,
        title: 'Unassigned cashier',
        message:
        'This cashier is not assigned to any shop and cannot process sales.',
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
      message:
      'Assigned to ${shopName ?? 'shop'}. Cashier can process sales at this shop.',
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