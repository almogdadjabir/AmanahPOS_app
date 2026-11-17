import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/core/sync/sync_state_store.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/theme/phosphor_icons.dart';
import 'package:amana_pos/utilities/dependencies_provider.dart';
import 'package:flutter/material.dart';

/// Shown on the login screen after a revoke / disable that left unsynced
/// rows on the device (see RevokeSessionPolicy). Renders nothing otherwise.
class RevokedPendingNotice extends StatefulWidget {
  const RevokedPendingNotice({super.key, this.loader});

  /// Test seam; defaults to the app's [SyncStateStore].
  final Future<RevokeMarker?> Function()? loader;

  @override
  State<RevokedPendingNotice> createState() => _RevokedPendingNoticeState();
}

class _RevokedPendingNoticeState extends State<RevokedPendingNotice> {
  RevokeMarker? _marker;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final load =
          widget.loader ?? () => getIt<SyncStateStore>().revokeMarker();
      final m = await load();
      if (mounted) setState(() => _marker = m);
    } catch (_) {
      // No notice rather than a broken login screen.
    }
  }

  @override
  Widget build(BuildContext context) {
    final m = _marker;
    if (m == null) return const SizedBox.shrink();
    final colors = context.appColors;
    final text = Theme.of(context).textTheme;
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.all(AppDims.s4),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colors.dangerContainer,
            borderRadius: AppDims.borderLg,
            border: Border.all(color: colors.danger.withValues(alpha: 0.25)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppDims.s4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  PhosphorIconsRegular.warningCircle,
                  size: 22,
                  color: colors.danger,
                ),
                const SizedBox(width: AppDims.s3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.tr.loginRevokedPendingTitle,
                        style: text.titleSmall!.copyWith(
                          color: colors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        context.tr.loginRevokedPendingBody(m.pendingCount),
                        style: text.bodyMedium!.copyWith(
                          color: colors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
