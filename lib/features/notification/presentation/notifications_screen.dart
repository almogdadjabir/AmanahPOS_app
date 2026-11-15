import 'dart:async';

import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/features/category/presentation/widgets/category_states.dart';
import 'package:amana_pos/features/notification/data/models/notification_item.dart';
import 'package:amana_pos/features/notification/presentation/bloc/notification_bloc.dart';
import 'package:amana_pos/features/notification/presentation/notification_details_sheet.dart';
import 'package:amana_pos/features/notification/presentation/widgets/notification_skeleton.dart';
import 'package:amana_pos/features/notification/presentation/widgets/notification_tile.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/theme/phosphor_icons.dart';
import 'package:amana_pos/widgets/app_large_title.dart';
import 'package:amana_pos/widgets/directional_icon.dart';
import 'package:amana_pos/widgets/pressable.dart';
import 'package:flutter/cupertino.dart' show CupertinoSliverRefreshControl;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _scrollCtrl = ScrollController();

  bool _loadMoreLock = false;
  Timer? _loadMoreTimer;

  @override
  void initState() {
    super.initState();
    context.read<NotificationBloc>().add(
      const OnNotificationInitial(force: true),
    );
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _loadMoreTimer?.cancel();
    _scrollCtrl.removeListener(_onScroll);
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollCtrl.hasClients || _loadMoreLock) return;

    final state = context.read<NotificationBloc>().state;
    if (!state.hasMore) return;
    if (state.status == NotificationStatus.loading) return;
    if (state.status == NotificationStatus.loadingMore) return;
    if (state.notifications.isEmpty) return;

    final position = _scrollCtrl.position;
    if (position.pixels < position.maxScrollExtent - 260) return;

    _loadMoreLock = true;
    context.read<NotificationBloc>().add(const OnLoadMoreNotifications());

    _loadMoreTimer?.cancel();
    _loadMoreTimer = Timer(const Duration(milliseconds: 500), () {
      _loadMoreLock = false;
    });
  }

  Future<void> _refresh() async {
    final bloc = context.read<NotificationBloc>();
    bloc.add(const OnNotificationInitial(force: true));
    try {
      await bloc.stream
          .firstWhere(
            (s) =>
                s.status == NotificationStatus.success ||
                s.status == NotificationStatus.failure,
          )
          .timeout(const Duration(seconds: 10));
    } catch (_) {
      // Timed out: let the control settle, current data stays on screen.
    }
  }

  void _open(NotificationItem item) {
    if (!item.isRead) {
      context.read<NotificationBloc>().add(OnMarkNotificationRead(item.id));
    }
    showNotificationDetailsSheet(context, item: item);
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
              child: BlocBuilder<NotificationBloc, NotificationState>(
                buildWhen: (prev, curr) =>
                    prev.status != curr.status ||
                    prev.notifications != curr.notifications ||
                    prev.hasMore != curr.hasMore,
                builder: (context, state) => CustomScrollView(
                  controller: _scrollCtrl,
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

  Widget _content(NotificationState state) {
    final tr = context.tr;
    final colors = context.appColors;
    final title = AppLargeTitle(title: tr.nfTitle);

    final loading =
        state.status == NotificationStatus.initial ||
        state.status == NotificationStatus.loading;
    if (loading) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [title, const NotificationSkeleton()],
      );
    }

    if (state.status == NotificationStatus.failure &&
        state.notifications.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          title,
          CategoryStateCard(
            icon: PhosphorIconsRegular.wifiSlash,
            tone: CategoryStateTone.danger,
            title: tr.nfErrorTitle,
            body: tr.nfErrorBody,
            actionLabel: tr.retry,
            secondaryAction: true,
            onAction: () => context.read<NotificationBloc>().add(
              const OnNotificationInitial(force: true),
            ),
          ),
        ],
      );
    }

    if (state.notifications.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          title,
          _EmptyCard(title: tr.nfEmptyTitle, body: tr.nfEmptyBody),
        ],
      );
    }

    final now = DateTime.now();
    bool isToday(DateTime? d) {
      if (d == null) return false;
      final l = d.toLocal();
      return l.year == now.year && l.month == now.month && l.day == now.day;
    }

    final today = state.notifications.where((n) => isToday(n.createdAt));
    final earlier = state.notifications.where((n) => !isToday(n.createdAt));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        title,
        if (today.isNotEmpty) ...[
          _SectionLabel(tr.nfToday),
          _Group(items: today.toList(), onOpen: _open),
        ],
        if (earlier.isNotEmpty) ...[
          _SectionLabel(tr.nfEarlier),
          _Group(items: earlier.toList(), onOpen: _open),
        ],
        if (state.hasMore)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppDims.s5),
            child: Center(
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: colors.textHint,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _NavBar extends StatelessWidget {
  const _NavBar();

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final tr = context.tr;

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
                      tr.back,
                      style: TextStyle(fontSize: 17, color: colors.primary),
                    ),
                    const SizedBox(width: 8),
                  ],
                ),
              ),
            ),
            const Spacer(),
            BlocBuilder<NotificationBloc, NotificationState>(
              buildWhen: (p, c) =>
                  p.notifications != c.notifications ||
                  p.unreadCount != c.unreadCount,
              builder: (context, state) {
                final enabled =
                    state.unreadCount > 0 ||
                    state.notifications.any((n) => !n.isRead);
                return Pressable(
                  onTap: enabled
                      ? () {
                          HapticFeedback.selectionClick();
                          context.read<NotificationBloc>().add(
                            const OnMarkAllNotificationsRead(),
                          );
                        }
                      : null,
                  child: SizedBox(
                    height: 44,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Center(
                        child: Text(
                          tr.nfMarkAllRead,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: enabled ? colors.primary : colors.disabled,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel(this.label);

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(20, 22, 20, 7),
      child: Text(
        label,
        style: Theme.of(
          context,
        ).textTheme.labelLarge!.copyWith(color: colors.textHint),
      ),
    );
  }
}

class _Group extends StatelessWidget {
  final List<NotificationItem> items;
  final ValueChanged<NotificationItem> onOpen;

  const _Group({required this.items, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: AppDims.borderLg,
        border: Border.all(color: colors.border),
      ),
      child: ClipRRect(
        borderRadius: AppDims.borderLg,
        child: Column(
          children: [
            for (var i = 0; i < items.length; i++) ...[
              if (i > 0)
                Divider(
                  height: 0.5,
                  thickness: 0.5,
                  indent: AppDims.s4 + 40 + AppDims.s3,
                  color: colors.border,
                ),
              NotificationRow(
                key: ValueKey(items[i].id),
                item: items[i],
                onTap: () => onOpen(items[i]),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  final String title;
  final String body;

  const _EmptyCard({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final text = Theme.of(context).textTheme;

    return SizedBox(
      width: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: AppDims.borderLg,
          border: Border.all(color: colors.border),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 34, 28, 30),
          child: Column(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: colors.primaryContainer,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(
                  PhosphorIconsRegular.bell,
                  size: 30,
                  color: colors.primary,
                ),
              ),
              const SizedBox(height: AppDims.s4),
              Text(
                title,
                textAlign: TextAlign.center,
                style: text.titleLarge!.copyWith(color: colors.textPrimary),
              ),
              const SizedBox(height: 6),
              Text(
                body,
                textAlign: TextAlign.center,
                style: text.bodyMedium!.copyWith(
                  fontSize: 15,
                  height: 1.4,
                  color: colors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
