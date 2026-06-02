import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/features/users/presentation/bloc/users_bloc.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/widgets/app_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solar_icons/solar_icons.dart';

class RolePicker extends StatelessWidget {
  const RolePicker({
    super.key,
    required this.roles,
    required this.selectedRole,
    required this.onSelected,
  });

  final List<String> roles;
  final String selectedRole;
  final ValueChanged<String> onSelected;

  static const Set<String> _allowedCreatableRoles = {
    'cashier',
    'manager',
  };

  List<String> get _safeRoles {
    final result = <String>[];

    for (final role in roles) {
      final normalized = role.toLowerCase().trim();

      if (_allowedCreatableRoles.contains(normalized) &&
          !result.contains(normalized)) {
        result.add(normalized);
      }
    }

    return result;
  }

  static Color _colorFor(String role) {
    return switch (role) {
      'manager' => const Color(0xFF0EA5E9),
      'cashier' => const Color(0xFF0D9488),
      _ => const Color(0xFF0D9488),
    };
  }

  static IconData _iconFor(String role) {
    return switch (role) {
      'manager' => SolarIconsOutline.shieldUser,
      'cashier' => SolarIconsOutline.userSpeakRounded,
      _ => SolarIconsOutline.user,
    };
  }

  static String _labelFor(BuildContext context, String role) {
    return switch (role) {
      'manager' => context.tr.manager,
      'cashier' => context.tr.cashier,
      _ => role,
    };
  }

  @override
  Widget build(BuildContext context) {
    final safeRoles = _safeRoles;

    if (safeRoles.isEmpty) {
      return const SizedBox.shrink();
    }

    final normalizedSelectedRole = selectedRole.toLowerCase().trim();

    return Row(
      children: List.generate(safeRoles.length, (index) {
        final role = safeRoles[index];
        final selected = role == normalizedSelectedRole;
        final isLast = index == safeRoles.length - 1;

        return Expanded(
          child: Padding(
            padding: EdgeInsetsDirectional.only(
              end: isLast ? 0 : AppDims.s2,
            ),
            child: _RoleOptionCard(
              role: role,
              label: _labelFor(context, role),
              icon: _iconFor(role),
              color: _colorFor(role),
              selected: selected,
              onTap: () => onSelected(role),
            ),
          ),
        );
      }),
    );
  }
}

class _RoleOptionCard extends StatelessWidget {
  const _RoleOptionCard({
    required this.role,
    required this.label,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String role;
  final String label;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppDims.rLg),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppDims.rLg),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: AppDims.s2,
              vertical: AppDims.s3,
            ),
            decoration: BoxDecoration(
              color: selected
                  ? color.withValues(alpha: 0.12)
                  : colors.surfaceSoft,
              borderRadius: BorderRadius.circular(AppDims.rLg),
              border: Border.all(
                color: selected ? color : colors.border,
                width: selected ? 1.4 : 1,
              ),
              boxShadow: selected
                  ? [
                BoxShadow(
                  color: color.withValues(alpha: 0.12),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ]
                  : null,
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _RoleIconBox(
                      icon: icon,
                      color: color,
                      selected: selected,
                    ),
                    const SizedBox(height: AppDims.s2),
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bs300(context).copyWith(
                        fontWeight: FontWeight.w900,
                        color: selected ? color : colors.textSecondary,
                        height: 1,
                      ),
                    ),
                  ],
                ),
                if (selected)
                  PositionedDirectional(
                    top: -4,
                    end: -4,
                    child: _SelectedMark(color: color),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleIconBox extends StatelessWidget {
  const _RoleIconBox({
    required this.icon,
    required this.color,
    required this.selected,
  });

  final IconData icon;
  final Color color;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: selected ? color.withValues(alpha: 0.14) : colors.surface,
        borderRadius: BorderRadius.circular(AppDims.rSm),
        border: Border.all(
          color: selected ? color.withValues(alpha: 0.18) : colors.border,
        ),
      ),
      child: SizedBox(
        width: 36,
        height: 36,
        child: Icon(
          icon,
          size: 20,
          color: selected ? color : colors.textHint,
        ),
      ),
    );
  }
}

class _SelectedMark extends StatelessWidget {
  const _SelectedMark({
    required this.color,
  });

  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(
          color: context.appColors.surface,
          width: 2,
        ),
      ),
      child: const SizedBox(
        width: 22,
        height: 22,
        child: Icon(
          SolarIconsOutline.checkCircle,
          size: 14,
          color: Colors.white,
        ),
      ),
    );
  }
}

class UserSubmitButton extends StatelessWidget {
  const UserSubmitButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.enabled = true,
    this.icon = SolarIconsOutline.userPlus,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool enabled;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return BlocSelector<UserBloc, UserState, bool>(
      selector: (state) => state.submitStatus == UserSubmitStatus.loading,
      builder: (context, isLoading) {
        final canAct = enabled && !isLoading && onPressed != null;
        return AppButton.wide(
          label: label,
          isLoading: isLoading,
          onPressed: canAct ? onPressed : null,
          prefixIcon: Icon(icon, size: 19, color: Colors.white),
        );
      },
    );
  }
}