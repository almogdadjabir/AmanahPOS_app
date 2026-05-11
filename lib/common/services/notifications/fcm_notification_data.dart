import 'dart:developer';
import 'package:flutter/foundation.dart';

class FcmNotificationData {
  final String? category;
  final String? type;
  final String? level;
  final String? notificationId;

  const FcmNotificationData({
    this.category,
    this.type,
    this.level,
    this.notificationId,
  });


  const FcmNotificationData.empty()
      : category = null,
        type = null,
        level = null,
        notificationId = null;

  /// Parses from FCM [message.data]. Never throws — returns [FcmNotificationData.empty]
  factory FcmNotificationData.fromMap(Map<String, dynamic> data) {
    if (data.isEmpty) return const FcmNotificationData.empty();

    try {
      return FcmNotificationData(
        category: _safeString(data['category']),
        type: _safeString(data['type']),
        level: _safeString(data['level']),
        notificationId: _safeString(data['notificationId']),
      );
    } catch (e) {
      if (kDebugMode) log('[FcmNotificationData] parse error: $e');
      return const FcmNotificationData.empty();
    }
  }

  static String? _safeString(dynamic value) {
    final str = value?.toString().trim();
    return (str == null || str.isEmpty) ? null : str;
  }

  bool get hasCategory => category != null;
  bool get hasType => type != null;
  bool get hasLevel => level != null;
  bool get hasNotificationId => notificationId != null;

  @override
  String toString() =>
      'FcmNotificationData(category: $category, type: $type, '
          'level: $level, notificationId: $notificationId)';
}