// lib/features/feature_menu/widgets/menu_footer.dart

import 'package:amana_pos/common/auth_bloc/auth_bloc.dart';
import 'package:amana_pos/core/offline/offline_db.dart';
import 'package:amana_pos/core/offline/presentation/bloc/offline_status_bloc.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/utilities/dependencies_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class MenuFooter extends StatelessWidget {
  final VoidCallback? onSignOut;
  const MenuFooter({super.key, this.onSignOut});

  static const String _appVersion = 'v1.0.0';

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: BlocBuilder<OfflineStatusBloc, OfflineStatusState>(
        bloc: getIt<OfflineStatusBloc>(),
        builder: (context, state) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [

              Divider(height: 1, thickness: 0.5,
                  color: context.appColors.border),

              // ── Main row: sync info + sign out ──────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 12),
                child: Row(
                  children: [
                    // Sync status
                    Expanded(
                      child: _SyncInfo(
                          version: _appVersion, state: state),
                    ),

                    // Sign out button
                    _SignOutButton(
                      onSignOut: onSignOut ??
                              () => _confirmSignOut(context),
                    ),
                  ],
                ),
              ),

              // ── Debug row (removed before going live) ───────────────
              if (kDebugMode) ...[
                Divider(height: 1, thickness: 0.5,
                    color: context.appColors.border),
                _DebugRow(
                  onCleared: () => getIt<OfflineStatusBloc>()
                      .add(const OnOfflineStatusStarted()),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  static Future<void> _confirmSignOut(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (_) => const _LogoutDialog(),
    );
    if (confirmed == true && context.mounted) {
      getIt<AuthBloc>().add(const OnLogoutEvent());
    }
  }
}

// ── Logout confirmation dialog ────────────────────────────────────────────────

class _LogoutDialog extends StatelessWidget {
  const _LogoutDialog();

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    const red    = Color(0xFFEF4444);

    return Dialog(
      backgroundColor: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDims.rXl),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppDims.s5),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [

            // Icon
            Container(
              width: 56, height: 56,
              decoration: BoxDecoration(
                color:        red.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(AppDims.rLg),
              ),
              child: const Icon(
                Icons.logout_rounded,
                size:  26,
                color: red,
              ),
            ),
            const SizedBox(height: AppDims.s4),

            // Title
            Text(
              'Sign out?',
              style: AppTextStyles.bs600(context).copyWith(
                fontWeight: FontWeight.w900,
                color:      colors.textPrimary,
              ),
            ),
            const SizedBox(height: AppDims.s2),

            // Body
            Text(
              'Make sure all your sales are synced before signing out. '
                  'Offline sales that have not synced will be lost.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bs300(context).copyWith(
                color:      colors.textSecondary,
                fontWeight: FontWeight.w600,
                height:     1.45,
              ),
            ),
            const SizedBox(height: AppDims.s5),

            // Actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colors.textSecondary,
                      side:   BorderSide(color: colors.border),
                      shape:  RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppDims.rMd)),
                      minimumSize: const Size(0, 48),
                    ),
                    child: Text(
                      'Cancel',
                      style: AppTextStyles.bs400(context).copyWith(
                        fontWeight: FontWeight.w800,
                        color:      colors.textSecondary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppDims.s3),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: FilledButton.styleFrom(
                      backgroundColor: red,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppDims.rMd)),
                      minimumSize: const Size(0, 48),
                    ),
                    child: Text(
                      'Sign out',
                      style: AppTextStyles.bs400(context).copyWith(
                        fontWeight: FontWeight.w800,
                        color:      Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Sync info ─────────────────────────────────────────────────────────────────

class _SyncInfo extends StatelessWidget {
  final String             version;
  final OfflineStatusState state;
  const _SyncInfo({required this.version, required this.state});

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(context);

    return GestureDetector(
      onTap: () => getIt<OfflineStatusBloc>()
          .add(const OnOfflineStatusRefreshRequested()),
      child: Row(
        children: [
          if (state.isBusy)
            SizedBox(
              width: 10, height: 10,
              child: CircularProgressIndicator(
                  strokeWidth: 1.8, color: color),
            )
          else
            Container(
              width: 8, height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
          const SizedBox(width: 7),
          Flexible(
            child: Text(
              _label(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.bs100(context).copyWith(
                color:      context.appColors.textHint,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _label() {
    final parts = [version, state.connectionLabel, state.statusLabel];
    final sync  = _syncText();
    if (sync != null) parts.add(sync);
    return parts.join(' · ');
  }

  String? _syncText() {
    final date = state.latestSyncAt;
    if (date == null) return null;
    final diff = DateTime.now().difference(date);
    if (diff.inSeconds < 30) return 'just now';
    if (diff.inMinutes < 1)  return '${diff.inSeconds}s ago';
    if (diff.inHours < 1)    return '${diff.inMinutes}m ago';
    if (diff.inDays < 1)     return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  Color _statusColor(BuildContext context) {
    if (state.isOffline && state.canUseAppOffline)  return const Color(0xFFF59E0B);
    if (state.isOffline && !state.canUseAppOffline) return context.appColors.danger;
    if (state.hasFailure)                           return context.appColors.danger;
    if (state.pendingSalesCount > 0)                return const Color(0xFFF59E0B);
    if (state.isBusy)                               return const Color(0xFF2563EB);
    return const Color(0xFF16A34A);
  }
}

// ── Sign out button ───────────────────────────────────────────────────────────

class _SignOutButton extends StatelessWidget {
  final VoidCallback onSignOut;
  const _SignOutButton({required this.onSignOut});

  @override
  Widget build(BuildContext context) {
    const red = Color(0xFFEF4444);

    return GestureDetector(
      onTap: onSignOut,
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppDims.s3, vertical: 8),
        decoration: BoxDecoration(
          color:        red.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppDims.rSm),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.logout_rounded, size: 15, color: red),
            const SizedBox(width: 5),
            Text(
              'Sign out',
              style: AppTextStyles.bs200(context).copyWith(
                color:      red,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Debug row (delete before release) ────────────────────────────────────────

class _DebugRow extends StatelessWidget {
  final VoidCallback onCleared;
  const _DebugRow({required this.onCleared});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return InkWell(
      onTap: () => _confirmClear(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: 20, vertical: 10),
        child: Row(
          children: [
            Icon(Icons.cleaning_services_rounded,
                size: 14, color: colors.textHint),
            const SizedBox(width: 7),
            Expanded(
              child: Text(
                'Clear local data — debug only',
                style: AppTextStyles.bs100(context).copyWith(
                  color:      colors.textHint,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color:        colors.surfaceSoft,
                borderRadius: BorderRadius.circular(4),
                border:       Border.all(color: colors.border),
              ),
              child: Text(
                'DEBUG',
                style: AppTextStyles.bs100(context).copyWith(
                  color:         colors.textHint,
                  fontWeight:    FontWeight.w900,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmClear(BuildContext context) async {
    final colors    = context.appColors;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.surface,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDims.rLg)),
        title:   const Text('Clear local data?'),
        content: const Text(
          'Deletes all cached data and pending offline sales. '
              'For testing only.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child:     const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: colors.danger,
              foregroundColor: Colors.white,
            ),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    try {
      await getIt<OfflineDb>().clearAllLocalOfflineData();
      onCleared();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Local data cleared.')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e')),
      );
    }
  }
}