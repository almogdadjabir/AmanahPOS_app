part of 'notification_bloc.dart';

abstract class NotificationEvent extends Equatable {
  const NotificationEvent();
  @override
  List<Object?> get props => [];
}

class OnNotificationInitial extends NotificationEvent {
  final bool force;
  const OnNotificationInitial({this.force = false});
  @override
  List<Object?> get props => [force];
}

class OnLoadMoreNotifications extends NotificationEvent {
  const OnLoadMoreNotifications();
}

class OnMarkNotificationRead extends NotificationEvent {
  final String id;
  const OnMarkNotificationRead(this.id);
  @override
  List<Object?> get props => [id];
}

class OnMarkAllNotificationsRead extends NotificationEvent {
  const OnMarkAllNotificationsRead();
}

class OnLoadUnreadCount extends NotificationEvent {
  const OnLoadUnreadCount();
}

class OnNotificationReset extends NotificationEvent {
  const OnNotificationReset();
}
