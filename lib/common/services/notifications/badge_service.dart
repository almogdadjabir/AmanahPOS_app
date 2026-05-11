import 'package:amana_pos/common/services/local/local_storage.dart';
import 'package:flutter/services.dart';

class BadgeService {
  static const _channel = MethodChannel('app/badge');
  static final _storage = CacheStorage();
  static const _key = 'badge_count';

  /// Set badge to a specific count (from API unread count).
  static Future<void> setBadge(int count) async {
    await _storage.save( _key,  count.toString());
    try {
      await _channel.invokeMethod('setBadge', {'count': count});
    } catch (_) {}
  }

  /// Increment badge by 1 (when a new push notification arrives).
  static Future<void> incrementBadge() async {
    final current = int.tryParse(await _storage.read(_key) ?? '') ?? 0;
    await setBadge(current + 1);
  }

  /// Clear badge to 0 (when user views notifications).
  static Future<void> clearBadge() async {
    await _storage.save(_key,'0');
    try {
      await _channel.invokeMethod('clearBadge');
    } catch (_) {}
  }
}
