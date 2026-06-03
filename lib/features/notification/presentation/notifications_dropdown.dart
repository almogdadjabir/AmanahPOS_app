import 'dart:async';

import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/features/notification/presentation/bloc/notification_bloc.dart';
import 'package:amana_pos/features/notification/presentation/widgets/notification_empty_view.dart';
import 'package:amana_pos/features/notification/presentation/widgets/notification_error_view.dart';
import 'package:amana_pos/features/notification/presentation/widgets/notification_skeleton.dart';
import 'package:amana_pos/features/notification/presentation/widgets/notification_tile.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solar_icons/solar_icons.dart';

const double _kPanelWidth = 388.0;
const double _kPanelMaxHeight = 560.0;

/// Desktop-only notification dropdown, anchored below the bell button.
/// Wrap the bell button with [CompositedTransformTarget] and pass the same
/// [LayerLink] here to position the panel correctly.
class NotificationsDropdown extends StatefulWidget {
  final LayerLink link;
  final VoidCallback onClose;
  final NotificationBloc notificationBloc;

  const NotificationsDropdown({
    super.key,
    required this.link,
    required this.onClose,
    required this.notificationBloc,
  });

  @override
  State<NotificationsDropdown> createState() => _NotificationsDropdownState();
}

class _NotificationsDropdownState extends State<NotificationsDropdown> {
  final _scrollCtrl = ScrollController();
  bool _loadMoreLock = false;
  Timer? _loadMoreTimer;

  @override
  void initState() {
    super.initState();
    widget.notificationBloc.add(const OnNotificationInitial(force: true));
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
    final state = widget.notificationBloc.state;
    if (!state.hasMore) return;
    if (state.status == NotificationStatus.loading) return;
    if (state.status == NotificationStatus.loadingMore) return;
    if (state.notifications.isEmpty) return;

    final pos = _scrollCtrl.position;
    if (pos.pixels < pos.maxScrollExtent - 200) return;

    _loadMoreLock = true;
    widget.notificationBloc.add(const OnLoadMoreNotifications());
    _loadMoreTimer?.cancel();
    _loadMoreTimer = Timer(
      const Duration(milliseconds: 500),
      () => _loadMoreLock = false,
    );
  }

  Future<void> _refresh() async {
    widget.notificationBloc.add(const OnNotificationInitial(force: true));
    await Future<void>.delayed(const Duration(milliseconds: 400));
  }

