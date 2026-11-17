import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/features/category/presentation/widgets/category_states.dart';
import 'package:amana_pos/features/sync/presentation/bloc/pending_sync_bloc.dart';
import 'package:amana_pos/features/sync/presentation/pending_sync_outbox_view.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/theme/phosphor_icons.dart';
import 'package:amana_pos/widgets/app_large_title.dart';
import 'package:amana_pos/widgets/directional_icon.dart';
import 'package:amana_pos/widgets/pressable.dart';
import 'package:amana_pos/widgets/shimmer.dart';
import 'package:flutter/cupertino.dart' show CupertinoSliverRefreshControl;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class PendingSyncScreen extends StatefulWidget {
  const PendingSyncScreen({super.key});

  @override
  State<PendingSyncScreen> createState() => _PendingSyncScreenState();
}

class _PendingSyncScreenState extends State<PendingSyncScreen> {
  @override
  void initState() {
    super.initState();
    context.read<PendingSyncBloc>().add(const OnPendingSyncLoad());
  }

  Future<void> _refresh() async {
    final bloc = context.read<PendingSyncBloc>();
    bloc.add(const OnPendingSyncLoad());
    try {
      await bloc.stream
          .firstWhere(
            (s) =>
                s.status == PendingSyncStatus.loaded ||
                s.status == PendingSyncStatus.error,
          )
          .timeout(const Duration(seconds: 10));
    } catch (_) {
      // Timed out: let the control settle.
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom + 24;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const _NavBar(),
            Expanded(
              child: BlocConsumer<PendingSyncBloc, PendingSyncState>(
                // A refused or failed discard / retry is never silent.
                listenWhen: (p, c) =>
                    c.failure != null && c.failureSeq != p.failureSeq,
                listener: (context, state) => ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(
                    SnackBar(content: Text(_failureText(state.failure!))),
                  ),
                builder: (context, state) => CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  slivers: [
                    CupertinoSliverRefreshControl(onRefresh: _refresh),
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(
                        AppDims.s4,
                        0,
                        AppDims.s4,
                        bottomInset,
                      ),
                      sliver: SliverToBoxAdapter(child: _content(state)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _failureText(PendingSyncFailure f) {
    final tr = context.tr;
    return switch (f) {
      PendingSyncFailure.discardSending => tr.syOxDiscardSending,
      PendingSyncFailure.discardAlreadySynced => tr.syOxDiscardAlreadySynced,
      PendingSyncFailure.discardOtherScope => tr.syOxDiscardOtherScope,
      PendingSyncFailure.actionFailed => tr.syOxActionFailed,
    };
  }

  Widget _content(PendingSyncState state) {
    final tr = context.tr;
    final title = AppLargeTitle(title: tr.syTitle);

    if (state.isLoading || state.status == PendingSyncStatus.initial) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [title, const _HeaderSkeleton()],
      );
    }

    if (state.status == PendingSyncStatus.error) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          title,
          CategoryStateCard(
            icon: PhosphorIconsRegular.wifiSlash,
            tone: CategoryStateTone.danger,
            title: tr.somethingWentWrong,
            body: tr.nfErrorBody,
            actionLabel: tr.retry,
            secondaryAction: true,
            onAction: () =>
                context.read<PendingSyncBloc>().add(const OnPendingSyncLoad()),
          ),
        ],
      );
    }

    if (state.rows.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          title,
          CategoryStateCard(
            icon: PhosphorIconsRegular.checkCircle,
            title: tr.syAllDoneTitle,
            body: tr.syAllDoneBody,
            actionLabel: tr.close,
            secondaryAction: true,
            onAction: () => Navigator.of(context).maybePop(),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        title,
        PendingSyncOutboxView(rows: state.rows),
      ],
    );
  }
}

class _NavBar extends StatelessWidget {
  const _NavBar();

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return SizedBox(
      height: 44,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: [
            Pressable(
              onTap: () => Navigator.of(context).maybePop(),
              child: SizedBox(
                height: 44,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(width: 4),
                    DirectionalIcon(
                      icon: PhosphorIconsRegular.caretLeft,
                      size: 24,
                      color: colors.primary,
                    ),
                    Text(
                      context.tr.back,
                      style: TextStyle(fontSize: 17, color: colors.primary),
                    ),
                    const SizedBox(width: 8),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

BoxDecoration _cardDecoration(AppThemeColors colors) => BoxDecoration(
  color: colors.surface,
  borderRadius: AppDims.borderLg,
  border: Border.all(color: colors.border),
);

class _HeaderSkeleton extends StatelessWidget {
  const _HeaderSkeleton();

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return AppSkeleton(
      child: DecoratedBox(
        decoration: _cardDecoration(colors),
        child: const Padding(
          padding: EdgeInsets.fromLTRB(16, 18, 16, 16),
          child: Column(
            children: [
              Shimmer(width: 80, height: 50, radius: 10),
              SizedBox(height: 10),
              Shimmer(width: 150, height: 14, radius: 6),
              SizedBox(height: 16),
              Shimmer(width: double.infinity, height: 48, radius: 12),
            ],
          ),
        ),
      ),
    );
  }
}
