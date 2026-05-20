import 'dart:async';

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
    if (!_scrollCtrl.hasClients) return;
    if (_loadMoreLock) return;

    final state = context.read<NotificationBloc>().state;

    if (!state.hasMore) return;
    if (state.status == NotificationStatus.loading) return;
    if (state.status == NotificationStatus.loadingMore) return;
    if (state.notifications.isEmpty) return;

    final position = _scrollCtrl.position;
    final shouldLoadMore = position.pixels >= position.maxScrollExtent - 260;

    if (!shouldLoadMore) return;

    _loadMoreLock = true;
    context.read<NotificationBloc>().add(const OnLoadMoreNotifications());

    _loadMoreTimer?.cancel();
    _loadMoreTimer = Timer(const Duration(milliseconds: 500), () {
      _loadMoreLock = false;
    });
  }

  Future<void> _refresh() async {
    context.read<NotificationBloc>().add(
      const OnNotificationInitial(force: true),
    );
    await Future<void>.delayed(const Duration(milliseconds: 400));
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: _buildAppBar(context, colors),
      body: BlocBuilder<NotificationBloc, NotificationState>(
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
              message: state.error ?? 'Something went wrong',
              onRetry: () => context.read<NotificationBloc>().add(
                const OnNotificationInitial(force: true),
              ),
            );
          }

          if (state.notifications.isEmpty) {
            return const NotificationEmptyView();
          }

          return RefreshIndicator(
            color: colors.primary,
            onRefresh: _refresh,
            child: ListView.separated(
              controller: _scrollCtrl,
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: const EdgeInsets.fromLTRB(
                AppDims.s4,
                AppDims.s3,
                AppDims.s4,
                120,
              ),
              itemCount:
              state.notifications.length + (state.hasMore ? 1 : 0),
              separatorBuilder: (_, __) =>
              const SizedBox(height: AppDims.s2),
              itemBuilder: (context, index) {
                // Load-more spinner
                if (index >= state.notifications.length) {
                  return Padding(
                    padding:
                    const EdgeInsets.symmetric(vertical: AppDims.s5),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: colors.textHint,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Loading more',
                          style: AppTextStyles.bs200(context).copyWith(
                            color: colors.textHint,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final item = state.notifications[index];

                // Section date header
                final showHeader = index == 0 ||
                    !_isSameDay(
                      state.notifications[index - 1].createdAt,
                      item.createdAt,
                    );

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (showHeader) ...[
                      if (index != 0) const SizedBox(height: AppDims.s2),
                      Padding(
                        padding: const EdgeInsets.only(
                          left: 2,
                          bottom: AppDims.s2,
                          top: AppDims.s1,
                        ),
                        child: Text(
                          _sectionLabel(item.createdAt),
                          style: AppTextStyles.bs100(context).copyWith(
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
                        showNotificationDetailsSheet(context, item: item);
                      },
                    )
                        .animate()
                        .fadeIn(
                      delay: Duration(
                          milliseconds: 24 + (index % 6) * 18),
                      duration: 220.ms,
                    )
                        .slideY(
                      begin: 0.025,
                      end: 0,
                      duration: 220.ms,
                      curve: Curves.easeOutCubic,
                    ),
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(
      BuildContext context, AppThemeColors colors) {
    return AppBar(
      elevation: 0,
      toolbarHeight: 64,
      backgroundColor: colors.background,
      surfaceTintColor: Colors.transparent,
      automaticallyImplyLeading: false,
      titleSpacing: 0,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(0.5),
        child: Divider(
          height: 0.5,
          thickness: 0.5,
          color: colors.border.withValues(alpha: 0.6),
        ),
      ),
      title: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppDims.s4),
        child: Row(
          children: [
            // Back button — pill style
            Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              child: InkWell(
                onTap: () => Navigator.of(context).pop(),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: colors.border.withValues(alpha: 0.6),
                      width: 0.5,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    SolarIconsOutline.altArrowLeft,
                    size: 18,
                    color: colors.textPrimary,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppDims.s3),

            // Title + unread chip
            Expanded(
              child: Row(
                children: [
                  Text(
                    'Notifications',
                    style: AppTextStyles.bs500(context).copyWith(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(width: 8),
                  BlocBuilder<NotificationBloc, NotificationState>(
                    buildWhen: (prev, curr) =>
                    prev.unreadCount != curr.unreadCount,
                    builder: (context, state) {
                      if (state.unreadCount == 0) {
                        return const SizedBox.shrink();
                      }
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: colors.danger.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: colors.danger.withValues(alpha: 0.20),
                            width: 0.5,
                          ),
                        ),
                        child: Text(
                          '${state.unreadCount} new',
                          style: AppTextStyles.bs100(context).copyWith(
                            color: colors.danger,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            // Mark all read — only when there are unread items
            BlocBuilder<NotificationBloc, NotificationState>(
              buildWhen: (prev, curr) =>
              prev.unreadCount != curr.unreadCount ||
                  prev.notifications != curr.notifications,
              builder: (context, state) {
                final hasUnread = state.unreadCount > 0 ||
                    state.notifications.any((item) => !item.isRead);

                if (!hasUnread) return const SizedBox.shrink();

                return GestureDetector(
                  onTap: () => context.read<NotificationBloc>().add(
                    const OnMarkAllNotificationsRead(),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        SolarIconsOutline.checkCircle,
                        size: 16,
                        color: colors.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Mark all read',
                        style: AppTextStyles.bs200(context).copyWith(
                          color: colors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

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
    if (diff < 7) return '${diff} days ago';
    return '${date.day}/${date.month}/${date.year}';
  }
}