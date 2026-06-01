import 'package:amana_pos/common/auth_bloc/auth_bloc.dart';
import 'package:amana_pos/core/offline/presentation/bloc/offline_status_bloc.dart';
import 'package:amana_pos/features/main_screen/presentation/widgets/location_chip.dart';
import 'package:amana_pos/features/main_screen/presentation/widgets/notification_button.dart';
import 'package:amana_pos/features/main_screen/presentation/widgets/sync_pill.dart';
import 'package:amana_pos/features/pos/presentation/bloc/pos_bloc.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/utilities/dependencies_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class PosAppBar extends StatelessWidget {
  const PosAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDims.s4).copyWith(
        top: AppDims.s2,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            spacing: AppDims.s2,
            children: [
              BlocSelector<AuthBloc, AuthState, bool>(
                selector: (s) => s.permissions.isOwner,
                builder: (context, isOwner) {
                  if (!isOwner) return const SizedBox.shrink();
                  return const NotificationButton();
                },
              ),

              Expanded(
                child: BlocBuilder<AuthBloc, AuthState>(
                  buildWhen: (p, c) =>
                  p.defaultBusiness != c.defaultBusiness ||
                      p.businessStatus != c.businessStatus,
                  builder: (context, authState) {
                    return BlocBuilder<PosBloc, PosState>(
                      buildWhen: (p, c) =>
                      p.selectedShopId != c.selectedShopId ||
                          p.selectedShopName != c.selectedShopName,
                      builder: (context, posState) {
                        return LocationChip(
                          business: authState.defaultBusiness,
                          selectedShopId: posState.selectedShopId,
                        );
                      },
                    );
                  },
                ),
              ),

              BlocBuilder<OfflineStatusBloc, OfflineStatusState>(
                bloc: getIt<OfflineStatusBloc>(),
                buildWhen: (p, c) =>
                p.connectionStatus != c.connectionStatus ||
                    p.bootstrapStatus != c.bootstrapStatus ||
                    p.salesSyncStatus != c.salesSyncStatus ||
                    p.pendingSalesCount != c.pendingSalesCount,
                builder: (context, state) => SyncPill(state: state),
              ),
            ],
          ),

          const SizedBox(height: AppDims.s4),

          Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  colors.border.withValues(alpha: 0.16),
                  colors.primary.withValues(alpha: 0.30),
                  colors.border.withValues(alpha: 0.16),
                  Colors.transparent,
                ],
                stops: const [0.00, 0.22, 0.50, 0.78, 1.00],
              ),
            ),
          ),
        ],
      ),
    );
  }
}