import 'package:amana_pos/common/auth_bloc/auth_bloc.dart';
import 'package:amana_pos/core/offline/offline_db.dart';
import 'package:amana_pos/core/offline/presentation/bloc/offline_status_bloc.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/utilities/dependencies_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class MenuFooter extends StatelessWidget {
  final VoidCallback? onSignOut;

  const MenuFooter({
    super.key,
    this.onSignOut,
  });

  static const String _appVersion = 'v1.0.0';

  @override
  Widget build(BuildContext context) {
    final bloc = getIt<OfflineStatusBloc>();

    return BlocBuilder<OfflineStatusBloc, OfflineStatusState>(
      bloc: bloc,
      builder: (context, state) {
        return Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDims.s4,
            vertical: AppDims.s3,
          ),
          decoration: BoxDecoration(
            color: context.appColors.surfaceSoft,
            border: Border(
              top: BorderSide(color: context.appColors.border),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: _SyncInfo(
                  appVersion: _appVersion,
                  state: state,
                ),
              ),

              if (kDebugMode) ...[
                const SizedBox(width: AppDims.s2),
                _ClearLocalDataButton(
                  onCleared: () {
                    getIt<OfflineStatusBloc>().add(
                      const OnOfflineStatusStarted(),
                    );
                  },
                ),
              ],

              const SizedBox(width: AppDims.s3),

              OutlinedButton.icon(
                onPressed: onSignOut ??
                        () => getIt<AuthBloc>().add(const OnLogoutEvent()),
                style: OutlinedButton.styleFrom(
                  foregroundColor: context.appColors.danger,
                  backgroundColor: context.appColors.background,
                  side: BorderSide(color: context.appColors.border),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDims.s3,
                    vertical: AppDims.s2,
                  ),
                  minimumSize: const Size(0, 36),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppDims.rSm),
                  ),
                  textStyle: const TextStyle(
                    fontFamily: 'NunitoSans',
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                icon: Icon(
                  Icons.logout_rounded,
                  size: 16,
                  color: context.appColors.danger,
                ),
                label: Text(
                  'Sign out',
                  style: TextStyle(color: context.appColors.danger),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ClearLocalDataButton extends StatelessWidget {
  const _ClearLocalDataButton({
    required this.onCleared,
  });

  final VoidCallback onCleared;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Clear local offline data',
      child: IconButton(
        onPressed: () => _confirmClear(context),
        style: IconButton.styleFrom(
          backgroundColor: context.appColors.background,
          side: BorderSide(color: context.appColors.border),
          minimumSize: const Size(36, 36),
          fixedSize: const Size(36, 36),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDims.rSm),
          ),
        ),
        icon: Icon(
          Icons.cleaning_services_rounded,
          size: 17,
          color: context.appColors.danger,
        ),
      ),
    );
  }

  Future<void> _confirmClear(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Clear local data?'),
          content: const Text(
            'This will delete cached businesses, products, categories, stock, customers, assets, and pending offline sales from this device only. This is for testing.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: context.appColors.danger,
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
          content: Text('Local offline data cleared.'),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to clear local data: $e'),
        ),
      );
    }
  }
}

class _SyncInfo extends StatelessWidget {
  const _SyncInfo({
    required this.appVersion,
    required this.state,
  });

  final String appVersion;
  final OfflineStatusState state;

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(context);
    final icon = _statusIcon();

    return InkWell(
      borderRadius: BorderRadius.circular(AppDims.rSm),
      onTap: () {
        getIt<OfflineStatusBloc>().add(
          const OnOfflineStatusRefreshRequested(),
        );
      },
      child: Row(
        children: [
          if (state.isBusy)
            SizedBox(
              width: 13,
              height: 13,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: color,
              ),
            )
          else
            Icon(
              icon,
              size: 15,
              color: color,
            ),
          const SizedBox(width: AppDims.s2),
          Flexible(
            child: Text(
              _label(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'NunitoSans',
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: context.appColors.textHint,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _label() {
    final parts = <String>[
      appVersion,
      state.connectionLabel,
      state.statusLabel,
    ];

    final lastSync = _lastSyncText();
    if (lastSync != null) {
      parts.add(lastSync);
    }

    return parts.join(' · ');
  }

  String? _lastSyncText() {
    final date = state.latestSyncAt;
    if (date == null) return null;

    final diff = DateTime.now().difference(date);

    if (diff.inSeconds < 30) return 'just now';
    if (diff.inMinutes < 1) return '${diff.inSeconds}s ago';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';

    return '${diff.inDays}d ago';
  }

  IconData _statusIcon() {
    if (state.isOffline) return Icons.cloud_off_rounded;
    if (state.hasFailure) return Icons.error_outline_rounded;
    if (state.pendingSalesCount > 0) return Icons.sync_problem_rounded;
    return Icons.cloud_done_rounded;
  }

  Color _statusColor(BuildContext context) {
    if (state.isOffline && state.canUseAppOffline) {
      return const Color(0xFFF59E0B);
    }

    if (state.isOffline && !state.canUseAppOffline) {
      return context.appColors.danger;
    }

    if (state.hasFailure) {
      return context.appColors.danger;
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