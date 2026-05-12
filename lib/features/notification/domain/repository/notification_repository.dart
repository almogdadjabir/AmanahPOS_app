import 'package:amana_pos/features/notification/data/models/notification_item.dart';
import 'package:amana_pos/features/notification/data/models/notifications_unread_vount_response_dto.dart' show NotificationsUnreadCountResponseDto;
import 'package:fpdart/fpdart.dart';

abstract class NotificationRepository {
  Future<Either<String?, NotificationListResponse>> getNotifications({
    required int page,
    int pageSize = 20,
  });

  Future<Either<String?, bool>> markRead(String id);

  Future<Either<String?, bool>> markAllRead();

  Future<Either<String?, NotificationsUnreadCountResponseDto>> getUnreadCount();
}
