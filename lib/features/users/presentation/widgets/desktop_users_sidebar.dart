import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/features/users/data/models/responses/user_response_dto.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/utilities/extension.dart';
import 'package:flutter/material.dart';
import 'package:solar_icons/solar_icons.dart';

class DesktopUsersSidebar extends StatelessWidget {
  final List<UserData> users;
  final VoidCallback onAddUser;
  final ValueChanged<UserData> onUserTap;

  const DesktopUsersSidebar({
    super.key,
    required this.users,
    required this.onAddUser,
    required this.onUserTap,
  });

  @override
  Widget build(BuildContext context) {
    final managers = users
        .where((u) {
          final role = u.role?.toLowerCase().trim();
          return role == 'manager' || role == 'admin';
        })
        .toList();

    final cashiers = users
        .where((u) => u.role?.toLowerCase().trim() == 'cashier')
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _QuickActionsCard(onAddUser: onAddUser),
        const SizedBox(height: AppDims.s4),
        _UserListPanel(
          icon: SolarIconsOutline.shieldUser,
          iconColor: const Color(0xFF8B5CF6),
          title: context.tr.managers,
          emptyMessage: context.tr.noManagersFound,
          items: managers.take(6).toList(),
          onUserTap: onUserTap,
        ),
        const SizedBox(height: AppDims.s4),
        _UserListPanel(
          icon: SolarIconsOutline.userSpeakRounded,
          iconColor: const Color(0xFF0EA5E9),
          title: context.tr.cashiers,
          emptyMessage: context.tr.noCashiersFound,
          items: cashiers.take(6).toList(),
          onUserTap: onUserTap,
        ),
      ],
    );
  }
}

class _QuickActionsCard extends StatelessWidget {
  final VoidCallback onAddUser;

  const _QuickActionsCard({required this.onAddUser});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final tr = context.tr;

    return Container(
      padding: const EdgeInsets.all(AppDims.s4),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppDims.rXl),
        border: Border.all(color: colors.border.withValues(alpha: 0.75)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Quick Actions',
            style: AppTextStyles.bs200(context).copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: AppDims.s3),
          FilledButton.icon(
            onPressed: onAddUser,
            style: FilledButton.styleFrom(
              backgroundColor: colors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: AppDims.s3),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDims.rMd),
              ),
            ),
            icon: const Icon(
              SolarIconsOutline.userPlus,
              size: 18,
              color: Colors.white,
            ),
            label: Text(
              tr.addUser,
              style: AppTextStyles.bs200(context).copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UserListPanel extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String emptyMessage;
  final List<UserData> items;
  final ValueChanged<UserData> onUserTap;

  const _UserListPanel({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.emptyMessage,
    required this.items,
    required this.onUserTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
      padding: const EdgeInsets.all(AppDims.s4),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppDims.rXl),
        border: Border.all(color: colors.border.withValues(alpha: 0.75)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PanelHeader(
            icon: icon,
            iconColor: iconColor,
            title: title,
            count: items.length,
          ),
          if (items.isEmpty) ...[
            const SizedBox(height: AppDims.s4),
            Icon(
              icon,
              size: 26,
              color: colors.textHint.withValues(alpha: 0.6),
            ),
            const SizedBox(height: AppDims.s2),
            Text(
              emptyMessage,
              textAlign: TextAlign.center,
              style: AppTextStyles.sm300(context).copyWith(
                color: colors.textHint,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppDims.s2),
          ] else ...[
            const SizedBox(height: AppDims.s3),
            for (var i = 0; i < items.length; i++) ...[
              if (i != 0) const SizedBox(height: AppDims.s2),
              _SidebarUserRow(
                user: items[i],
                accentColor: iconColor,
                onTap: () => onUserTap(items[i]),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _PanelHeader extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final int count;

  const _PanelHeader({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppDims.rSm),
          ),
          child: Icon(icon, size: 15, color: iconColor),
        ),
        const SizedBox(width: AppDims.s2),
        Expanded(
          child: Text(
            title,
            style: AppTextStyles.bs200(context).copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        if (count > 0)
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDims.s2,
              vertical: 2,
            ),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '$count',
              style: AppTextStyles.sm100(context).copyWith(
                color: iconColor,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
      ],
    );
  }
}

class _SidebarUserRow extends StatefulWidget {
  final UserData user;
  final Color accentColor;
  final VoidCallback onTap;

  const _SidebarUserRow({
    required this.user,
    required this.accentColor,
    required this.onTap,
  });

  @override
  State<_SidebarUserRow> createState() => _SidebarUserRowState();
}

class _SidebarUserRowState extends State<_SidebarUserRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final name = widget.user.fullName?.trim().isNotEmpty == true
        ? widget.user.fullName!.trim()
        : 'User';
    final subtitle = widget.user.phone?.trim().isNotEmpty == true
        ? widget.user.phone!.trim()
        : widget.user.email?.trim() ?? '—';

    final row = AnimatedContainer(
      duration: const Duration(milliseconds: 140),
      padding: const EdgeInsets.symmetric(
        horizontal: AppDims.s2,
        vertical: AppDims.s2,
      ),
      decoration: BoxDecoration(
        color: _hovered ? colors.surfaceSoft : Colors.transparent,
        borderRadius: BorderRadius.circular(AppDims.rMd),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: widget.accentColor.withValues(alpha: 0.12),
            child: Text(
              widget.user.fullName?.initials ?? '?',
              style: AppTextStyles.sm100(context).copyWith(
                color: widget.accentColor,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: AppDims.s2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.sm300(context).copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.sm100(context).copyWith(
                    color: colors.textHint,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppDims.s2),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: (widget.user.isActive == true
                      ? const Color(0xFF16A34A)
                      : colors.textHint)
                  .withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              widget.user.isActive == true
                  ? context.tr.active
                  : context.tr.inactive,
              style: AppTextStyles.sm100(context).copyWith(
                color: widget.user.isActive == true
                    ? const Color(0xFF16A34A)
                    : colors.textHint,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppDims.rMd),
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(AppDims.rMd),
          child: row,
        ),
      ),
    );
  }
}
