import 'package:amana_pos/features/users/presentation/bloc/users_bloc.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solar_icons/solar_icons.dart';

class RolePicker extends StatelessWidget {
  final List<String> roles;
  final String selectedRole;
  final ValueChanged<String> onSelected;

  const RolePicker({
    super.key,
    required this.roles,
    required this.selectedRole,
    required this.onSelected,
  });

  static const Set<String> _allowedCreatableRoles = {
    'cashier',
    'manager',
  };

  List<String> get _safeRoles {
    return roles
        .map((role) => role.toLowerCase().trim())
        .where(_allowedCreatableRoles.contains)
        .toSet()
        .toList();
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

  static String _labelFor(String role) {
    return switch (role) {
      'manager' => 'Manager',
      'cashier' => 'Cashier',
      _ => role,
    };
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final safeRoles = _safeRoles;

    if (safeRoles.isEmpty) {
      return const SizedBox.shrink();
    }

    return Row(
      children: List.generate(safeRoles.length, (index) {
        final role = safeRoles[index];
        final selected = role == selectedRole.toLowerCase().trim();
        final color = _colorFor(role);
        final isLast = index == safeRoles.length - 1;

        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: isLast ? 0 : AppDims.s2,
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(AppDims.rLg),
              child: InkWell(
                onTap: () => onSelected(role),
                borderRadius: BorderRadius.circular(AppDims.rLg),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  curve: Curves.easeOutCubic,
                  padding: const EdgeInsets.symmetric(
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
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: selected
                              ? color.withValues(alpha: 0.12)
                              : colors.surface,
                          borderRadius: BorderRadius.circular(AppDims.rSm),
                        ),
                        child: Icon(
                          _iconFor(role),
                          size: 19,
                          color: selected ? color : colors.textHint,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _labelFor(role),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bs300(context).copyWith(
                          fontWeight: FontWeight.w900,
                          color: selected ? color : colors.textSecondary,
                          height: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

class UserSubmitButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool enabled;

  const UserSubmitButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UserBloc, UserState>(
      buildWhen: (prev, curr) {
        return prev.submitStatus != curr.submitStatus;
      },
      builder: (context, state) {
        final colors = context.appColors;
        final isLoading = state.submitStatus == UserSubmitStatus.loading;
        final canAct = enabled && !isLoading;

        return SizedBox(
          width: double.infinity,
          height: 52,
          child: FilledButton(
            onPressed: canAct ? onPressed : null,
            style: FilledButton.styleFrom(
              backgroundColor: colors.primary,
              disabledBackgroundColor: colors.border,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDims.rMd),
              ),
            ),
            child: isLoading
                ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: Colors.white,
              ),
            )
                : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  SolarIconsOutline.userPlus,
                  size: 19,
                  color: Colors.white,
                ),
                const SizedBox(width: AppDims.s2),
                Text(
                  label,
                  style: AppTextStyles.bs500(context).copyWith(
                    fontWeight: FontWeight.w900,
                    color: canAct ? Colors.white : colors.textHint,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}