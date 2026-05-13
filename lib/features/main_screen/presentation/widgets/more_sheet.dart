import 'package:amana_pos/common/auth_bloc/auth_bloc.dart';
import 'package:amana_pos/config/router/route_strings.dart';
import 'package:amana_pos/core/offline/offline_db.dart';
import 'package:amana_pos/core/offline/presentation/bloc/offline_status_bloc.dart';
import 'package:amana_pos/features/main_screen/data/app_feature.dart';
import 'package:amana_pos/features/main_screen/data/feature_config.dart';
import 'package:amana_pos/features/main_screen/presentation/bloc/navigation_bloc.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/utilities/dependencies_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';


class MoreSheet extends StatelessWidget {
  final List<FeatureConfig> items;
  final AppFeature currentFeature;
  final String? userName;
  final bool isOwner;
  final String? businessName;

  const MoreSheet({super.key,
    required this.items,
    required this.currentFeature,
    required this.userName,
    required this.isOwner,
    required this.businessName,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [

              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.symmetric(vertical: AppDims.s3),
                  decoration: BoxDecoration(
                    color: colors.border,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),


              _UserHeader(
                userName: userName,
                isOwner: isOwner,
                businessName: businessName,
              ),

              Divider(height: 1, thickness: 0.5, color: colors.border),


              ...List.generate(items.length, (i) {
                final item = items[i];
                return _FeatureRow(
                  config: item,
                  isActive: item.feature == currentFeature,
                  showDivider: i < items.length - 1,
                  onTap: () {
                    Navigator.of(context).pop();
                    context.read<NavigationBloc>().add(
                      NavigationFeatureSelected(item.feature),
                    );
                  },
                )
                    .animate(delay: Duration(milliseconds: 60 + i * 55))
                    .fadeIn(duration: 220.ms)
                    .slideX(
                  begin: -0.04,
                  end: 0,
                  duration: 240.ms,
                  curve: Curves.easeOutCubic,
                );
              }),

              Divider(height: 1, thickness: 0.5, color: colors.border),


              _MoreFooter(),
            ],
          ),
        ),
      ),
    );
  }
}


class _UserHeader extends StatelessWidget {
  final String? userName;
  final bool isOwner;
  final String? businessName;

