import 'package:amana_pos/common/auth_bloc/auth_bloc.dart';
import 'package:amana_pos/core/features/business_features.dart';
import 'package:amana_pos/core/sync/local_writer.dart';
import 'package:amana_pos/features/pos/presentation/bloc/pos_bloc.dart';
import 'package:amana_pos/utilities/dependencies_provider.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../domain/debt_service.dart';

/// A [DebtService] wired to the signed-in user, the selected shop and the
/// synced business switches (all read at call time).
DebtService buildDebtService(BuildContext context) {
  final auth = context.read<AuthBloc>();
  final pos = context.read<PosBloc>();
  final features = getIt<BusinessFeaturesService>();
  return DebtService(
    writer: getIt<LocalWriter>(),
    features: () => features.current,
    shopId: () => pos.state.selectedShopId,
    actor: () {
      final p = auth.state.profile;
      final id = p?.id;
      if (id == null || id.isEmpty) return null;
      final perms = auth.state.permissions;
      return DebtActor(
        id: id,
        name: p?.fullName ?? '',
        canManage: perms.isOwner || perms.isManager,
      );
    },
  );
}
