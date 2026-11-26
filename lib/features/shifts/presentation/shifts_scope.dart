import 'package:amana_pos/common/auth_bloc/auth_bloc.dart';
import 'package:amana_pos/core/features/business_features.dart';
import 'package:amana_pos/core/offline/offline_db.dart';
import 'package:amana_pos/core/sync/db_change_notifier.dart';
import 'package:amana_pos/core/sync/local_writer.dart';
import 'package:amana_pos/core/sync/sync_state_store.dart';
import 'package:amana_pos/features/pos/presentation/bloc/pos_bloc.dart';
import 'package:amana_pos/utilities/dependencies_provider.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../domain/shift_reconciler.dart';
import '../domain/shift_service.dart';
import 'shifts_cubit.dart';

/// Builds a [ShiftsCubit] wired to the signed-in user, the selected shop and
/// the synced business switches. Everything is read lazily at call time, so a
/// shop switch or a role change is picked up without rebuilding.
ShiftsCubit buildShiftsCubit(BuildContext context) {
  final auth = context.read<AuthBloc>();
  final pos = context.read<PosBloc>();
  final features = getIt<BusinessFeaturesService>();
  final offline = getIt<OfflineDb>();

  String? shop() => pos.state.selectedShopId;

  ShiftActor? actor() {
    final p = auth.state.profile;
    final id = p?.id;
    if (id == null || id.isEmpty) return null;
    final perms = auth.state.permissions;
    return ShiftActor(
      id: id,
      name: p?.fullName ?? '',
      canManage: perms.isOwner || perms.isManager,
    );
  }

  final service = ShiftService(
    writer: getIt<LocalWriter>(),
    state: getIt<SyncStateStore>(),
    features: () => features.current,
    actor: actor,
    shopId: shop,
  );
  return ShiftsCubit(
    service: service,
    reconciler: ShiftReconciler(
      service: service,
      db: () => offline.database,
      features: () => features.current,
      shopId: shop,
      timezone: () async => features.current.timezone,
    ),
    features: features,
    db: offline,
    notifier: getIt<DbChangeNotifier>(),
    shopId: shop,
  );
}
