import 'package:amana_pos/features/users/presentation/bloc/users_bloc.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';


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

  static Color _colorFor(String role) => switch (role) {
    'admin'   => const Color(0xFF8B5CF6),
    'manager' => const Color(0xFF0EA5E9),
    _ => const Color(0xFF0D9488),
  };

  static IconData _iconFor(String role) => switch (role) {
    'admin' => Icons.shield_outlined,
    'manager' => Icons.manage_accounts_outlined,
    _ => Icons.point_of_sale_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Row(
      children: List.generate(roles.length, (i) {
        final role = roles[i];
        final selected = role == selectedRole;
        final color = _colorFor(role);
        final isLast = i == roles.length - 1;

        return Expanded(
          child: GestureDetector(
            onTap: () => onSelected(role),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              margin: EdgeInsets.only(right: isLast ? 0 : AppDims.s2),
              padding: const EdgeInsets.symmetric(vertical: AppDims.s3),
              decoration: BoxDecoration(
                color: selected
                    ? color.withValues(alpha: 0.12)
                    : colors.surfaceSoft,
                borderRadius: BorderRadius.circular(AppDims.rMd),
                border: Border.all(
                  color: selected ? color : colors.border,
                  width: selected ? 1.5 : 1,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    _iconFor(role),
                    size:  20,
                    color: selected ? color : colors.textHint,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    role,
                    style: AppTextStyles.bs200(context).copyWith(
                      fontWeight: FontWeight.w800,
                      color: selected ? color : colors.textHint,
                    ),
                  ),
                ],
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
  final VoidCallback onPressed;
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
      buildWhen: (prev, curr) => prev.submitStatus != curr.submitStatus,
      builder: (context, state) {
        final isLoading = state.submitStatus == UserSubmitStatus.loading;
        final canAct = enabled && !isLoading;

        return SizedBox(
          width:  double.infinity,
          height: 50,
          child: FilledButton(
            onPressed: canAct ? onPressed : null,
            style: FilledButton.styleFrom(
              backgroundColor: context.appColors.primary,
              disabledBackgroundColor: context.appColors.border,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDims.rMd),
              ),
            ),
            child: isLoading
                ? const SizedBox(
              width:  20,
              height: 20,
              child:  CircularProgressIndicator(
                strokeWidth: 2.5,
                color: Colors.white,
              ),
            )
                : Text(
              label,
              style: AppTextStyles.bs500(context).copyWith(
                fontWeight: FontWeight.w800,
                color: canAct
                    ? Colors.white
                    : context.appColors.textHint,
              ),
            ),
          ),
        );
      },
    );
  }
}