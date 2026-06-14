import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/features/users/data/models/responses/user_response_dto.dart';
import 'package:amana_pos/features/users/presentation/bloc/users_bloc.dart';
import 'package:amana_pos/features/users/presentation/widgets/deactivate_user_sheet.dart';
import 'package:amana_pos/features/users/presentation/widgets/edit_user_sheet.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/utilities/extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:amana_pos/common/motion/motion_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solar_icons/solar_icons.dart';

const double kDesktopUserDrawerWidth = 460.0;

/// Right-side desktop panel that slides in when a user row is tapped.
/// Replaces the full-screen route on desktop with an overlay drawer that
/// keeps the user list visible behind a soft scrim.
class DesktopUserDetailDrawer extends StatefulWidget {
  final UserData user;
  final VoidCallback onClose;

  const DesktopUserDetailDrawer({
    super.key,
    required this.user,
    required this.onClose,
  });

  @override
  State<DesktopUserDetailDrawer> createState() =>
      _DesktopUserDetailDrawerState();
}

class _DesktopUserDetailDrawerState extends State<DesktopUserDetailDrawer> {
  @override
  Widget build(BuildContext context) {
    return BlocListener<UserBloc, UserState>(
      listenWhen: (prev, curr) =>
          prev.submitStatus != curr.submitStatus &&
          curr.submitStatus == UserSubmitStatus.success,
      listener: (context, state) {
        // If user was deleted/deactivated and no longer in the list, close
        final stillExists =
            state.userList.any((u) => u.id == widget.user.id);
        if (!stillExists) widget.onClose();
      },
      child: BlocSelector<UserBloc, UserState, UserData?>(
        selector: (state) {
          for (final u in state.userList) {
            if (u.id == widget.user.id) return u;
          }
          return null;
        },
        builder: (context, latestUser) {
          final user = latestUser ?? widget.user;
          return _DrawerBody(user: user, onClose: widget.onClose);
        },
      ),
    );
  }
}

// ── Drawer body ────────────────────────────────────────────────────────────────

class _DrawerBody extends StatelessWidget {
  final UserData user;
  final VoidCallback onClose;

  const _DrawerBody({required this.user, required this.onClose});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        border: BorderDirectional(
          start: BorderSide(
            color: colors.primary.withValues(alpha: 0.20),
            width: 1.5,
          ),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 40,
            offset: Offset(-10, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          _AvatarHeader(user: user, onClose: onClose),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AppDims.s4,
                AppDims.s4,
                AppDims.s4,
                AppDims.s4,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _QuickStatsRow(user: user)
                      .mAnimate()
                      .fadeIn(delay: 50.ms, duration: 200.ms)
                      .slideY(
                        begin: 0.04,
                        end: 0,
                        duration: 200.ms,
                        curve: Curves.easeOut,
                      ),
                  const SizedBox(height: AppDims.s3),
                  _DetailsCard(user: user)
                      .mAnimate()
                      .fadeIn(delay: 90.ms, duration: 200.ms)
                      .slideY(
                        begin: 0.04,
                        end: 0,
                        duration: 200.ms,
                        curve: Curves.easeOut,
                      ),
                ],
              ),
            ),
          ),
          _ActionBar(user: user),
        ],
      ),
    );
  }
}

// ── Avatar hero header ─────────────────────────────────────────────────────────

class _AvatarHeader extends StatelessWidget {
  final UserData user;
  final VoidCallback onClose;

  const _AvatarHeader({required this.user, required this.onClose});

  @override
  Widget build(BuildContext context) {
    final roleColor = _roleColor(user.role);
    final isActive = user.isActive ?? false;
    final name = user.fullName?.trim().isNotEmpty == true
        ? user.fullName!.trim()
        : 'User';

    return SizedBox(
      height: 200,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Gradient background
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  roleColor.withValues(alpha: 0.18),
                  roleColor.withValues(alpha: 0.06),
                ],
              ),
            ),
          ),

          // Bottom cinematic gradient
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [0.0, 0.40, 0.70, 1.0],
                colors: [
                  Colors.transparent,
                  Colors.transparent,
                  Color(0x44000000),
                  Color(0xCC000000),
                ],
              ),
            ),
          ),

          // Large avatar centered
          Center(
            child: CircleAvatar(
              radius: 44,
              backgroundColor: roleColor.withValues(alpha: 0.22),
              child: Text(
                user.fullName?.initials ?? '?',
                style: AppTextStyles.bs700(context).copyWith(
                  color: roleColor,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
            ),
          ),

          // Close button
          PositionedDirectional(
            top: AppDims.s3,
            end: AppDims.s3,
            child: _GlassIconButton(
              icon: Icons.close_rounded,
              onTap: onClose,
            ),
          ),

          // Inactive badge
          if (!isActive)
            PositionedDirectional(
              top: AppDims.s3,
              start: AppDims.s3,
              child: _GlassPill(
                label: context.tr.inactive,
                textColor: Colors.red.shade300,
                bgColor: Colors.black.withValues(alpha: 0.55),
              ),
            ),

          // Bottom: name + role
          PositionedDirectional(
            bottom: AppDims.s4,
            start: AppDims.s4,
            end: AppDims.s4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _GlassPill(label: _roleLabel(context, user.role)),
                const SizedBox(height: AppDims.s2),
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bs500(context).copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    height: 1.18,
                    shadows: const [
                      Shadow(color: Color(0x55000000), blurRadius: 12),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).mAnimate().fadeIn(duration: 160.ms);
  }
}

// ── Glass UI helpers ───────────────────────────────────────────────────────────

class _GlassIconButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _GlassIconButton({required this.icon, required this.onTap});

  @override
  State<_GlassIconButton> createState() => _GlassIconButtonState();
}

