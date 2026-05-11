import 'dart:async';
import 'dart:developer';
import 'package:amana_pos/common/services/local/local_storage.dart';
import 'package:amana_pos/core/api/request_handler.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';


class FcmTokenService {
  final CacheStorage _cacheStorage;
  final RequestHandler _requestHandler;

  static const String _fcmTokenKey = 'fcm_token';
  static const String _fcmTokenTimestampKey = 'fcm_token_timestamp';
  static const String _fcmTokenSyncedKey = 'fcm_token_synced';
  static const int _maxRetries = 3;
  static const Duration _retryDelay = Duration(seconds: 5);

  String? _cachedToken;
  bool _isInitialized = false;
  StreamSubscription<String>? _tokenRefreshSubscription;

  FcmTokenService({
    required CacheStorage cacheStorage,
    required RequestHandler requestHandler,
  })  : _cacheStorage = cacheStorage,
        _requestHandler = requestHandler;


  Future<void> initialize() async {
    if (_isInitialized) {
      if (kDebugMode) {
        log('FCM Token Service already initialized');
      }
      return;
    }

    try {
      final token = await _getTokenWithRetry();
      if (token != null) {
        await _saveToken(token);
        _cachedToken = token;

        // Sync with backend if not synced
        final isSynced = await _isTokenSynced();
        if (!isSynced) {
          await _syncTokenToBackend(token);
        }

        if (kDebugMode) {
          log('FCM Token initialized: $token');
        }
      }

      _tokenRefreshSubscription = FirebaseMessaging.instance.onTokenRefresh.listen(
        _handleTokenRefresh,
        onError: (error) {
          if (kDebugMode) {
            log('FCM Token refresh error: $error');
          }
        },
      );

      _isInitialized = true;
    } catch (e) {
      if (kDebugMode) {
        log('Failed to initialize FCM token: $e');
      }
      // Don't throw - allow app to continue
    }
  }

  /// Get token with retry logic for network issues
  Future<String?> _getTokenWithRetry() async {
    for (int attempt = 0; attempt < _maxRetries; attempt++) {
      try {
        // On iOS, wait for APNs token first
        if (defaultTargetPlatform == TargetPlatform.iOS) {
          final apnsToken = await FirebaseMessaging.instance.getAPNSToken()
              .timeout(const Duration(seconds: 10));

          if (apnsToken == null) {
            if (kDebugMode) {
              log('APNs token not ready yet, attempt ${attempt + 1}');
            }
            if (attempt < _maxRetries - 1) {
              await Future.delayed(_retryDelay);
            }
            continue; // skip to next retry
          }

          if (kDebugMode) {
            log('APNs token ready: ${apnsToken.substring(0, 10)}...');
          }
        }

        final token = await FirebaseMessaging.instance.getToken()
            .timeout(const Duration(seconds: 10));
        if (token != null) return token;

      } catch (e) {
        if (kDebugMode) {
          log('FCM Token fetch attempt ${attempt + 1} failed: $e');
        }
        if (attempt < _maxRetries - 1) {
          await Future.delayed(_retryDelay);
        }
      }
    }
    return null;
  }

  /// Handle token refresh event
  Future<void> _handleTokenRefresh(String newToken) async {
    if (kDebugMode) {
      log('FCM Token refreshed: ${newToken.substring(0, 20)}...');
    }

    await _saveToken(newToken);
    _cachedToken = newToken;
    await _syncTokenToBackend(newToken);
  }

