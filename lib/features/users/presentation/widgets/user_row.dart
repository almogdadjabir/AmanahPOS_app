import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/common/motion/motion.dart';
import 'package:amana_pos/common/motion/motion_route.dart';
import 'package:amana_pos/features/users/data/models/responses/user_response_dto.dart';
import 'package:amana_pos/features/users/presentation/bloc/users_bloc.dart';
import 'package:amana_pos/features/users/presentation/user_detail_screen.dart';
import 'package:amana_pos/features/users/presentation/widgets/user_actions.dart';
import 'package:amana_pos/features/users/presentation/widgets/user_format.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/theme/phosphor_icons.dart';
import 'package:amana_pos/widgets/app_swipe_actions.dart';
import 'package:amana_pos/widgets/directional_icon.dart';
import 'package:amana_pos/widgets/pressable.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

void openUserDetail(BuildContext context, UserData user) {
  final bloc = context.read<UserBloc>();
  Navigator.of(context).push(
    motionPageRoute(
      BlocProvider.value(
        value: bloc,
        child: UserDetailScreen(user: user),
      ),
    ),
  );
}

/// Section label ("Managers") above a group.
class UserSectionLabel extends StatelessWidget {
  final String text;
  final bool first;
  const UserSectionLabel(this.text, {super.key, this.first = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(20, first ? 8 : 22, 20, 7),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          height: 1.3,
          color: context.appColors.textHint,
        ),
      ),
    );
  }
}

/// Grouped list of team members. Swipe reveals Deactivate (Reactivate for
/// inactive members).
class UserListGroup extends StatelessWidget {
  final List<UserData> users;