class _GlassIconButtonState extends State<_GlassIconButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 130),
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: _hovered
                ? Colors.white.withValues(alpha: 0.30)
                : Colors.black.withValues(alpha: 0.42),
            shape: BoxShape.circle,
          ),
          child: Icon(widget.icon, size: 17, color: Colors.white),
        ),
      ),
    );
  }
}

class _GlassPill extends StatelessWidget {
  final String label;
  final Color textColor;
  final Color bgColor;

  const _GlassPill({
    required this.label,
    this.textColor = Colors.white,
    this.bgColor = const Color(0x30FFFFFF),
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        child: Text(
          label,
          style: AppTextStyles.sm200(context).copyWith(
            color: textColor,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

// ── Quick stats row ────────────────────────────────────────────────────────────

class _QuickStatsRow extends StatelessWidget {
  final UserData user;

  const _QuickStatsRow({required this.user});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final tr = context.tr;
    final isActive = user.isActive ?? false;
    final isVerified = user.isVerified ?? false;
    final roleColor = _roleColor(user.role);

    final tiles = <({IconData icon, String label, String value, Color color})>[
      (
        icon: _roleIcon(user.role),
        label: 'Role',
        value: _roleLabel(context, user.role),
        color: roleColor,
      ),
      (
        icon: isActive
            ? SolarIconsOutline.checkCircle
            : SolarIconsOutline.pauseCircle,
        label: tr.status,
        value: isActive ? tr.active : tr.inactive,
        color: isActive ? const Color(0xFF16A34A) : colors.textHint,
      ),
      (
        icon: isVerified
            ? SolarIconsOutline.shieldCheck
            : SolarIconsOutline.shieldWarning,
        label: 'Verified',
        value: isVerified ? 'Yes' : 'No',
        color: isVerified ? const Color(0xFF0EA5E9) : colors.textHint,
      ),
      if (user.defaultShopName?.trim().isNotEmpty == true)
        (
          icon: SolarIconsOutline.shop,
          label: 'Shop',
          value: user.defaultShopName!.trim(),
          color: const Color(0xFF8B5CF6),
        ),
    ];

    return Row(
      children: [
        for (var i = 0; i < tiles.length; i++) ...[
          if (i != 0) const SizedBox(width: AppDims.s2),
          Expanded(
            child: _StatTile(
              icon: tiles[i].icon,
              label: tiles[i].label,
              value: tiles[i].value,
              color: tiles[i].color,
            ),
          ),
        ],
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(AppDims.rMd),
        border: Border.all(color: color.withValues(alpha: 0.13)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: AppDims.s3),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 17),
            const SizedBox(height: 5),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: AppTextStyles.bs200(context).copyWith(
                color: colors.textPrimary,
                fontWeight: FontWeight.w900,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: AppTextStyles.sm100(context).copyWith(
                color: colors.textSecondary,
                fontWeight: FontWeight.w700,
                height: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Details card ───────────────────────────────────────────────────────────────

class _DetailsCard extends StatelessWidget {
  final UserData user;

  const _DetailsCard({required this.user});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final rows = <_DetailItem>[];

    final phone = user.phone?.trim();
    if (phone != null && phone.isNotEmpty) {
      rows.add(_DetailItem(
        icon: SolarIconsOutline.phoneRounded,
        label: 'Phone',
        value: phone,
        copyable: true,
      ));
    }

    final email = user.email?.trim();
    if (email != null && email.isNotEmpty) {
      rows.add(_DetailItem(
        icon: SolarIconsOutline.letter,
        label: 'Email',
        value: email,
        copyable: true,
      ));
    }

    final shop = user.defaultShopName?.trim();
    if (shop != null && shop.isNotEmpty) {
      rows.add(_DetailItem(
        icon: SolarIconsOutline.shop,
        label: 'Default shop',
        value: shop,
        copyable: false,
      ));
    }

    if (user.lastLoginAt != null) {
      rows.add(_DetailItem(
        icon: SolarIconsOutline.clockCircle,
        label: 'Last login',
        value: _fmtDate(user.lastLoginAt!),
        copyable: false,
      ));
    }

    if (user.createdAt != null) {
      rows.add(_DetailItem(
        icon: SolarIconsOutline.calendarDate,
        label: 'Created',
        value: _fmtDate(user.createdAt!),
        copyable: false,
      ));
    }

    if (rows.isEmpty) return const SizedBox.shrink();

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppDims.rLg),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            _DetailsRowWidget(item: rows[i]),
            if (i < rows.length - 1)
              Divider(
                height: 1,
                thickness: 1,
                color: colors.border.withValues(alpha: 0.5),
                indent: AppDims.s4 + 36 + AppDims.s3,
                endIndent: AppDims.s4,
              ),
          ],
        ],
      ),
    );
  }

  static String _fmtDate(String iso) {
    try {
      final dt = DateTime.parse(iso);
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
      ];
      return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
    } catch (_) {
      return iso;
    }
  }
}

class _DetailItem {
  final IconData icon;
  final String label;
  final String value;
  final bool copyable;

  const _DetailItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.copyable,
  });
}

