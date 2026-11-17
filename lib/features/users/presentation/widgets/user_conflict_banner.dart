import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/features/users/data/models/responses/user_response_dto.dart';
import 'package:amana_pos/features/users/presentation/bloc/users_bloc.dart';
import 'package:amana_pos/features/users/presentation/widgets/user_actions.dart';
import 'package:amana_pos/features/users/presentation/widgets/user_format.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/widgets/pressable.dart';
import 'package:flutter/material.dart';

/// A refused team change the owner has to decide on. Nothing is applied
/// without a tap: "Apply mine again" re-sends it against the member's
/// current server version, "Dismiss" shows the server state.
class UserConflictBanner extends StatelessWidget {
  final UserData user;
  const UserConflictBanner({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final c = user.conflict;
    if (c == null) return const SizedBox.shrink();
    final colors = context.appColors;
    final tr = context.tr;
    final shops = activeShops(context);
    final String body;
    if (c.isVersionConflict) {
      final current = [
        '${tr.tmRole}: ${userRoleLabel(context, user.role)}',
        if (hasMultipleShops(context))
          '${tr.tmBranch}: ${shopName(shops, user.defaultShopId) ?? '-'}',
      ].join(', ');
      body = tr.userConflictBody(
        user.displayName,
        current,
        userChangeSummary(context, c.payload, shops),
      );
    } else if (c.code == 'conflict_unique') {
      body = tr.userPhoneExists;
    } else {
      body = tr.userChangeRefused(c.message ?? c.code);
    }

    Widget action(String label, Color color, UserEvent event) => Pressable(
      onTap: () => runUserSubmit(context, event),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.dangerContainer,
          borderRadius: AppDims.borderLg,
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppDims.s4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tr.userConflictTitle,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: colors.danger,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                body,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.35,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  if (c.isVersionConflict)
                    action(
                      tr.userConflictApplyMine,
                      colors.primary,
                      OnApplyUserConflict(c.mutationId),
                    ),
                  const Spacer(),
                  action(
                    tr.userConflictDismiss,
                    colors.textSecondary,
                    OnDismissUserConflict(c.mutationId),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
