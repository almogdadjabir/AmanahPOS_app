import 'dart:async';

import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/core/sync/db_change_notifier.dart';
import 'package:amana_pos/core/sync/sync_schema.dart';
import 'package:amana_pos/core/sync/sync_scope.dart';
import 'package:amana_pos/core/sync/sync_state_store.dart';
import 'package:amana_pos/common/auth_bloc/auth_bloc.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/utilities/dependencies_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Pure view: shown only to the owner while the checksum self-audit reports
/// `drift` (local totals still differ from the server after a repair).
class DataDriftBannerView extends StatelessWidget {
  const DataDriftBannerView({
    super.key,
    required this.isOwner,
    required this.state,
  });

  final bool isOwner;
  final AuditState? state;

  @override
  Widget build(BuildContext context) {
    if (!isOwner || state == null || !state!.isDrift) {
      return const SizedBox.shrink();
    }
    final colors = context.appColors;
    final tr = context.tr;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.warningContainer,
          borderRadius: AppDims.borderLg,
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppDims.s4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tr.shDataDriftTitle,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: colors.warning,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                tr.shDataDriftBody,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.35,
                  color: colors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Wires [DataDriftBannerView] to the persisted audit state of the signed-in
/// scope; re-reads on every `sync_state` table change. Best-effort: any
/// failure shows nothing.
class DataDriftBanner extends StatefulWidget {
  const DataDriftBanner({super.key});

  @override
  State<DataDriftBanner> createState() => _DataDriftBannerState();
}

class _DataDriftBannerState extends State<DataDriftBanner> {
  AuditState? _state;
  StreamSubscription<Set<String>>? _sub;

  @override
  void initState() {
    super.initState();
    _load();
    try {
      _sub = getIt<DbChangeNotifier>().changes.listen((t) {
        if (t.contains(SyncTables.syncState)) _load();
      });
    } catch (_) {}
  }

  Future<void> _load() async {
    try {
      final scope = SyncScope.current;
      final s = scope == null
          ? null
          : await getIt<SyncStateStore>().forScope(scope).auditState();
      if (mounted) setState(() => _state = s);
    } catch (_) {
      // Never keep another scope's drift on screen.
      if (mounted) setState(() => _state = null);
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // No AuthBloc above (a bare test tree) = not an owner = nothing shown.
    var isOwner = false;
    try {
      isOwner = context.watch<AuthBloc>().state.permissions.isOwner;
    } catch (_) {}
    return DataDriftBannerView(isOwner: isOwner, state: _state);
  }
}
