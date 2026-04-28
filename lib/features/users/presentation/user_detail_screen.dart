import 'package:amana_pos/features/users/data/models/responses/user_response_dto.dart';
import 'package:amana_pos/features/users/presentation/bloc/users_bloc.dart';
import 'package:amana_pos/features/users/presentation/widgets/deactivate_user_sheet.dart';
import 'package:amana_pos/features/users/presentation/widgets/edit_user_sheet.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/utilities/extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class UserDetailScreen extends StatelessWidget {
  final UserData user;
  const UserDetailScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return BlocSelector<UserBloc, UserState, UserData?>(
      selector: (state) => state.userList
          .where((u) => u.id == user.id)
          .firstOrNull,
      builder: (context, data) {
        final u = data ?? user;
        return Scaffold(
          backgroundColor: context.appColors.background,
          body: CustomScrollView(
            slivers: [
              _UserAppBar(user: u),
              SliverPadding(
                padding: const EdgeInsets.all(AppDims.s4),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _InfoSection(user: u),
                    const SizedBox(height: AppDims.s5),
                    _ActivitySection(user: u),
                    const SizedBox(height: AppDims.s6),
                  ]),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─── App bar ──────────────────────────────────────────────────────────────────

class _UserAppBar extends StatelessWidget {
  final UserData user;
  const _UserAppBar({required this.user});

  @override
  Widget build(BuildContext context) {
    final isActive = user.isActive ?? false;

    return SliverAppBar(
      expandedHeight: 190,
      pinned: true,
      backgroundColor: context.appColors.surface,
      leading: IconButton(
        onPressed: () => Navigator.of(context).pop(),
        icon: Icon(Icons.arrow_back_rounded,
            color: context.appColors.textPrimary),
      ),
      actions: [
        IconButton(
          onPressed: () => showEditUserSheet(context, user: user),
          icon: Icon(Icons.edit_outlined,
              size: 20, color: context.appColors.textPrimary),
          tooltip: 'Edit',
        ),
        if (isActive)
          IconButton(
            onPressed: () => showDeactivateUserSheet(context, user),
            icon: const Icon(Icons.block_rounded,
                size: 20, color: Color(0xFFDC2626)),
            tooltip: 'Deactivate',
          ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          color: context.appColors.surface,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 56),

              // ── Avatar ──────────────────────────────────────────────
              Container(
                width: 76, height: 76,
                decoration: BoxDecoration(
                  color: context.appColors.primaryContainer,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  user.fullName?.initials ?? '?',
                  style: AppTextStyles.lg100(context).copyWith(
                  fontWeight: FontWeight.w800,
                    color: context.appColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: AppDims.s2),

              // ── Name ────────────────────────────────────────────────
              Text(
                user.fullName ?? '—',
                style: AppTextStyles.bs500(context).copyWith(
                fontWeight: FontWeight.w800,
                  color: context.appColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppDims.s1),

              // ── Role + status row ────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _RoleBadge(role: user.role),
                  const SizedBox(width: AppDims.s2),
                  _StatusDot(active: user.isActive ?? false),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Info section ─────────────────────────────────────────────────────────────

class _InfoSection extends StatelessWidget {
  final UserData user;
  const _InfoSection({required this.user});

  @override
  Widget build(BuildContext context) {
    return _Card(
      children: [
        _InfoRow(
          icon: Icons.phone_outlined,
          label: 'Phone',
          value: user.phone ?? '—',
        ),
        _InfoRow(
          icon: Icons.badge_outlined,
          label: 'Role',
          value: _capitalize(user.role),
        ),
        _InfoRow(
          icon: Icons.verified_outlined,
          label: 'Verified',
          value: (user.isVerified ?? false) ? 'Yes' : 'No',
          valueColor: (user.isVerified ?? false)
              ? const Color(0xFF16A34A)
              : null,
        ),
        _InfoRow(
          icon: Icons.circle,
          iconColor: (user.isActive ?? false)
              ? const Color(0xFF22C55E)
              : null,
          label: 'Status',
          value: (user.isActive ?? false) ? 'Active' : 'Inactive',
          isLast: true,
        ),
      ],
    );
  }

  String _capitalize(String? s) {
    if (s == null || s.isEmpty) return '—';
    return s[0].toUpperCase() + s.substring(1);
  }
}

// ─── Activity section ─────────────────────────────────────────────────────────

class _ActivitySection extends StatelessWidget {
  final UserData user;
  const _ActivitySection({required this.user});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ACTIVITY',
          style: AppTextStyles.bs400(context).copyWith(
          fontWeight: FontWeight.w800,
            color: context.appColors.textHint,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: AppDims.s2),
        _Card(
          children: [
            _InfoRow(
              icon: Icons.login_rounded,
              label: 'Last login',
              value: _formatDate(user.lastLoginAt) ?? 'Never',
              valueColor: user.lastLoginAt == null
                  ? context.appColors.textHint
                  : null,
            ),
            _InfoRow(
              icon: Icons.calendar_today_outlined,
              label: 'Joined',
              value: _formatDate(user.createdAt) ?? '—',
              isLast: true,
            ),
          ],
        ),
      ],
    );
  }

  String? _formatDate(String? iso) {
    if (iso == null) return null;
    try {
      final dt = DateTime.parse(iso).toLocal();
      return '${dt.day} ${_month(dt.month)} ${dt.year}  '
          '${dt.hour.toString().padLeft(2, '0')}:'
          '${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return iso;
    }
  }

  String _month(int m) => const [
    '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ][m];
}

// ─── Shared widgets ───────────────────────────────────────────────────────────

class _Card extends StatelessWidget {
  final List<Widget> children;
  const _Card({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.appColors.surface,
        borderRadius: BorderRadius.circular(AppDims.rMd),
      ),
      child: Column(children: children),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final String label;
  final String value;
  final Color? valueColor;
  final bool isLast;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.iconColor,
    this.valueColor,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppDims.s4, vertical: AppDims.s3),
          child: Row(
            children: [
              Icon(icon, size: 16,
                  color: iconColor ?? context.appColors.textHint),
              const SizedBox(width: AppDims.s3),
              Text(
                label,
                style: AppTextStyles.bs500(context).copyWith(
                fontWeight: FontWeight.w600,
                  color: context.appColors.textSecondary,
                ),
              ),
              const Spacer(),
              Text(
                value,
                style: AppTextStyles.bs500(context).copyWith(
                fontWeight: FontWeight.w700,
                  color: valueColor ?? context.appColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
        if (!isLast)
          Divider(height: 1, thickness: 1,
              indent: AppDims.s4,
              color: context.appColors.border),
      ],
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        role!,
        style: AppTextStyles.bs400(context).copyWith(
        fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }
}

class _StatusDot extends StatelessWidget {
  final bool active;
  const _StatusDot({required this.active});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: active
            ? const Color(0xFF22C55E).withOpacity(0.12)
            : context.appColors.surfaceSoft,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6, height: 6,
            decoration: BoxDecoration(
              color: active
                  ? const Color(0xFF22C55E)
                  : context.appColors.textHint,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            active ? 'Active' : 'Inactive',
            style: AppTextStyles.bs400(context).copyWith(
            fontWeight: FontWeight.w800,
              color: active
                  ? const Color(0xFF16A34A)
                  : context.appColors.textHint,
            ),
          ),
        ],
      ),
    );
  }
}