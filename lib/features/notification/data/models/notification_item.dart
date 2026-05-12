import 'package:equatable/equatable.dart';

const kNotificationTypes = {
  'info', 'success', 'warning', 'error',
  'sale', 'stock', 'subscription', 'security', 'system',
};

class NotificationItem extends Equatable {
  final String id;
  final String? title;
  final String? body;
  final String type;
  final bool isRead;
  final DateTime? createdAt;

  const NotificationItem({
    required this.id,
    this.title,
    this.body,
    required this.type,
    required this.isRead,
    this.createdAt,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString(),
      body: (json['body'] ?? json['message'])?.toString(),
      type: json['type']?.toString() ?? 'info',
      isRead: json['is_read'] as bool? ?? json['read'] as bool? ?? false,
      createdAt: _parseDate(json['created_at'] ?? json['createdAt']),
    );
  }

  NotificationItem copyWith({bool? isRead}) {
    return NotificationItem(
      id: id,
      title: title,
      body: body,
      type: type,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
    );
  }

  static DateTime? _parseDate(dynamic raw) {
    if (raw == null) return null;
    return DateTime.tryParse(raw.toString());
  }

  @override
  List<Object?> get props => [id, title, body, type, isRead, createdAt];
}


class NotificationListResponse {
  final int count;
  final String? next;
  final List<NotificationItem> results;

  const NotificationListResponse({
    required this.count,
    this.next,
    required this.results,
  });

  factory NotificationListResponse.fromJson(Map<String, dynamic> json) {
    return NotificationListResponse(
      count: json['count'] as int? ?? 0,
      next: json['next']?.toString(),
      results: (json['results'] as List<dynamic>? ?? [])
          .map((e) => NotificationItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  bool get hasMore => next != null && next!.isNotEmpty;
}
