import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/config/router/route_strings.dart';
import 'package:amana_pos/features/pos/presentation/bloc/pos_bloc.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/widgets/pressable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'shift_format.dart';
import 'shifts_cubit.dart';
import 'shifts_scope.dart';

/// The quiet shift chip in the POS top bar: "Shift 08:00", "No shift" or
/// "Needs count". Hidden when shifts are off. It also runs the auto schedule
/// (on start, on resume, every 30 s) and never touches a sale.
class ShiftChip extends StatelessWidget {
  const ShiftChip({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ShiftsCubit>(
      create: (c) => buildShiftsCubit(c)
        ..load()
        ..startSchedule(),
      child: const _ChipBody(),
    );
  }
}

class _ChipBody extends StatefulWidget {
  const _ChipBody();

  @override
  State<_ChipBody> createState() => _ChipBodyState();
}

class _ChipBodyState extends State<_ChipBody> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      context.read<ShiftsCubit>().tick();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<PosBloc, PosState>(
      listenWhen: (p, c) => p.selectedShopId != c.selectedShopId,
      listener: (context, _) => context.read<ShiftsCubit>().load(),
      child: BlocBuilder<ShiftsCubit, ShiftsState>(
        builder: (context, s) {
          if (s.loading || !s.features.shiftsEnabled) {
            return const SizedBox.shrink();
          }
          final tr = context.tr;
          final colors = context.appColors;
          final needs = s.open == null &&
              s.features.cashDrawer &&
              s.needsCount > 0;
          final (String label, Color fg, Color bg) = s.open != null
              ? (
                  tr.sfChipOpen(shiftClock(s.open!.openedAt, s.offset)),
                  colors.success,
                  colors.successContainer,
                )
              : needs
              ? (tr.sfChipNeedsCount, colors.warning, colors.warningContainer)
              : (tr.sfChipNone, colors.textSecondary, colors.surfaceSoft);
          return Pressable(
            onTap: () =>
                Navigator.of(context).pushNamed(RouteStrings.shiftsScreen),
            child: Container(
              height: 34,
              padding: const EdgeInsets.symmetric(horizontal: AppDims.s3),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: AppDims.borderPill,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(color: fg, shape: BoxShape.circle),
                    child: const SizedBox(width: 7, height: 7),
                  ),
                  const SizedBox(width: AppDims.s2 - 1),
                  Text(
                    label,
                    style: Theme.of(context).textTheme.labelMedium!.copyWith(
                      color: fg,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