  const _UserHeader({
    required this.userName,
    required this.isOwner,
    required this.businessName,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final initials = _initials(userName);
    final roleLabel = isOwner ? 'Owner' : 'Cashier';
    const roleColor = Color(0xFF0D9488);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppDims.s4, AppDims.s2, AppDims.s4, AppDims.s4),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: colors.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                initials,
                style: AppTextStyles.bs300(context).copyWith(
                  fontWeight: FontWeight.w900,
                  color: colors.primary,
                ),
              ),
            ),
          ),

          const SizedBox(width: AppDims.s3),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userName ?? 'User',
                  style: AppTextStyles.bs200(context).copyWith(
                    fontWeight: FontWeight.w800,
                    color: colors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: roleColor.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: roleColor.withValues(alpha: 0.28),
                        ),
                      ),
                      child: Text(
                        roleLabel,
                        style: AppTextStyles.sm200(context).copyWith(
                          fontWeight: FontWeight.w800,
                          color: roleColor,
                        ),
                      ),
                    ),
                    if (businessName != null) ...[
                      const SizedBox(width: AppDims.s2),
                      Flexible(
                        child: Text(
                          businessName!,
                          style: AppTextStyles.sm200(context).copyWith(
                            fontWeight: FontWeight.w600,
                            color: colors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _initials(String? name) {
    if (name == null || name.trim().isEmpty) return '?';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }
}


class _FeatureRow extends StatelessWidget {
  final FeatureConfig config;
  final bool isActive;
  final bool showDivider;
  final VoidCallback onTap;

  const _FeatureRow({
    required this.config,
    required this.isActive,
    required this.showDivider,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Column(
      children: [
        InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppDims.s4, vertical: 13),
            child: Row(
              children: [
                // Icon badge
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: config.color.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(AppDims.rMd),
                  ),
                  child: Icon(config.icon, size: 22, color: config.color),
                ),

                const SizedBox(width: AppDims.s4),

                // Name + subtitle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        config.label,
                        style: AppTextStyles.bs200(context).copyWith(
                          fontWeight: FontWeight.w700,
                          color: isActive ? config.color : colors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        config.subtitle,
                        style: AppTextStyles.sm200(context).copyWith(
                          fontWeight: FontWeight.w500,
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),

                // Active check or forward arrow
                Icon(
                  isActive
                      ? Icons.check_circle_rounded
                      : Icons.arrow_forward_ios_rounded,
                  size: isActive ? 20 : 15,
                  color: isActive ? config.color : colors.textHint,
                ),
              ],
            ),
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            thickness: 0.5,
            indent: AppDims.s4 + 42 + AppDims.s4,
            color: colors.border.withValues(alpha: 0.6),
          ),
      ],
    );
  }
}


class _MoreFooter extends StatelessWidget {
  const _MoreFooter();

  static const String _appVersion = 'v1.0.0';
  static const Color _red = Color(0xFFEF4444);

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppDims.s4, AppDims.s3, AppDims.s4, AppDims.s4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          BlocBuilder<OfflineStatusBloc, OfflineStatusState>(
            bloc: getIt<OfflineStatusBloc>(),
            buildWhen: (prev, curr) =>
            prev.connectionStatus != curr.connectionStatus ||
                prev.bootstrapStatus != curr.bootstrapStatus ||
                prev.salesSyncStatus != curr.salesSyncStatus ||
                prev.pendingSalesCount != curr.pendingSalesCount,
            builder: (context, state) {
              final statusColor = _syncColor(context, state);
              final hasPending = state.pendingSalesCount > 0;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Status row
                  Row(
                    children: [
                      if (state.isBusy)
                        SizedBox(
                          width: 8,
                          height: 8,
                          child: CircularProgressIndicator(
                            strokeWidth: 1.5,
                            color: statusColor,
                          ),
                        )
                      else
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: statusColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                      const SizedBox(width: AppDims.s2),
                      Expanded(
                        child: Text(
                          '$_appVersion · ${state.connectionLabel} · ${state.statusLabel}',
                          style: AppTextStyles.sm200(context).copyWith(
                            fontWeight: FontWeight.w600,
                            color: colors.textHint,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),

                  // Pending sales action row
                  if (hasPending) ...[
                    const SizedBox(height: AppDims.s2),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.of(context).pop();
                              Navigator.of(context).pushNamed(
                                  RouteStrings.pendingSyncScreen);
                            },
                            icon: const Icon(Icons.receipt_long_rounded,
                                size: 15),
                            label: Text(
                              'View ${state.pendingSalesCount} pending',
                              style: AppTextStyles.sm300(context).copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFFF59E0B),
                              side: const BorderSide(
                                  color: Color(0xFFF59E0B), width: 1.2),
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(AppDims.rMd),
                              ),
                              minimumSize: const Size(0, 40),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppDims.s2),
                        OutlinedButton(
                          onPressed: state.isBusy
                              ? null
                              : () {
                                  Navigator.of(context).pop();
                                  getIt<OfflineStatusBloc>().add(
                                    const OnOfflineStatusSyncSalesRequested(),
                                  );
                                },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: colors.primary,
                            side: BorderSide(
                                color: colors.primary.withValues(alpha: 0.4)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppDims.rMd),
                            ),
                            minimumSize: const Size(0, 40),
                            padding: const EdgeInsets.symmetric(
                                horizontal: AppDims.s3),
                          ),
                          child: state.isBusy
                              ? SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: colors.primary,
                                  ),
                                )
                              : const Icon(Icons.sync_rounded, size: 18),
                        ),
                      ],
                    ),
                  ],
                ],
              );
            },
          ),

          const SizedBox(height: AppDims.s3),

          OutlinedButton.icon(
            onPressed: () => _confirmLogout(context),
            icon: const Icon(Icons.logout_rounded, size: 18, color: _red),
            label: Text(
              'Sign out',
              style: AppTextStyles.bs200(context).copyWith(
                fontWeight: FontWeight.w800,
                color: _red,
              ),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: _red,
              side: BorderSide(color: _red.withValues(alpha: 0.30)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDims.rMd),
              ),
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
          const SizedBox(height: AppDims.s1),

          _DebugRow(
            onCleared: () => getIt<OfflineStatusBloc>()
                .add(const OnOfflineStatusStarted()),
          ),
        ],
      ),
    );
  }

  Color _syncColor(BuildContext context, OfflineStatusState state) {
    final colors = context.appColors;
    if (state.isOffline && state.canUseAppOffline) return const Color(0xFFF59E0B);
    if (state.isOffline && !state.canUseAppOffline) return colors.danger;
    if (state.hasFailure) return colors.danger;
    if (state.pendingSalesCount > 0) return const Color(0xFFF59E0B);
    if (state.isBusy) return const Color(0xFF2563EB);
    return const Color(0xFF16A34A);
  }

  static Future<void> _confirmLogout(BuildContext context) async {
    // Close the More sheet first.
    Navigator.of(context).pop();

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (_) => const _LogoutDialog(),
    );

    if (confirmed == true) {
      getIt<AuthBloc>().add(const OnLogoutEvent());
    }
  }
}

class _DebugRow extends StatelessWidget {
  final VoidCallback onCleared;
  const _DebugRow({required this.onCleared});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return InkWell(
      onTap: () => _confirmClear(context),
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


class _LogoutDialog extends StatelessWidget {
  const _LogoutDialog();

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    const red = Color(0xFFEF4444);

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
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: red.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(AppDims.rLg),
              ),
              child: const Icon(Icons.logout_rounded, size: 26, color: red),
            ),
            const SizedBox(height: AppDims.s4),
            Text(
              'Sign out?',
              style: AppTextStyles.bs600(context).copyWith(
                fontWeight: FontWeight.w900,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: AppDims.s2),
            Text(
              'Make sure all your sales are synced before signing out. '
                  'Offline sales that have not synced will be lost.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bs300(context).copyWith(
                color: colors.textSecondary,
                fontWeight: FontWeight.w600,
                height: 1.45,
              ),
            ),
            const SizedBox(height: AppDims.s5),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colors.textSecondary,
                      side: BorderSide(color: colors.border),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppDims.rMd),
                      ),
                      minimumSize: const Size(0, 48),
                    ),
                    child: Text(
                      'Cancel',
                      style: AppTextStyles.bs400(context).copyWith(
                        fontWeight: FontWeight.w800,
                        color: colors.textSecondary,
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
                        borderRadius: BorderRadius.circular(AppDims.rMd),
                      ),
                      minimumSize: const Size(0, 48),
                    ),
                    child: Text(
                      'Sign out',
                      style: AppTextStyles.bs400(context).copyWith(
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
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
