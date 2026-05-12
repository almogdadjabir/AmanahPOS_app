import 'package:amana_pos/features/notification/data/models/notification_item.dart';
import 'package:amana_pos/features/notification/data/models/notifications_unread_vount_response_dto.dart';
import 'package:amana_pos/features/notification/domain/repository/notification_repository.dart';
import 'package:fpdart/fpdart.dart';

class NotificationUseCases {
  const NotificationUseCases({required this.repository});
  final NotificationRepository repository;

  Future<Either<String?, NotificationListResponse>> getNotifications({
    required int page,
    int pageSize = 20,
  }) =>
      repository.getNotifications(page: page, pageSize: pageSize);

  Future<Either<String?, bool>> markRead(String id) =>
      repository.markRead(id);

  Future<Either<String?, bool>> markAllRead() =>
      repository.markAllRead();

  Future<Either<String?, NotificationsUnreadCountResponseDto>> getUnreadCount() =>
      repository.getUnreadCount();
}
