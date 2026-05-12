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

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _scrollCtrl = ScrollController();
  bool _loadMoreLock = false;

  @override
  void initState() {
    super.initState();
    context.read<NotificationBloc>().add(const OnNotificationInitial(force: true));
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollCtrl.removeListener(_onScroll);
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_loadMoreLock) return;
    final state = context.read<NotificationBloc>().state;
    if (!state.hasMore) return;
    if (state.status == NotificationStatus.loadingMore) return;

    final pos = _scrollCtrl.position;
    if (pos.pixels >= pos.maxScrollExtent - 200) {
      _loadMoreLock = true;
      context.read<NotificationBloc>().add(const OnLoadMoreNotifications());
      Future.delayed(const Duration(milliseconds: 400), () {
        _loadMoreLock = false;
      });
    }
  }

  Future<void> _refresh() async {
    context.read<NotificationBloc>().add(const OnNotificationInitial(force: true));
    await Future.delayed(const Duration(milliseconds: 400));
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: colors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: Icon(
            Icons.arrow_back_rounded,
            color: context.appColors.textPrimary,
          ),
        ),
        title: Text(
          'Notifications',
          style: AppTextStyles.bs500(context).copyWith(
            fontWeight: FontWeight.w900,
            color: colors.textPrimary,
          ),
        ),
        actions: [
          BlocBuilder<NotificationBloc, NotificationState>(
            buildWhen: (prev, curr) =>
                prev.unreadCount != curr.unreadCount ||
                prev.notifications != curr.notifications,
            builder: (context, state) {
              final hasUnread = state.unreadCount > 0 ||
                  state.notifications.any((n) => !n.isRead);
              if (!hasUnread) return const SizedBox.shrink();
              return TextButton(
                onPressed: () => context
                    .read<NotificationBloc>()
                    .add(const OnMarkAllNotificationsRead()),
                child: Text(
                  'Mark all read',
                  style: AppTextStyles.bs300(context).copyWith(
                    color: colors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              );
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0.5),
          child: Divider(height: 0.5, color: colors.border),
        ),
      ),
      body: BlocBuilder<NotificationBloc, NotificationState>(
        buildWhen: (prev, curr) =>
            prev.status != curr.status ||
            prev.notifications != curr.notifications,
        builder: (context, state) {
          if (state.status == NotificationStatus.loading ||
              state.status == NotificationStatus.initial) {
            return NotificationSkeleton();
          }

          if (state.status == NotificationStatus.failure &&
              state.notifications.isEmpty) {
            return NotificationErrorView(
              message: state.error ?? 'Something went wrong',
              onRetry: () => context
                  .read<NotificationBloc>()
                  .add(const OnNotificationInitial(force: true)),
            );
          }

          if (state.notifications.isEmpty) {
            return NotificationEmptyView();
          }

          return RefreshIndicator(
            color: colors.primary,
            onRefresh: _refresh,
            child: ListView.separated(
              controller: _scrollCtrl,
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              itemCount:
                  state.notifications.length + (state.hasMore ? 1 : 0),
              separatorBuilder: (_, _) =>
                  Divider(height: 1, color: colors.border.withValues(alpha: 0.5)),
              itemBuilder: (context, i) {
                if (i >= state.notifications.length) {
                  return Padding(
                    padding: const EdgeInsets.all(AppDims.s5),
                    child: Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: colors.primary,
                        ),
                      ),
                    ),
                  );
                }

                final item = state.notifications[i];
                return NotificationTile(
                  key: ValueKey(item.id),
                  item: item,
                  onTap: () {
                    if (!item.isRead) {
                      context
                          .read<NotificationBloc>()
                          .add(OnMarkNotificationRead(item.id));
                    }
                  },
                ).animate(delay: Duration(milliseconds: i < 8 ? i * 30 : 0))
                    .fadeIn(duration: 220.ms)
                    .slideX(
                      begin: -0.03,
                      end: 0,
                      duration: 220.ms,
                      curve: Curves.easeOut,
                    );
              },
            ),
          );
        },
      ),
    );
  }
}