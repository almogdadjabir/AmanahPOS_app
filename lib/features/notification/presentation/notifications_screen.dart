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
  const NotificationsScreen({
    super.key,
  });

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

    context.read<NotificationBloc>().add(
      const OnLoadMoreNotifications(),
    );

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
      appBar: AppBar(
        elevation: 0,
        toolbarHeight: 88,
        backgroundColor: colors.background,
        surfaceTintColor: Colors.transparent,
        automaticallyImplyLeading: false,
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppDims.s4),
          child: Row(
            children: [
              BackButton(),
              const SizedBox(width: AppDims.s3),
              Expanded(
                child: Text(
                  'Notifications',
                  style: AppTextStyles.bs600(context).copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.7,
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          BlocBuilder<NotificationBloc, NotificationState>(
            buildWhen: (prev, curr) {
              return prev.unreadCount != curr.unreadCount ||
                  prev.notifications != curr.notifications;
            },
            builder: (context, state) {
              final hasUnread = state.unreadCount > 0 ||
                  state.notifications.any((item) => !item.isRead);

              if (!hasUnread) {
                return const SizedBox.shrink();
              }

              return Padding(
                padding: const EdgeInsets.only(right: AppDims.s2),
                child: TextButton.icon(
                  onPressed: () {
                    context.read<NotificationBloc>().add(
                      const OnMarkAllNotificationsRead(),
                    );
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: colors.primary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDims.s2,
                    ),
                    minimumSize: const Size(0, 38),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  icon: Icon(
                    SolarIconsOutline.checkCircle,
                    size: 18,
                  ),
                  label: Text(
                    'Mark all read',
                    style: AppTextStyles.bs300(context).copyWith(
                      color: colors.primary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: BlocBuilder<NotificationBloc, NotificationState>(
        buildWhen: (prev, curr) {
          return prev.status != curr.status ||
              prev.notifications != curr.notifications ||
              prev.hasMore != curr.hasMore;
        },
        builder: (context, state) {
          if (state.status == NotificationStatus.loading ||
              state.status == NotificationStatus.initial) {
            return const NotificationSkeleton();
          }

          if (state.status == NotificationStatus.failure &&
              state.notifications.isEmpty) {
            return NotificationErrorView(
              message: state.error ?? 'Something went wrong',
              onRetry: () {
                context.read<NotificationBloc>().add(
                  const OnNotificationInitial(force: true),
                );
              },
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
                AppDims.s4,
                AppDims.s4,
                120,
              ),
              itemCount: state.notifications.length + (state.hasMore ? 1 : 0),
              separatorBuilder: (_, __) => const SizedBox(height: AppDims.s3),
              itemBuilder: (context, index) {
                if (index >= state.notifications.length) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppDims.s5,
                    ),
                    child: Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.6,
                          color: colors.primary,
                        ),
                      ),
                    ),
                  );
                }

                final item = state.notifications[index];

                return NotificationTile(
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
                      item: item,
                    );
                  },
                )
                    .animate()
                    .fadeIn(
                  delay: Duration(milliseconds: 24 + (index % 6) * 18),
                  duration: 220.ms,
                )
                    .slideY(
                  begin: 0.025,
                  end: 0,
                  duration: 220.ms,
                  curve: Curves.easeOutCubic,
                );
              },
            ),
          );
        },
      ),
    );
  }
}