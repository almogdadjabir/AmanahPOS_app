import 'package:amana_pos/config/router/route_strings.dart';
import 'package:amana_pos/features/users/data/models/responses/user_response_dto.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/utilities/extension.dart';
import 'package:flutter/material.dart';

class UserList extends StatelessWidget {
  final List<UserData> users;
  const UserList({super.key, required this.users});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
          AppDims.s4, AppDims.s4, AppDims.s4, 100),
      itemCount: users.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppDims.s3),
      itemBuilder: (_, i) => _UserCard(user: users[i]),
    );
  }
}

class _UserCard extends StatelessWidget {
  final UserData user;
  const _UserCard({required this.user});

  @override
  Widget build(BuildContext context) {
    final isActive = user.isActive ?? false;

    return Material(
      color: context.appColors.surface,
      borderRadius: BorderRadius.circular(AppDims.rMd),
      child: InkWell(
        onTap: ()=> Navigator.of(context).pushNamed(
          RouteStrings.userDetailScreen,
          arguments: {'user': user},
        ),
        borderRadius: BorderRadius.circular(AppDims.rMd),
        child: Padding(
          padding: const EdgeInsets.all(AppDims.s3),
          child: Row(
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: context.appColors.primaryContainer,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  user.fullName?.initials ?? '?',
                  style: AppTextStyles.bs500(context).copyWith(
                  fontWeight: FontWeight.w800,
                    color: context.appColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: AppDims.s3),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.fullName ?? '—',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bs400(context).copyWith(
                      fontWeight: FontWeight.w800,
                        color: context.appColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        _RoleBadge(role: user.role),
                        if (user.phone != null) ...[
                          const SizedBox(width: AppDims.s2),
                          Flexible(
                            child: Text(
                              user.phone!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.bs300(context).copyWith(
                              fontWeight: FontWeight.w600,
                                color: context.appColors.textHint,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: isActive
                      ? const Color(0xFF22C55E).withOpacity(0.12)
                      : context.appColors.surfaceSoft,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  isActive ? 'Active' : 'Inactive',
                  style: AppTextStyles.bs200(context).copyWith(
                    fontWeight: FontWeight.w800,
                    color: isActive
                        ? const Color(0xFF16A34A)
                        : context.appColors.textHint,
                  ),
                ),
              ),
              const SizedBox(width: AppDims.s2),
              Icon(Icons.chevron_right_rounded,
                  color: context.appColors.textHint, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  final String? role;
  const _RoleBadge({this.role});

  Color _color(BuildContext context) => switch (role) {
    'admin'   => const Color(0xFF8B5CF6),
    'manager' => const Color(0xFF0EA5E9),
    'cashier' => const Color(0xFF0D9488),
    _         => context.appColors.textHint,
  };

  @override
  Widget build(BuildContext context) {
    if (role == null) return const SizedBox.shrink();
    final color = _color(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        role!,
        style: TextStyle(
          fontFamily: 'NunitoSans', fontSize: 10,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }
}