class _DetailsRowWidget extends StatelessWidget {
  final _DetailItem item;

  const _DetailsRowWidget({required this.item});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppDims.s4,
        AppDims.s3,
        AppDims.s3,
        AppDims.s3,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: colors.surfaceSoft,
              borderRadius: BorderRadius.circular(AppDims.rSm),
            ),
            child: SizedBox(
              width: 36,
              height: 36,
              child: Icon(item.icon, size: 16, color: colors.textSecondary),
            ),
          ),
          const SizedBox(width: AppDims.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.label,
                  style: AppTextStyles.sm100(context).copyWith(
                    color: colors.textSecondary,
                    fontWeight: FontWeight.w700,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  item.value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bs200(context).copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w800,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          if (item.copyable) ...[
            const SizedBox(width: AppDims.s2),
            _CopyButton(value: item.value),
          ],
        ],
      ),
    );
  }
}

class _CopyButton extends StatefulWidget {
  final String value;

  const _CopyButton({required this.value});

  @override
  State<_CopyButton> createState() => _CopyButtonState();
}

class _CopyButtonState extends State<_CopyButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: () async {
          await Clipboard.setData(ClipboardData(text: widget.value));
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Copied to clipboard'),
                duration: const Duration(seconds: 1),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDims.rMd),
                ),
              ),
            );
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 130),
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: _hovered
                ? colors.primary.withValues(alpha: 0.10)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(AppDims.rSm),
          ),
          child: Icon(
            SolarIconsOutline.copy,
            size: 15,
            color: _hovered ? colors.primary : colors.textHint,
          ),
        ),
      ),
    );
  }
}

// ── Sticky action bar ──────────────────────────────────────────────────────────

class _ActionBar extends StatelessWidget {
  final UserData user;

  const _ActionBar({required this.user});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final tr = context.tr;
    final isActive = user.isActive ?? false;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(
          top: BorderSide(color: colors.border.withValues(alpha: 0.7)),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppDims.s4,
          AppDims.s3,
          AppDims.s4,
          AppDims.s4,
        ),
        child: Row(
          children: [
            Expanded(
              child: _DrawerActionButton(
                icon: SolarIconsOutline.penNewSquare,
                label: tr.edit,
                color: colors.primary,
                onTap: () => showEditUserSheet(context, user: user),
              ),
            ),
            const SizedBox(width: AppDims.s3),
            Expanded(
              child: _DrawerActionButton(
                icon: isActive
                    ? SolarIconsOutline.pauseCircle
                    : SolarIconsOutline.checkCircle,
                label: isActive ? tr.deactivate : 'Activate',
                color: isActive
                    ? const Color(0xFFEA580C)
                    : const Color(0xFF16A34A),
                onTap: () => showDeactivateUserSheet(context, user),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerActionButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _DrawerActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  State<_DrawerActionButton> createState() => _DrawerActionButtonState();
}

class _DrawerActionButtonState extends State<_DrawerActionButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 130),
          height: 44,
          decoration: BoxDecoration(
            color: widget.color.withValues(alpha: _hovered ? 0.12 : 0.07),
            borderRadius: BorderRadius.circular(AppDims.rMd),
            border: Border.all(
              color: widget.color.withValues(alpha: _hovered ? 0.28 : 0.15),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(widget.icon, color: widget.color, size: 16),
              const SizedBox(width: AppDims.s2),
              Text(
                widget.label,
                style: AppTextStyles.bs200(context).copyWith(
                  color: widget.color,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Helpers ────────────────────────────────────────────────────────────────────

Color _roleColor(String? role) {
  return switch (role?.toLowerCase().trim()) {
    'manager' => const Color(0xFF0EA5E9),
    'cashier' => const Color(0xFF0D9488),
    'admin' => const Color(0xFF8B5CF6),
    _ => const Color(0xFF94A3B8),
  };
}

IconData _roleIcon(String? role) {
  return switch (role?.toLowerCase().trim()) {
    'manager' => SolarIconsOutline.shieldUser,
    'cashier' => SolarIconsOutline.userSpeakRounded,
    'admin' => SolarIconsOutline.crownStar,
    _ => SolarIconsOutline.user,
  };
}

String _roleLabel(BuildContext context, String? role) {
  final tr = context.tr;
  return switch (role?.toLowerCase().trim()) {
    'manager' => tr.manager,
    'cashier' => tr.cashier,
    'admin' => tr.admin,
    _ => role ?? '—',
  };
}
