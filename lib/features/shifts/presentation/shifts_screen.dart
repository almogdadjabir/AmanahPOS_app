import 'package:amana_pos/common/auth_bloc/auth_bloc.dart';
import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/features/settings/presentation/widgets/settings_widgets.dart';
import 'package:amana_pos/l10n/app_localizations.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/theme/phosphor_icons.dart';
import 'package:amana_pos/widgets/app_button.dart';
import 'package:amana_pos/widgets/app_group.dart';
import 'package:amana_pos/widgets/app_large_title.dart';
import 'package:amana_pos/widgets/app_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../domain/shift.dart';
import 'shift_action_sheet.dart';
import 'shift_format.dart';
import 'shifts_cubit.dart';

/// Shifts: the open shift with the cash that should be in the drawer, its
/// pay-in/out, close, and the history. Hidden entirely when the owner turned
/// shifts off in the dashboard.
class ShiftsScreen extends StatefulWidget {
  const ShiftsScreen({super.key});

  @override
  State<ShiftsScreen> createState() => _ShiftsScreenState();
}

class _ShiftsScreenState extends State<ShiftsScreen> {
  @override
  void initState() {
    super.initState();
    context.read<ShiftsCubit>().load();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final tr = context.tr;
    final perms = context.select<AuthBloc, bool>(
      (b) => b.state.permissions.isOwner || b.state.permissions.isManager,
    );

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            SettingsNavBar(backLabel: tr.back),
            Expanded(
              child: BlocBuilder<ShiftsCubit, ShiftsState>(
                builder: (context, s) {
                  final canOperate = perms || s.features.cashiersMayOperateShifts;
                  return ListView(
                    padding: EdgeInsets.fromLTRB(
                      AppDims.s4,
                      0,
                      AppDims.s4,
                      AppDims.s8 + MediaQuery.viewPaddingOf(context).bottom,
                    ),
                    children: [
                      AppLargeTitle(title: tr.sfTitle),
                      ..._body(context, s, canOperate),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _body(BuildContext context, ShiftsState s, bool canOperate) {
    final tr = context.tr;
    final cubit = context.read<ShiftsCubit>();
    if (s.loading) {
      return const [
        Padding(
          padding: EdgeInsets.all(AppDims.s8),
          child: Center(child: CircularProgressIndicator()),
        ),
      ];
    }
    if (s.failed) {
      return [
        _Message(
          icon: PhosphorIconsRegular.warning,
          title: tr.sfLoadFailed,
          action: AppButton(
            label: tr.sfTryAgain,
            variant: AppButtonVariant.secondary,
            onPressed: cubit.load,
          ),
        ),
      ];
    }
    if (!s.features.shiftsEnabled) {
      return [
        _Message(
          icon: PhosphorIconsRegular.clock,
          title: tr.sfOffTitle,
          help: tr.sfOffHelp,
        ),
      ];
    }
    return [
      if (s.needsCount > 0 && s.features.cashDrawer)
        Padding(
          padding: const EdgeInsets.only(bottom: AppDims.s3),
          child: _Banner(text: tr.sfNeedsCountBanner(s.needsCount)),
        ),
      if (s.open == null)
        _Message(
          icon: PhosphorIconsRegular.clock,
          title: tr.sfNoShiftTitle,
          help: tr.sfNoShiftHelp,
          action: canOperate
              ? AppButton(
                  label: tr.sfActOpen,
                  onPressed: () => showShiftActionSheet(
                    context,
                    cubit: cubit,
                    mode: ShiftSheetMode.open,
                  ),
                )
              : null,
        )
      else
        ..._openShift(context, s, canOperate),
      const SizedBox(height: AppDims.s5),
      ..._history(context, s),
    ];
  }

  List<Widget> _openShift(BuildContext context, ShiftsState s, bool canOperate) {
    final tr = context.tr;
    final colors = context.appColors;
    final text = Theme.of(context).textTheme;
    final cubit = context.read<ShiftsCubit>();
    final open = s.open!;
    final f = s.figures!;
    final off = s.offset;
    final since = shiftClock(open.openedAt, off);
    final who = open.origin == ShiftOrigin.auto
        ? tr.sfOpenedAuto(since)
        : tr.sfOpenedBy(since, open.openedByName ?? '—');
    final drawer = s.features.cashDrawer;

    Widget row(String title, BigInt v, {bool minus = false}) => AppGroupRow(
      title: title,
      value: '${minus && v > BigInt.zero ? '−' : ''}${shiftMoney(v)}',
      showChevron: false,
    );

    return [
      Container(
        padding: const EdgeInsets.all(AppDims.s4),
        decoration: BoxDecoration(
          color: colors.primaryContainer,
          borderRadius: BorderRadius.circular(AppDims.s4),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              drawer ? tr.sfExpected : tr.sfCurrent,
              style: text.bodySmall!.copyWith(color: colors.textSecondary),
            ),
            const SizedBox(height: AppDims.s1),
            if (drawer)
              Text(
                shiftMoney(f.expected),
                textDirection: TextDirection.ltr,
                style: text.headlineMedium!.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              )
            else
              Row(
                children: [
                  _Stat(label: tr.sfSales, value: '${f.salesCount}'),
                  const SizedBox(width: AppDims.s6),
                  _Stat(
                    label: tr.sfTotal,
                    value: shiftMoney(f.salesTotal ?? BigInt.zero),
                  ),
                ],
              ),
            const SizedBox(height: AppDims.s1),
            Text(
              who,
              style: text.bodySmall!.copyWith(color: colors.textSecondary),
            ),
          ],
        ),
      ),
      const SizedBox(height: AppDims.s3),
      if (drawer)
        AppGroup(
          children: [
            row(tr.sfOpening, f.parts.opening),
            row(tr.sfCashSales, f.parts.cashSales),
            row(tr.sfDebtPayments, f.parts.debtPayments),
            row(tr.sfPayIns, f.parts.payIns),
            row(
              tr.sfRefunds,
              f.parts.refunds + f.parts.cancels,
              minus: true,
            ),
            row(tr.sfPayOuts, f.parts.payOuts, minus: true),
          ],
        )
      else
        AppGroup(
          footer: tr.sfDrawerOff,
          children: [
            row('${tr.sfActOpen} · ${tr.sfCashSales}', f.parts.cashSales),
            for (final o in f.other) row(o.method, o.amount),
          ],
        ),
      if (drawer && f.other.isNotEmpty)
        Padding(
          padding: const EdgeInsets.only(top: AppDims.s2),
          child: Text(
            tr.sfOther(
              f.other
                  .map((o) => '${o.method} ${shiftMoney(o.amount)}')
                  .join(', '),
            ),
            style: text.bodySmall!.copyWith(color: colors.textSecondary),
          ),
        ),
      const SizedBox(height: AppDims.s4),
      if (drawer)
        Row(
          spacing: AppDims.s2,
          children: [
            Expanded(
              child: AppButton(
                label: tr.sfActPayIn,
                variant: AppButtonVariant.secondary,
                onPressed: () => showShiftActionSheet(
                  context,
                  cubit: cubit,
                  mode: ShiftSheetMode.payIn,
                  expected: f.expected,
                ),
              ),
            ),
            Expanded(
              child: AppButton(
                label: tr.sfActPayOut,
                variant: AppButtonVariant.secondary,
                onPressed: () => showShiftActionSheet(
                  context,
                  cubit: cubit,
                  mode: ShiftSheetMode.payOut,
                  expected: f.expected,
                ),
              ),
            ),
          ],
        ),
      if (canOperate) ...[
        const SizedBox(height: AppDims.s2),
        AppButton.wide(
          label: tr.sfActClose,
          onPressed: () => drawer
              ? showShiftActionSheet(
                  context,
                  cubit: cubit,
                  mode: ShiftSheetMode.close,
                  expected: f.expected,
                )
              : _closeWithoutCount(context),
        ),
      ],
    ];
  }

  Future<void> _closeWithoutCount(BuildContext context) async {
    final tr = context.tr;
    final cubit = context.read<ShiftsCubit>();
    final ok = await showAppConfirmSheet(
      context,
      title: tr.sfWClose,
      confirmLabel: tr.sfActClose,
      destructive: false,
    );
    if (!ok || !context.mounted) return;
    final r = await cubit.closeShift();
    if (!context.mounted) return;
    shiftToast(context, r, tr.sfDoneClose);
  }

  List<Widget> _history(BuildContext context, ShiftsState s) {
    final tr = context.tr;
    final cubit = context.read<ShiftsCubit>();
    if (s.history.isEmpty) {
      return [
        AppGroup(
          header: tr.sfHistory,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppDims.s4),
              child: Text(
                tr.sfHistoryEmpty,
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  color: context.appColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ];
    }
    return [
      AppGroup(
        header: tr.sfHistory,
        children: [
          for (final h in s.history)
            AppGroupRow(
              title: shiftSpan(h.openedAt, h.closedAt, s.offset),
              subtitle: h.origin == ShiftOrigin.auto
                  ? tr.sfOriginAuto
                  : tr.sfOriginManual,
              trailing: s.features.cashDrawer ? _StatePill(shift: h) : null,
              onTap: () => _detail(context, h),
            ),
        ],
      ),
      if (s.hasMore)
        Padding(
          padding: const EdgeInsets.only(top: AppDims.s3),
          child: AppButton(
            label: tr.sfShowMore,
            variant: AppButtonVariant.secondary,
            onPressed: cubit.loadMore,
          ),
        ),
    ];
  }

  Future<void> _detail(BuildContext context, ShiftInfo shift) {
    final cubit = context.read<ShiftsCubit>();
    return showAppSheet<void>(
      context,
      builder: (_) => BlocProvider.value(
        value: cubit,
        child: _ShiftDetailSheet(shift: shift),
      ),
    );
  }
}

class _ShiftDetailSheet extends StatelessWidget {
  const _ShiftDetailSheet({required this.shift});

  final ShiftInfo shift;

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    final cubit = context.read<ShiftsCubit>();
    final s = cubit.state;
    return AppSheet(
      title: shiftSpan(shift.openedAt, shift.closedAt, s.offset),
      child: FutureBuilder(
        future: cubit.detail(shift),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Padding(
              padding: EdgeInsets.all(AppDims.s8),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final f = snap.data!.$1;
          final drawer = s.features.cashDrawer;
          Widget row(String t, BigInt v) =>
              AppGroupRow(title: t, value: shiftMoney(v), showChevron: false);
          return Padding(
            padding: const EdgeInsets.fromLTRB(
              AppDims.s4,
              0,
              AppDims.s4,
              AppDims.s4,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppGroup(
                  children: [
                    if (drawer) ...[
                      row(tr.sfOpening, f.parts.opening),
                      row(tr.sfCashSales, f.parts.cashSales),
                      row(tr.sfPayIns, f.parts.payIns),
                      row(tr.sfRefunds, f.parts.refunds),
                      row(tr.sfPayOuts, f.parts.payOuts),
                      row(tr.sfLExpected, shift.expected ?? f.expected),
                      if (shift.counted != null)
                        row(tr.sfLCounted, shift.counted!),
                    ] else ...[
                      row(tr.sfCashSales, f.parts.cashSales),
                      for (final o in f.other) row(o.method, o.amount),
                      row(tr.sfTotal, f.salesTotal ?? BigInt.zero),
                    ],
                  ],
                ),
                if (drawer && shift.state == ShiftState.needsCount) ...[
                  const SizedBox(height: AppDims.s3),
                  AppButton.wide(
                    label: tr.sfActCount,
                    onPressed: () {
                      Navigator.of(context).pop();
                      showShiftActionSheet(
                        context,
                        cubit: cubit,
                        mode: ShiftSheetMode.count,
                        shift: shift,
                      );
                    },
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StatePill extends StatelessWidget {
  const _StatePill({required this.shift});

  final ShiftInfo shift;

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    final colors = context.appColors;
    final (String label, Color fg, Color bg) = switch (shift.state) {
      ShiftState.needsCount => (
        tr.sfChipNeedsCount,
        colors.warning,
        colors.warningContainer,
      ),
      ShiftState.counted => _diff(tr, colors),
      ShiftState.open => (tr.sfChipOpen(''), colors.success, colors.successContainer),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall!.copyWith(
          color: fg,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  (String, Color, Color) _diff(AppLocalizations tr, AppThemeColors colors) {
    final d = shift.difference ?? BigInt.zero;
    if (d == BigInt.zero) {
      return (tr.sfDiffEven, colors.success, colors.successContainer);
    }
    return d.isNegative
        ? (tr.sfDiffShort(shiftMoney(-d)), colors.danger, colors.dangerContainer)
        : (tr.sfDiffOver(shiftMoney(d)), colors.info, colors.infoContainer);
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: text.bodySmall!.copyWith(
            color: context.appColors.textSecondary,
          ),
        ),
        Text(
          value,
          textDirection: TextDirection.ltr,
          style: text.titleLarge!.copyWith(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsets.all(AppDims.s3),
      decoration: BoxDecoration(
        color: colors.warningContainer,
        borderRadius: BorderRadius.circular(AppDims.s3),
      ),
      child: Row(
        spacing: AppDims.s2,
        children: [
          Icon(PhosphorIconsRegular.warning, color: colors.warning, size: 18),
          Expanded(
            child: Text(
              text,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium!.copyWith(color: colors.warning),
            ),
          ),
        ],
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({
    required this.icon,
    required this.title,
    this.help,
    this.action,
  });

  final IconData icon;
  final String title;
  final String? help;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(AppDims.s6),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppDims.s4),
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: colors.primaryContainer,
              borderRadius: BorderRadius.circular(AppDims.s4),
            ),
            child: Icon(icon, color: colors.primary, size: 26),
          ),
          const SizedBox(height: AppDims.s3),
          Text(
            title,
            textAlign: TextAlign.center,
            style: text.titleMedium!.copyWith(fontWeight: FontWeight.w700),
          ),
          if (help != null) ...[
            const SizedBox(height: AppDims.s2),
            Text(
              help!,
              textAlign: TextAlign.center,
              style: text.bodyMedium!.copyWith(color: colors.textSecondary),
            ),
          ],
          if (action != null) ...[
            const SizedBox(height: AppDims.s4),
            action!,
          ],
        ],
      ),
    );
  }
}