  const UserListGroup({super.key, required this.users});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final tr = context.tr;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: AppDims.borderLg,
        border: Border.all(color: colors.border),
      ),
      child: ClipRRect(
        borderRadius: AppDims.borderLg,
        child: Column(
          children: [
            for (var i = 0; i < users.length; i++) ...[
              if (i > 0)
                Divider(
                  height: 0.5,
                  thickness: 0.5,
                  indent: 68,
                  color: colors.border,
                ),
              UserSwipe(
                action: users[i].isActiveUser
                    ? AppSwipeAction(
                        label: tr.tmSwipeDeactivate,
                        icon: PhosphorIconsRegular.prohibit,
                        color: colors.danger,
                        onTap: () => confirmDeactivateUser(context, users[i]),
                      )
                    : AppSwipeAction(
                        label: tr.cuReactivate,
                        icon: PhosphorIconsRegular.userCheck,
                        color: colors.primary,
                        onTap: () => reactivateUser(context, users[i]),
                      ),
                child: UserRow(key: ValueKey(users[i].id ?? i), user: users[i]),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Single 96 wide swipe action (the shared swipe widget is 84 wide).
class UserSwipe extends StatefulWidget {
  final Widget child;
  final AppSwipeAction action;

  const UserSwipe({super.key, required this.child, required this.action});

  @override
  State<UserSwipe> createState() => _UserSwipeState();
}

class _UserSwipeState extends State<UserSwipe>
    with SingleTickerProviderStateMixin {
  static const double _width = 96;

  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: AppDims.sheet,
  );

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _drag(DragUpdateDetails d, bool rtl) {
    final delta = (rtl ? d.delta.dx : -d.delta.dx) / _width;
    final before = _ctrl.value;
    _ctrl.value = (_ctrl.value + delta).clamp(0.0, 1.0);
    if (before < 0.5 && _ctrl.value >= 0.5) HapticFeedback.selectionClick();
  }

  void _end(DragEndDetails d, bool rtl) {
    final v = rtl
        ? d.velocity.pixelsPerSecond.dx
        : -d.velocity.pixelsPerSecond.dx;
    _settle(v.abs() > 400 ? v > 0 : _ctrl.value > 0.5);
  }

  void _settle(bool open) {
    final target = open ? 1.0 : 0.0;
    if (!Motion.on) {
      _ctrl.value = target;
      return;
    }
    _ctrl.animateTo(target, curve: AppDims.sheetCurve);
  }

  @override
  Widget build(BuildContext context) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final a = widget.action;

    return ClipRect(
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onHorizontalDragUpdate: (d) => _drag(d, rtl),
        onHorizontalDragEnd: (d) => _end(d, rtl),
        child: Stack(
          children: [
            Positioned.fill(
              child: Align(
                alignment: AlignmentDirectional.centerEnd,
                child: SizedBox(
                  width: _width,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      _settle(false);
                      a.onTap();
                    },
                    child: ColoredBox(
                      color: a.color,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(a.icon, size: 22, color: Colors.white),
                          const SizedBox(height: 3),
                          Text(
                            a.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              height: 1.3,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            AnimatedBuilder(
              animation: _ctrl,
              builder: (context, child) => Transform.translate(
                offset: Offset(_ctrl.value * _width * (rtl ? 1 : -1), 0),
                child: child,
              ),
              child: AbsorbPointerWhenOpen(
                controller: _ctrl,
                onTapClosed: () => _settle(false),
                child: widget.child,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Round avatar with initials. Managers get the indigo tint, inactive members
/// are dimmed.
class UserAvatar extends StatelessWidget {
  final UserData user;
  final double size;

  const UserAvatar({super.key, required this.user, this.size = 44});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final active = user.isActiveUser;
    final (bg, fg) = !active
        ? (colors.surfaceSoft, colors.disabled)
        : user.isManager
        ? (colors.digitalTint, colors.digitalInk)
        : (colors.primaryContainer, colors.primary);

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
      child: Text(
        userInitials(context, user.displayName),
        style: TextStyle(
          fontSize: size > 60 ? 32 : 16,
          height: 1.3,
          fontWeight: FontWeight.w600,
          color: fg,
        ),
      ),
    );
  }
}

class UserRow extends StatelessWidget {
  final UserData user;

  const UserRow({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final tr = context.tr;
    final active = user.isActiveUser;
    final last = user.lastLogin;

    Widget? right;
    if (active) {
      if (user.isInvited) {
        right = DecoratedBox(
          decoration: BoxDecoration(
            color: colors.warningContainer,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            child: Text(
              tr.tmInvited,
              style: TextStyle(
                fontSize: 12,
                height: 1.3,
                fontWeight: FontWeight.w600,
                color: colors.warning,
              ),
            ),
          ),
        );
      } else {
        right = Text(
          last != null ? userLastSignInShort(context, last) : tr.tmNever,
          style: TextStyle(fontSize: 13, height: 1.3, color: colors.textHint),
        );
      }
    }

    return Pressable(
      onTap: () => openUserDetail(context, user),
      scale: 1,
      child: ColoredBox(
        color: colors.surface,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 64),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppDims.s4),
            child: Row(
              children: [
                UserAvatar(user: user),
                const SizedBox(width: AppDims.s3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              user.displayName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 17,
                                height: 1.3,
                                fontWeight: FontWeight.w500,
                                color: active
                                    ? colors.textPrimary
                                    : colors.textSecondary,
                              ),
                            ),
                          ),
                          if (!active) ...[
                            const SizedBox(width: 6),
                            DecoratedBox(
                              decoration: BoxDecoration(
                                color: colors.surfaceSoft,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                child: Text(
                                  tr.tmInactive,
                                  style: TextStyle(
                                    fontSize: 12,
                                    height: 1.3,
                                    fontWeight: FontWeight.w600,
                                    color: colors.textHint,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 1),
                        child: Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: Text(
                            formatUserPhone(user.phone),
                            textDirection: TextDirection.ltr,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              height: 1.3,
                              color: colors.textHint,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (right != null) ...[
                  const SizedBox(width: AppDims.s2),
                  right,
                ],
                const SizedBox(width: AppDims.s3),
                DirectionalIcon(
                  icon: PhosphorIconsRegular.caretRight,
                  size: 16,
                  color: colors.borderStrong,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
