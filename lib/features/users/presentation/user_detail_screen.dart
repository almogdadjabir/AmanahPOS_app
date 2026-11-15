import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/features/users/data/models/responses/user_response_dto.dart';
import 'package:amana_pos/features/users/presentation/bloc/users_bloc.dart';
import 'package:amana_pos/features/users/presentation/widgets/user_actions.dart';
import 'package:amana_pos/features/users/presentation/widgets/user_format.dart';
import 'package:amana_pos/features/users/presentation/widgets/user_pickers.dart';
import 'package:amana_pos/features/users/presentation/widgets/user_row.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/theme/phosphor_icons.dart';
import 'package:amana_pos/widgets/app_form_group.dart';
import 'package:amana_pos/widgets/directional_icon.dart';
import 'package:amana_pos/widgets/pressable.dart';
import 'package:flutter/cupertino.dart' show CupertinoSwitch;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class UserDetailScreen extends StatelessWidget {
  final UserData user;

  const UserDetailScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final tr = context.tr;

    // Live from the bloc, falling back to the user the screen was opened with.
    final live =
        context.select<UserBloc, UserData?>((bloc) {
          for (final u in bloc.state.userList) {
            if (u.id == user.id) return u;
          }
          return null;
        }) ??
        user;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _NavBar(backLabel: tr.tmTitle),
            Expanded(
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                padding: EdgeInsets.fromLTRB(
                  AppDims.s4,
                  6,
                  AppDims.s4,
                  MediaQuery.viewPaddingOf(context).bottom + 24,
                ),
                child: _Body(user: live),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  final UserData user;
  const _Body({required this.user});

  Future<void> _pickRole(BuildContext context) async {
    final id = user.id;
    if (id == null) return;
    final current = user.isManager ? 'manager' : 'cashier';
    final picked = await showRolePicker(context, current: current);
    if (picked == null || picked == current || !context.mounted) return;
    await runUserSubmit(
      context,
      OnUpdateUser(userId: id, role: picked),
      successMessage: context.tr.tmUpdated,
    );
  }

  Future<void> _pickBranch(BuildContext context) async {
    final id = user.id;
    final shops = activeShops(context);
    if (id == null || shops.isEmpty) return;
    final current = user.defaultShopId;
    final picked = await showBranchPicker(
      context,
      shops: shops,
      current: current,
    );
    if (picked == null || picked == current || !context.mounted) return;
    await runUserSubmit(
      context,
      OnUpdateUser(userId: id, shopId: picked),
      successMessage: context.tr.tmUpdated,
    );
  }

  Future<void> _toggleActive(BuildContext context, bool on) async {
    if (on) {
      await reactivateUser(context, user);
    } else {
      await confirmDeactivateUser(context, user);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final tr = context.tr;
    final multiShop = hasMultipleShops(context);
    final shops = activeShops(context);
    final last = user.lastLogin;
    final joined = user.joinedAt;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Column(
          children: [
            UserAvatar(user: user, size: 84),
            const SizedBox(height: 14),
            Text(
              user.displayName,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 26,
                height: 31 / 26,
                fontWeight: FontWeight.w700,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              formatUserPhone(user.phone),
              textDirection: TextDirection.ltr,
              style: TextStyle(
                fontSize: 15,
                height: 1.3,
                color: colors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 22),
        AppFormGroup(
          children: [
            _KvRow(
              label: tr.tmRole,
              value: userRoleLabel(context, user.role),
              onTap: () => _pickRole(context),
            ),
            if (multiShop)
              _KvRow(
                label: tr.tmBranch,
                value: shopName(shops, user.defaultShopId) ?? '-',
                onTap: () => _pickBranch(context),
              ),
          ],
        ),
        const SizedBox(height: 22),
        AppFormGroup(
          children: [
            _KvRow(
              label: tr.tmLastSignIn,
              value: last != null
                  ? userLastSignInLong(context, last)
                  : tr.tmNever,
            ),
            if (joined != null)
              _KvRow(label: tr.tmJoined, value: userJoined(context, joined)),
          ],
        ),
        const SizedBox(height: 22),
        AppFormGroup(
          footer: tr.tmCanSignInFoot,
          children: [
            _KvRow(
              label: tr.tmCanSignIn,
              trailing: CupertinoSwitch(
                value: user.isActiveUser,
                activeTrackColor: colors.primary,
                onChanged: (v) {
                  HapticFeedback.selectionClick();
                  _toggleActive(context, v);
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Label on the start side, value (or [trailing]) on the end side.
class _KvRow extends StatelessWidget {
  final String label;
  final String? value;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _KvRow({required this.label, this.value, this.trailing, this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    final row = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 50),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppDims.s4),
        child: Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 17,
                height: 1.3,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(width: AppDims.s3),
            Expanded(
              child: trailing != null
                  ? Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: trailing,
                    )
                  : Text(
                      value ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.end,
                      style: TextStyle(
                        fontSize: 17,
                        height: 1.3,
                        color: colors.textSecondary,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
            ),
            if (onTap != null) ...[
              const SizedBox(width: AppDims.s2),
              DirectionalIcon(
                icon: PhosphorIconsRegular.caretRight,
                size: 18,
                color: colors.borderStrong,
              ),
            ],
          ],
        ),
      ),
    );

    if (onTap == null) return row;
    return Pressable(onTap: onTap, scale: 1, child: row);
  }
}

class _NavBar extends StatelessWidget {
  final String backLabel;
  const _NavBar({required this.backLabel});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return SizedBox(
      height: 44,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: [
            Pressable(
              onTap: () => Navigator.of(context).maybePop(),
              child: SizedBox(
                height: 44,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(width: 4),
                    DirectionalIcon(
                      icon: PhosphorIconsRegular.caretLeft,
                      size: 24,
                      color: colors.primary,
                    ),
                    Text(
                      backLabel,
                      style: TextStyle(
                        fontSize: 17,
                        height: 1.3,
                        color: colors.primary,
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