  @override
  Widget build(BuildContext context) {
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    return Stack(
      children: [
        // ── Full-screen dismiss barrier ───────────────────────────────────
        Positioned.fill(
          child: GestureDetector(
            onTap: widget.onClose,
            behavior: HitTestBehavior.translucent,
          ),
        ),

        // ── Anchored panel ───────────────────────────────────────────────
        CompositedTransformFollower(
          link: widget.link,
          targetAnchor:
              isRtl ? Alignment.bottomLeft : Alignment.bottomRight,
          followerAnchor:
              isRtl ? Alignment.topLeft : Alignment.topRight,
          offset: const Offset(0, 8),
          child: BlocProvider.value(
            value: widget.notificationBloc,
            child: _NotificationsPanel(
              scrollCtrl: _scrollCtrl,
              onClose: widget.onClose,
              onRefresh: _refresh,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Panel shell ───────────────────────────────────────────────────────────────

class _NotificationsPanel extends StatelessWidget {
  final ScrollController scrollCtrl;
  final VoidCallback onClose;
  final Future<void> Function() onRefresh;

  const _NotificationsPanel({
    required this.scrollCtrl,
    required this.onClose,
    required this.onRefresh,
  });

  bool _isSameDay(DateTime? a, DateTime? b) {
    if (a == null || b == null) return false;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _sectionLabel(DateTime? date) {
    if (date == null) return 'Earlier';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(date.year, date.month, date.day);
    final diff = today.difference(d).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    if (diff < 7) return '$diff days ago';
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Material(
      color: Colors.transparent,
      child: SizedBox(
        width: _kPanelWidth,
        child: Container(
          constraints: const BoxConstraints(maxHeight: _kPanelMaxHeight),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: colors.border.withValues(alpha: 0.55),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: colors.shadow.withValues(alpha: 0.14),
                blurRadius: 28,
                offset: const Offset(0, 10),
              ),
              BoxShadow(
                color: colors.shadow.withValues(alpha: 0.05),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Header ──────────────────────────────────────────────
                _PanelHeader(onClose: onClose),
                Divider(
                  height: 1,
                  thickness: 1,
                  color: colors.border.withValues(alpha: 0.45),
                ),

                // ── List body ────────────────────────────────────────────
                Flexible(
                  child: BlocBuilder<NotificationBloc, NotificationState>(
                    buildWhen: (prev, curr) =>
                        prev.status != curr.status ||
                        prev.notifications != curr.notifications ||
                        prev.hasMore != curr.hasMore,
                    builder: (context, state) {
                      if (state.status == NotificationStatus.loading ||
                          state.status == NotificationStatus.initial) {
                        return const NotificationSkeleton();
                      }

                      if (state.status == NotificationStatus.failure &&
                          state.notifications.isEmpty) {
                        return NotificationErrorView(
                          message:
                              state.error ?? context.tr.somethingWentWrong,
                          onRetry: () => context
                              .read<NotificationBloc>()
                              .add(const OnNotificationInitial(force: true)),
                        );
                      }

                      if (state.notifications.isEmpty) {
                        return const NotificationEmptyView();
                      }

                      return RefreshIndicator(
                        color: colors.primary,
                        onRefresh: onRefresh,
                        child: ListView.separated(
                          controller: scrollCtrl,
                          physics: const AlwaysScrollableScrollPhysics(
                            parent: BouncingScrollPhysics(),
                          ),
                          padding: const EdgeInsets.fromLTRB(
                            AppDims.s3,
                            AppDims.s2,
                            AppDims.s3,
                            AppDims.s4,
                          ),
                          itemCount: state.notifications.length +
                              (state.hasMore ? 1 : 0),
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: AppDims.s2),
                          itemBuilder: (context, index) {
                            // Load-more spinner
                            if (index >= state.notifications.length) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                    vertical: AppDims.s3),
                                child: Center(
                                  child: SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: colors.textHint,
                                    ),
                                  ),
                                ),
                              );
                            }

                            final item = state.notifications[index];
                            final showHeader = index == 0 ||
                                !_isSameDay(
                                  state.notifications[index - 1].createdAt,
                                  item.createdAt,
                                );

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (showHeader) ...[
                                  if (index != 0)
                                    const SizedBox(height: AppDims.s2),
                                  Padding(
                                    padding: const EdgeInsets.only(
                                      left: 2,
                                      bottom: AppDims.s2,
                                      top: AppDims.s1,
                                    ),
                                    child: Text(
                                      _sectionLabel(item.createdAt),
                                      style: AppTextStyles.sm300(context)
                                          .copyWith(
                                        color: colors.textHint,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                ],
                                NotificationTile(
                                  key: ValueKey(item.id),
                                  item: item,
                                  onTap: () {
                                    if (!item.isRead) {
                                      context.read<NotificationBloc>().add(
                                            OnMarkNotificationRead(item.id),
                                          );
                                    }
                                    showNotificationDetailsSheet(
                                        context,
                                        item: item);
                                  },
                                )
                                    .animate()
                                    .fadeIn(
                                      delay: Duration(
                                          milliseconds:
                                              20 + (index % 6) * 15),
                                      duration: 190.ms,
                                    )
                                    .slideY(
                                      begin: 0.025,
                                      end: 0,
                                      duration: 190.ms,
                                      curve: Curves.easeOutCubic,
                                    ),
                              ],
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        )
            .animate()
            .fadeIn(duration: 160.ms, curve: Curves.easeOut)
            .slideY(
              begin: -0.035,
              end: 0,
              duration: 200.ms,
              curve: Curves.easeOutCubic,
            ),
      ),
    );
  }
}

// ── Panel header ──────────────────────────────────────────────────────────────

class _PanelHeader extends StatelessWidget {
  final VoidCallback onClose;

  const _PanelHeader({required this.onClose});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppDims.s4, AppDims.s3, AppDims.s3, AppDims.s3,
      ),
      child: Row(
        children: [
          // ── Title + unread badge ──────────────────────────────────────
          Text(
            context.tr.notificationsTitle,
            style: AppTextStyles.bs300(context).copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(width: 8),
          BlocBuilder<NotificationBloc, NotificationState>(
            buildWhen: (p, c) => p.unreadCount != c.unreadCount,
            builder: (context, state) {
              if (state.unreadCount == 0) return const SizedBox.shrink();
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: colors.danger.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: colors.danger.withValues(alpha: 0.20),
                    width: 0.5,
                  ),
                ),
                child: Text(
                  '${state.unreadCount}',
                  style: AppTextStyles.sm200(context).copyWith(
                    color: colors.danger,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              );
            },
          ),

          const Spacer(),

          // ── Mark all read ─────────────────────────────────────────────
          BlocBuilder<NotificationBloc, NotificationState>(
            buildWhen: (p, c) =>
                p.unreadCount != c.unreadCount ||
                p.notifications != c.notifications,
            builder: (context, state) {
              final hasUnread = state.unreadCount > 0 ||
                  state.notifications.any((n) => !n.isRead);
              if (!hasUnread) return const SizedBox.shrink();
              return GestureDetector(
                onTap: () => context
                    .read<NotificationBloc>()
                    .add(const OnMarkAllNotificationsRead()),
                child: Padding(
                  padding: const EdgeInsetsDirectional.only(end: AppDims.s2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(SolarIconsOutline.checkCircle,
                          size: 14, color: colors.primary),
                      const SizedBox(width: 4),
                      Text(
                        context.tr.markAllRead,
                        style: AppTextStyles.sm300(context).copyWith(
                          color: colors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
