import 'dart:developer';

import 'package:amana_pos/common/services/local/local_storage.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

/// Usage:
///   await FcmTopicService.instance.subscribeToMarketingTopics();
///   await FcmTopicService.instance.unsubscribeAll(); // on logout
class FcmTopicService {
  FcmTopicService._({required CacheStorage cacheStorage})
      : _cacheStorage = cacheStorage;

  static FcmTopicService? _instance;

  factory FcmTopicService({required CacheStorage cacheStorage}) {
    _instance ??= FcmTopicService._(cacheStorage: cacheStorage);
    return _instance!;
  }

  static FcmTopicService get instance {
    assert(_instance != null, 'Call FcmTopicService() constructor first.');
    return _instance!;
  }

  final CacheStorage _cacheStorage;
  static const String _subscribedTopicsKey = 'fcm_subscribed_topics';
  static const String topicAllUsers = 'marketing_all';
  static const String topicTest = 'marketing_test_topic';
  static const String topicAnnouncements = 'marketing_announcements';
  static const String topicPromotions = 'marketing_promotions';
  static const String topicCampaigns = 'marketing_campaigns';
  static const List<String> _defaultTopics = [
   // topicTest,  ///INFO: For testing only, Don't forget to remove on Release.
    topicAllUsers,
    topicAnnouncements,
    topicPromotions,
    topicCampaigns,
  ];


  Future<void> subscribeToMarketingTopics() async {
    for (final topic in _defaultTopics) {
      await _subscribeToTopic(topic);
    }
  }

  Future<void> unsubscribeAll() async {
    final raw = await _cacheStorage.getValue(_subscribedTopicsKey);
    if (raw == null || raw.isEmpty) return;

    final topics = raw.split(',').where((t) => t.isNotEmpty).toList();
    for (final topic in topics) {
      await _unsubscribeFromTopic(topic, updateCache: false);
    }

    await _cacheStorage.save(_subscribedTopicsKey, null);
    if (kDebugMode) log('[FcmTopicService] All topics unsubscribed.');
  }

  Future<List<String>> getSubscribedTopics() async {
    final raw = await _cacheStorage.getValue(_subscribedTopicsKey);
    if (raw == null || raw.isEmpty) return [];
    return raw.split(',').where((t) => t.isNotEmpty).toList();
  }

  Future<void> _subscribeToTopic(String topic) async {
    try {
      await FirebaseMessaging.instance.subscribeToTopic(topic);
      await _addToCache(topic);
      if (kDebugMode) log('[FcmTopicService] subscribed → $topic');
    } catch (e) {
      if (kDebugMode) log('[FcmTopicService] subscribe failed [$topic]: $e');
      // Non-fatal — app continues.
    }
  }

  Future<void> _unsubscribeFromTopic(
      String topic, {
        bool updateCache = true,
      }) async {
    try {
      await FirebaseMessaging.instance.unsubscribeFromTopic(topic);
      if (updateCache) await _removeFromCache(topic);
      if (kDebugMode) log('[FcmTopicService] unsubscribed → $topic');
    } catch (e) {
      if (kDebugMode) log('[FcmTopicService] unsubscribe failed [$topic]: $e');
    }
  }

  Future<void> _addToCache(String topic) async {
    final current = await getSubscribedTopics();
    if (current.contains(topic)) return;
    current.add(topic);
    await _cacheStorage.save(_subscribedTopicsKey, current.join(','));
  }

  Future<void> _removeFromCache(String topic) async {
    final current = await getSubscribedTopics();
    current.remove(topic);
    await _cacheStorage.save(_subscribedTopicsKey, current.join(','));
  }
}