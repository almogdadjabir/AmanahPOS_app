import 'package:amana_pos/core/api/request_handler.dart';
import 'package:amana_pos/features/notification/data/models/notification_item.dart';
import 'package:amana_pos/features/notification/data/models/notifications_unread_vount_response_dto.dart';
import 'package:amana_pos/features/notification/domain/repository/notification_repository.dart';
import 'package:fpdart/fpdart.dart';

class NotificationRepoImpl extends NotificationRepository {
  NotificationRepoImpl(this._requestHandler);
  final RequestHandler _requestHandler;

  @override
  Future<Either<String?, NotificationListResponse>> getNotifications({
    required int page,
    int pageSize = 20,
  }) {
    return _requestHandler.handleGetRequest(
      'api/v1/notifications/',
      (json) => NotificationListResponse.fromJson(json as Map<String, dynamic>),
      data: {'page': page, 'page_size': pageSize},
    );
  }

  @override
  Future<Either<String?, bool>> markRead(String id) {
    return _requestHandler.handlePatchRequest<bool>(
      'api/v1/notifications/$id/read/',
      (_) => true,
    );
  }

  @override
  Future<Either<String?, bool>> markAllRead() {
    return _requestHandler.handlePostRequest<bool>(
      'api/v1/notifications/mark-all-read/',
      (_) => true,
    );
  }

  @override
  Future<Either<String?, NotificationsUnreadCountResponseDto>> getUnreadCount() {
    return _requestHandler.handleGetRequest(
      'api/v1/notifications/unread-count/',
          (json) => NotificationsUnreadCountResponseDto.fromJson(json as Map<String, dynamic>),

    );
  }
}
