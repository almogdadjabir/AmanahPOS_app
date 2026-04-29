import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:amana_pos/config/constants.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _fastKeys = {
  Constants.appTheme,
};

class CacheStorage {
  final storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock,
      synchronizable: false,
    ),
  );

  static SharedPreferences? _staticPrefs;

  SharedPreferences? get prefs => _staticPrefs;

  static void preloadPrefs(SharedPreferences prefs) {
    _staticPrefs = prefs;
  }

  Future<void> init() async {
    _staticPrefs ??= await SharedPreferences.getInstance();
  }

  Future<void> _ensurePrefsInitialized() async {
    if (_staticPrefs == null) {
      await init();
    }
  }


  Future<String?> _prefsGet(String key) async {
    await _ensurePrefsInitialized();
    return _staticPrefs?.getString(key);
  }

  Future<void> _prefsSave(String key, String? value) async {
    await _ensurePrefsInitialized();
    if (value == null) {
      await _staticPrefs?.remove(key);
    } else {
      await _staticPrefs?.setString(key, value);
    }
  }


  Future<bool?> setBool(String key, bool value) async {
    await _ensurePrefsInitialized();
    return await _staticPrefs?.setBool(key, value);
  }

  Future<bool?> getBool(String key) async {
    await _ensurePrefsInitialized();
    return _staticPrefs?.getBool(key);
  }

  Future<bool> save(String key, String? value) async {
    try {
      if (_fastKeys.contains(key)) {
        await _prefsSave(key, value);
        return true;
      }
      if (value == null) {
        await storage.delete(key: key);
      } else {
        await storage.write(key: key, value: value);
      }
      return true;
    } catch (e) {
      if (kDebugMode) log('Error saving data: $e');
      return false;
    }
  }

  Future<String?> read(String key) async {
    try {
      if (_fastKeys.contains(key)) {
        return await _prefsGet(key);
      }
      return await storage.read(key: key);
    } catch (e) {
      if (kDebugMode) log('Error reading data: $e');
      return null;
    }
  }

  Future<String?> getValue(String key) async => await read(key);

  Future<bool> saveObject(String key, Object? value) async {
    try {
      if (value == null) {
        await storage.delete(key: key);
        return true;
      }
      final stringData = jsonEncode(value);
      await storage.write(key: key, value: stringData);
      return true;
    } catch (e) {
      if (kDebugMode) log('Error saving object to secure storage: $e');
      return false;
    }
  }

  Future<dynamic> getObject(String key) async {
    try {
      final data = await storage.read(key: key);
      if (data == null) return null;
      return jsonDecode(data);
    } catch (e) {
      if (kDebugMode) log('Error getting object from secure storage: $e');
      return null;
    }
  }

  Future<dynamic> getObjectData(String key) async => await getObject(key);

  Future<T?> getTypedObject<T>(
      String key,
      T Function(Map<String, dynamic> json) fromJson,
      ) async {
    try {
      final data = await storage.read(key: key);
      if (data == null) return null;
      final Map<String, dynamic> jsonData = jsonDecode(data);
      return fromJson(jsonData);
    } catch (e) {
      if (kDebugMode) log('Error getting typed object from secure storage: $e');
      return null;
    }
  }

  Future<bool> resetTokens() async {
    try {
      for (final key in [
        Constants.authToken,
        Constants.xTenantID,
        Constants.refreshToken,
        Constants.cachedProfile,
      ]) {
        await storage.delete(key: key);
        final check = await storage.read(key: key);
        if (check != null) await storage.delete(key: key);
      }
      return true;
    } catch (e) {
      if (kDebugMode) log('Error resetting tokens: $e');
      return false;
    }
  }

  Future<bool> deleteAllSecure() async {
    try {
      await storage.deleteAll();
      return true;
    } catch (e) {
      if (kDebugMode) log('Error deleting all secure data: $e');
      return false;
    }
  }

  Future<bool> containsKey(String key) async {
    try {
      if (_fastKeys.contains(key)) {
        await _ensurePrefsInitialized();
        return _staticPrefs?.containsKey(key) ?? false;
      }
      return await storage.containsKey(key: key);
    } catch (e) {
      if (kDebugMode) log('Error checking if key exists: $e');
      return false;
    }
  }

  Future<void> clearOnLogout() async {
    await _ensurePrefsInitialized();
  }

  Future<void> clearStaleKeychainOnFreshInstall() async {
    await _ensurePrefsInitialized();
    const String freshInstallSentinel = 'fresh_install_sentinel_v1';
    try {
      final bool isKnownInstall =
          _staticPrefs?.getBool(freshInstallSentinel) ?? false;
      if (isKnownInstall) return;

      await Future.wait([
        storage.delete(key: Constants.authToken),
        storage.delete(key: Constants.xTenantID),
        storage.delete(key: Constants.refreshToken),
        storage.delete(key: Constants.cachedProfile),
      ]);

      await _staticPrefs?.setBool(freshInstallSentinel, true);
      if (kDebugMode) {
        log('CacheStorage: Fresh install — stale Keychain data cleared.');
      }
    } catch (e) {
      if (kDebugMode) log('CacheStorage: clearStaleKeychainOnFreshInstall failed: $e');
    }
  }

  Future<bool> isKeychainAccessible() async {
    if (!Platform.isIOS) return true;
    try {
      const testKey = '__keychain_accessibility_probe__';
      await storage.write(key: testKey, value: '1');
      final probe = await storage.read(key: testKey);
      await storage.delete(key: testKey);
      return probe == '1';
    } catch (e) {
      if (kDebugMode) log('CacheStorage: Keychain not accessible yet: $e');
      return false;
    }
  }
}