  /// Save token to cache with timestamp and validation
  Future<void> _saveToken(String token) async {
    if (token.isEmpty || token.length < 20) {
      if (kDebugMode) {
        log('Invalid FCM token, not saving');
      }
      return;
    }

    try {
      final currentToken = await _cacheStorage.getValue(_fcmTokenKey);

      if (currentToken != token) {
        await _cacheStorage.save(_fcmTokenKey, token);
        await _cacheStorage.save(
          _fcmTokenTimestampKey,
          DateTime.now().millisecondsSinceEpoch.toString(),
        );
        await _cacheStorage.setBool(_fcmTokenSyncedKey, false);

        if (kDebugMode) {
          log('FCM Token saved to cache');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        log('Failed to save FCM token: $e');
      }
      // Don't throw - continue operation
    }
  }

  /// Get cached token with validation
  Future<String?> getToken() async {
    if (_cachedToken != null && _cachedToken!.isNotEmpty) {
      return _cachedToken;
    }

    try {
      final token = await _cacheStorage.getValue(_fcmTokenKey);
      if (token != null && token.isNotEmpty && token.length > 20) {
        _cachedToken = token;
        return token;
      }
    } catch (e) {
      if (kDebugMode) {
        log('Failed to get cached FCM token: $e');
      }
    }

    // Fallback: Try to get fresh token
    try {
      final freshToken = await _getTokenWithRetry();
      if (freshToken != null) {
        await _saveToken(freshToken);
        _cachedToken = freshToken;
        return freshToken;
      }
    } catch (e) {
      if (kDebugMode) {
        log('Failed to get fresh FCM token: $e');
      }
    }

    return null;
  }

  /// Check if token is synced with backend
  Future<bool> _isTokenSynced() async {
    try {
      final synced = await _cacheStorage.getBool(_fcmTokenSyncedKey);
      return synced ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Sync token to backend with retry logic
  Future<bool> _syncTokenToBackend(String token) async {
    // for (int attempt = 0; attempt < _maxRetries; attempt++) {
    //   try {
    //     final response = await _requestHandler.handlePostRequest(
    //       'api/user-device/update-fcm-token',
    //           (data) => true,
    //       data: {'fcmToken': token},
    //     ).timeout(const Duration(seconds: 15));
    //
    //     return response.fold(
    //           (error) {
    //         if (kDebugMode) {
    //           // log('Failed to sync FCM token (attempt ${attempt + 1}): $error');
    //           log('Failed to sync FCM token: $error');
    //         }
    //         return false;
    //       },
    //           (success) async {
    //         await _cacheStorage.setBool(_fcmTokenSyncedKey, true);
    //         if (kDebugMode) {
    //           log('FCM Token synced to backend successfully');
    //         }
    //         return true;
    //       },
    //     );
    //   } catch (e) {
    //     if (kDebugMode) {
    //       // log('FCM Token sync attempt ${attempt + 1} failed: $e');
    //       log('FCM Token sync failed: $e');
    //     }
    //     // if (attempt < _maxRetries - 1) {
    //     //   await Future.delayed(_retryDelay * (attempt + 1));
    //     // }
    //   }
    // // }
    return false;
  }

  /// Get token timestamp
  Future<DateTime?> getTokenTimestamp() async {
    try {
      final timestampStr = await _cacheStorage.getValue(_fcmTokenTimestampKey);
      if (timestampStr != null) {
        final timestamp = int.tryParse(timestampStr);
        if (timestamp != null) {
          return DateTime.fromMillisecondsSinceEpoch(timestamp);
        }
      }
    } catch (e) {
      if (kDebugMode) {
        log('Failed to get token timestamp: $e');
      }
    }
    return null;
  }

  /// Check if token needs refresh (older than 60 days for production)
  Future<bool> shouldRefreshToken() async {
    final timestamp = await getTokenTimestamp();
    if (timestamp == null) return true;

    final daysSinceUpdate = DateTime.now().difference(timestamp).inDays;
    return daysSinceUpdate > 60;
  }

  /// Force token refresh - use sparingly
  Future<String?> refreshToken() async {
    try {
      await FirebaseMessaging.instance.deleteToken();

      await Future.delayed(const Duration(seconds: 2));

      final newToken = await _getTokenWithRetry();
      if (newToken != null) {
        await _saveToken(newToken);
        _cachedToken = newToken;
        await _syncTokenToBackend(newToken);

        if (kDebugMode) {
          log('FCM Token force refreshed');
        }
        return newToken;
      }
    } catch (e) {
      if (kDebugMode) {
        log('Failed to refresh FCM token: $e');
      }
    }
    return null;
  }

  /// Clear cached token - call on logout
  Future<void> clearToken() async {
    try {
      await _cacheStorage.save(_fcmTokenKey, null);
      await _cacheStorage.save(_fcmTokenTimestampKey, null);
      await _cacheStorage.save(_fcmTokenSyncedKey, null);
      _cachedToken = null;

      if (kDebugMode) {
        log('FCM Token cleared from cache');
      }
    } catch (e) {
      if (kDebugMode) {
        log('Failed to clear FCM token: $e');
      }
    }
  }

  /// Get token info for debugging/monitoring
  Future<Map<String, dynamic>> getTokenInfo() async {
    final token = await getToken();
    final timestamp = await getTokenTimestamp();
    final shouldRefresh = await shouldRefreshToken();
    final isSynced = await _isTokenSynced();

    return {
      'hasToken': token != null,
      'tokenLength': token?.length ?? 0,
      'timestamp': timestamp?.toIso8601String(),
      'shouldRefresh': shouldRefresh,
      'daysSinceUpdate': timestamp != null
          ? DateTime.now().difference(timestamp).inDays
          : null,
      'isSynced': isSynced,
      'isInitialized': _isInitialized,
    };
  }

  Future<void> dispose() async {
    await _tokenRefreshSubscription?.cancel();
    _tokenRefreshSubscription = null;
    _isInitialized = false;
  }
}