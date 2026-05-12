import 'dart:async';

import 'package:amana_pos/common/services/local/local_storage.dart';
import 'package:amana_pos/features/notification/data/models/notification_item.dart';
import 'package:amana_pos/features/notification/domain/usecase/notification_usecases.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'notification_event.dart';
part 'notification_state.dart';

const _kUnreadCountKey = 'notification_unread_count';

class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  final NotificationUseCases useCases;
  final CacheStorage cacheStorage;

  NotificationBloc({
    required this.useCases,
    required this.cacheStorage,
  }) : super(NotificationState.initial()) {
    on<OnNotificationInitial>(_onInit);
    on<OnLoadMoreNotifications>(_onLoadMore);
    on<OnMarkNotificationRead>(_onMarkRead);
    on<OnMarkAllNotificationsRead>(_onMarkAllRead);
    on<OnLoadUnreadCount>(_onLoadUnreadCount);
  }


  Future<void> _onInit(
    OnNotificationInitial event,
    Emitter<NotificationState> emit,
  ) async {
    if (state.status == NotificationStatus.loading) return;
    if (!event.force &&
        state.status == NotificationStatus.success &&
        state.notifications.isNotEmpty) {
      return;
    }

    emit(state.copyWith(
      status: NotificationStatus.loading,
      clearError: true,
    ));

    final result = await useCases.getNotifications(page: 1);

    result.fold(
      (error) => emit(state.copyWith(
        status: NotificationStatus.failure,
        error: error,
      )),
      (response) {
        emit(state.copyWith(
          status: NotificationStatus.success,
          notifications: response.results,
          currentPage: 1,
          hasMore: response.hasMore,
          clearError: true,
        ));
        add(const OnLoadUnreadCount());
      },
    );
  }

  Future<void> _onLoadMore(
    OnLoadMoreNotifications event,
    Emitter<NotificationState> emit,
  ) async {
    if (!state.hasMore) return;
    if (state.status == NotificationStatus.loadingMore) return;

    emit(state.copyWith(status: NotificationStatus.loadingMore));

    final nextPage = state.currentPage + 1;
    final result = await useCases.getNotifications(page: nextPage);

    result.fold(
      (error) => emit(state.copyWith(
        status: NotificationStatus.success,
        error: error,
      )),
      (response) {
        if (!emit.isDone) {
          emit(state.copyWith(
            status: NotificationStatus.success,
            notifications: [...state.notifications, ...response.results],
            currentPage: nextPage,
            hasMore: response.hasMore,
            clearError: true,
          ));
        }
      },
    );
  }

  Future<void> _onMarkRead(
    OnMarkNotificationRead event,
    Emitter<NotificationState> emit,
  ) async {
    final wasUnread =
        state.notifications.any((n) => n.id == event.id && !n.isRead);
    if (!wasUnread) return;

    final updated = state.notifications
        .map((n) => n.id == event.id ? n.copyWith(isRead: true) : n)
        .toList();

    final newCount = (state.unreadCount - 1).clamp(0, state.unreadCount);

    emit(state.copyWith(
      notifications: updated,
      unreadCount: newCount,
    ));

    unawaited(_persistCount(newCount));

    await useCases.markRead(event.id);
  }


  Future<void> _onMarkAllRead(
    OnMarkAllNotificationsRead event,
    Emitter<NotificationState> emit,
  ) async {
    final updated =
        state.notifications.map((n) => n.copyWith(isRead: true)).toList();

    emit(state.copyWith(notifications: updated, unreadCount: 0));

    unawaited(_persistCount(0));

    await useCases.markAllRead();
  }

  Future<void> _onLoadUnreadCount(
    OnLoadUnreadCount event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      final raw = await cacheStorage.getValue(_kUnreadCountKey);
      final cached = raw != null ? int.tryParse(raw) : null;
      if (cached != null && cached != state.unreadCount && !emit.isDone) {
        emit(state.copyWith(unreadCount: cached));
      }
    } catch (_) {
    }

    final result = await useCases.getUnreadCount();
    result.fold(
      (_) {
        // Silent failure — badge stays at the cached value.
      },
      (count) async {
        if (!emit.isDone && count != state.unreadCount) {
          emit(state.copyWith(unreadCount: count.unreadCount));
        }
        unawaited(_persistCount(count.unreadCount ?? 0));
      },
    );
  }


  Future<void> _persistCount(int count) async {
    try {
      await cacheStorage.save(_kUnreadCountKey, count.toString());
    } catch (_) {}
  }
}
