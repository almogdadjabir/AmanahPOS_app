part of 'notification_bloc.dart';

enum NotificationStatus { initial, loading, loadingMore, success, failure }
enum NotificationUnreadCountStatus { initial, loading, loadingMore, success, failure }

class NotificationState extends Equatable {
  final NotificationStatus status;
  final NotificationUnreadCountStatus unreadCountStatus;
  final List<NotificationItem> notifications;
  final int unreadCount;
  final int currentPage;
  final bool hasMore;
  final String? error;

  const NotificationState({
    this.status = NotificationStatus.initial,
    this.unreadCountStatus = NotificationUnreadCountStatus.initial,
    this.notifications = const [],
    this.unreadCount = 0,
    this.currentPage = 0,
    this.hasMore = false,
    this.error,
  });

  factory NotificationState.initial() => const NotificationState();

  NotificationState copyWith({
    NotificationStatus? status,
    List<NotificationItem>? notifications,
    NotificationUnreadCountStatus? unreadCountStatus,
    int? unreadCount,
    int? currentPage,
    bool? hasMore,
    String? error,
    bool clearError = false,
    bool clearNotifications = false,
  }) {
    return NotificationState(
      status: status ?? this.status,
      notifications: notifications ?? this.notifications,
      unreadCount: unreadCount ?? this.unreadCount,
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
      error: clearError ? null : error ?? this.error,
      unreadCountStatus: unreadCountStatus ?? this.unreadCountStatus,
    );
  }

  @override
  List<Object?> get props => [
        status,
        notifications,
        unreadCount,
        currentPage,
        hasMore,
        error,
        unreadCountStatus,
      ];
}
