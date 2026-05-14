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
import 'package:solar_icons/solar_icons.dart';

class MenuFooter extends StatelessWidget {
  final VoidCallback? onSignOut;

  const MenuFooter({
    super.key,
    this.onSignOut,
  });

  static const String _appVersion = 'v1.0.0';

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return SafeArea(
      top: false,
      child: BlocBuilder<OfflineStatusBloc, OfflineStatusState>(
        bloc: getIt<OfflineStatusBloc>(),
        builder: (context, state) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Divider(
                height: 1,
                thickness: 0.5,
                color: colors.border,
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppDims.s4,
                  AppDims.s3,
                  AppDims.s4,
                  AppDims.s3,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _SyncInfo(
                        version: _appVersion,
                        state: state,
                      ),
                    ),
                    const SizedBox(width: AppDims.s3),
                    _SignOutButton(
                      onSignOut: onSignOut ?? () => _confirmSignOut(context),
                    ),
                  ],
                ),
              ),

              if (kDebugMode) ...[
                Divider(
                  height: 1,
                  thickness: 0.5,
                  color: colors.border,
                ),
                _DebugRow(
                  onCleared: () {
                    getIt<OfflineStatusBloc>().add(
                      const OnOfflineStatusStarted(),
                    );
                  },
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

class _LogoutDialog extends StatelessWidget {
  const _LogoutDialog();

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    const danger = Color(0xFFEF4444);
    const warning = Color(0xFFF59E0B);

    return Dialog(
      elevation: 0,
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(
        horizontal: AppDims.s4,
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppDims.s4),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(AppDims.rXl),
          border: Border.all(
            color: colors.border,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 24,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: danger.withValues(alpha: 0.09),
                    borderRadius: BorderRadius.circular(AppDims.rLg),
                    border: Border.all(
                      color: danger.withValues(alpha: 0.16),
                    ),
                  ),
                  child: const Icon(
                    SolarIconsOutline.logout,
                    size: 25,
                    color: danger,
                  ),
                ),

                const SizedBox(width: AppDims.s3),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sign out?',
                        style: AppTextStyles.bs600(context).copyWith(
                          color: colors.textPrimary,
                          fontWeight: FontWeight.w900,
                          height: 1.05,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'You are about to leave this device session.',
                        style: AppTextStyles.bs200(context).copyWith(
                          color: colors.textSecondary,
                          fontWeight: FontWeight.w700,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppDims.s4),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppDims.s3),
              decoration: BoxDecoration(
                color: warning.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppDims.rLg),
                border: Border.all(
                  color: warning.withValues(alpha: 0.18),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    SolarIconsOutline.dangerTriangle,
                    size: 20,
                    color: warning,
                  ),
                  const SizedBox(width: AppDims.s2),
                  Expanded(
                    child: Text(
                      'Make sure all sales are synced before signing out. Unsynced offline sales may be lost.',
                      style: AppTextStyles.bs200(context).copyWith(
                        color: colors.textSecondary,
                        fontWeight: FontWeight.w700,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppDims.s5),

            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 50,
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: colors.textPrimary,
                        side: BorderSide(
                          color: colors.border,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppDims.rMd),
                        ),
                      ),
                      child: Text(
                        'Keep working',
                        style: AppTextStyles.bs300(context).copyWith(
                          color: colors.textSecondary,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: AppDims.s3),

                Expanded(
                  child: SizedBox(
                    height: 50,
                    child: FilledButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      style: FilledButton.styleFrom(
                        backgroundColor: danger,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppDims.rMd),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            SolarIconsOutline.logout,
                            size: 17,
                            color: Colors.white,
                          ),
                          const SizedBox(width: AppDims.s2),
                          Text(
                            'Sign out',
                            style: AppTextStyles.bs300(context).copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
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

class _SyncInfo extends StatelessWidget {
  final String version;
  final OfflineStatusState state;

  const _SyncInfo({
    required this.version,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final color = _statusColor(context);

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppDims.rMd),
      child: InkWell(
        onTap: () {
          getIt<OfflineStatusBloc>().add(
            const OnOfflineStatusRefreshRequested(),
          );
        },
        borderRadius: BorderRadius.circular(AppDims.rMd),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDims.s1,
            vertical: AppDims.s1,
          ),
          child: Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(AppDims.rSm),
                ),
                child: Center(
                  child: state.isBusy
                      ? SizedBox(
                    width: 13,
                    height: 13,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: color,
                    ),
                  )
                      : Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: AppDims.s2),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _mainLabel(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bs100(context).copyWith(
                        color: colors.textSecondary,
                        fontWeight: FontWeight.w900,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _subLabel(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.sm100(context).copyWith(
                        color: colors.textHint,
                        fontWeight: FontWeight.w700,
                        height: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _mainLabel() {
    return '${state.connectionLabel} · ${state.statusLabel}';
  }

  String _subLabel() {
    final sync = _syncText();
    if (sync == null) return version;
    return '$version · Synced $sync';
  }

  String? _syncText() {
    final date = state.latestSyncAt;

    if (date == null) {
      return null;
    }

    final diff = DateTime.now().difference(date);

    if (diff.inSeconds < 30) return 'just now';
    if (diff.inMinutes < 1) return '${diff.inSeconds}s ago';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';

    return '${diff.inDays}d ago';
  }

  Color _statusColor(BuildContext context) {
    final colors = context.appColors;

    if (state.isOffline && state.canUseAppOffline) {
      return const Color(0xFFF59E0B);
    }

    if (state.isOffline && !state.canUseAppOffline) {
      return colors.danger;
    }

    if (state.hasFailure) {
      return colors.danger;
    }

    if (state.pendingSalesCount > 0) {
      return const Color(0xFFF59E0B);
    }

    if (state.isBusy) {
      return const Color(0xFF2563EB);
    }

    return const Color(0xFF16A34A);
  }
}

class _SignOutButton extends StatelessWidget {
  final VoidCallback onSignOut;

  const _SignOutButton({
    required this.onSignOut,
  });

  @override
  Widget build(BuildContext context) {
    const danger = Color(0xFFEF4444);

    return Material(
      color: danger.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(AppDims.rMd),
      child: InkWell(
        onTap: onSignOut,
        borderRadius: BorderRadius.circular(AppDims.rMd),
        child: Container(
          height: 40,
          padding: const EdgeInsets.symmetric(
            horizontal: AppDims.s3,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppDims.rMd),
            border: Border.all(
              color: danger.withValues(alpha: 0.14),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                SolarIconsOutline.logout,
                size: 16,
                color: danger,
              ),
              const SizedBox(width: 6),
              Text(
                'Sign out',
                style: AppTextStyles.bs200(context).copyWith(
                  color: danger,
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

class _DebugRow extends StatelessWidget {
  final VoidCallback onCleared;

  const _DebugRow({
    required this.onCleared,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return InkWell(
      onTap: () => _confirmClear(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDims.s4,
          vertical: AppDims.s3,
        ),
        child: Row(
          children: [
            Icon(
              SolarIconsOutline.trashBinTrash,
              size: 15,
              color: colors.textHint,
            ),
            const SizedBox(width: AppDims.s2),
            Expanded(
              child: Text(
                'Clear local data — debug only',
                style: AppTextStyles.bs100(context).copyWith(
                  color: colors.textHint,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 7,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: colors.surfaceSoft,
                borderRadius: BorderRadius.circular(AppDims.rXs),
                border: Border.all(
                  color: colors.border,
                ),
              ),
              child: Text(
                'DEBUG',
                style: AppTextStyles.bs100(context).copyWith(
                  color: colors.textHint,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.8,
                  height: 1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmClear(BuildContext context) async {
    final colors = context.appColors;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: colors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDims.rLg),
          ),
          title: Text(
            'Clear local data?',
            style: AppTextStyles.bs600(context).copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w900,
            ),
          ),
          content: Text(
            'Deletes all cached data and pending offline sales. For testing only.',
            style: AppTextStyles.bs300(context).copyWith(
              color: colors.textSecondary,
              fontWeight: FontWeight.w700,
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
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
        );
      },
    );

    if (confirmed != true) return;

    try {
      await getIt<OfflineDb>().clearAllLocalOfflineData();
      onCleared();

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Local data cleared.'),
        ),
      );
    } catch (error) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed: $error'),
        ),
      );
    }
  }
}