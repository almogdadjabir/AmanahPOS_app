import 'dart:developer';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class DeviceInfoData {
  final String deviceId;
  final String appVersion;
  final String buildNumber;
  final String platform;

  const DeviceInfoData({
    required this.deviceId,
    required this.appVersion,
    required this.buildNumber,
    required this.platform,
  });

  factory DeviceInfoData.fromMap(Map<dynamic, dynamic> map) {
    return DeviceInfoData(
      deviceId: map['deviceId']?.toString() ?? '',
      appVersion: map['appVersion']?.toString() ?? '',
      buildNumber: map['buildNumber']?.toString() ?? '',
      platform: map['platform']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'deviceId': deviceId,
      'appVersion': appVersion,
      'buildNumber': buildNumber,
      'platform': platform,
    };
  }

  @override
  String toString() {
    return 'DeviceInfoData(deviceId: $deviceId, appVersion: $appVersion, buildNumber: $buildNumber, platform: $platform)';
  }
}

class DeviceInfoService {
  DeviceInfoService._();

  static final DeviceInfoService instance = DeviceInfoService._();

  static const MethodChannel _channel = MethodChannel('amana_pos/device_info');

  DeviceInfoData? _cachedDeviceInfo;

  Future<DeviceInfoData> getDeviceInfo({
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && _cachedDeviceInfo != null) {
      return _cachedDeviceInfo!;
    }

    try {
      final result = await _channel.invokeMethod<Map<dynamic, dynamic>>(
        'getDeviceMeta',
      );

      if (result == null) {
        return _fallback();
      }

      final data = DeviceInfoData.fromMap(result);
      _cachedDeviceInfo = data;
      return data;
    } catch (e, s) {
      if (kDebugMode) {
        log('[DeviceInfoService] getDeviceInfo failed: $e');
        log('$s');
      }
      return _fallback();
    }
  }

  Future<String> getDeviceId() async {
    try {
      final value = await _channel.invokeMethod<String>('getDeviceId');
      return value ?? '';
    } catch (e) {
      if (kDebugMode) {
        log('[DeviceInfoService] getDeviceId failed: $e');
      }
      return '';
    }
  }

  Future<String> getAppVersion() async {
    try {
      final value = await _channel.invokeMethod<String>('getAppVersion');
      return value ?? '';
    } catch (e) {
      if (kDebugMode) {
        log('[DeviceInfoService] getAppVersion failed: $e');
      }
      return '';
    }
  }

  Future<String> getBuildNumber() async {
    try {
      final value = await _channel.invokeMethod<String>('getBuildNumber');
      return value ?? '';
    } catch (e) {
      if (kDebugMode) {
        log('[DeviceInfoService] getBuildNumber failed: $e');
      }
      return '';
    }
  }

  DeviceInfoData _fallback() {
    return DeviceInfoData(
      deviceId: '',
      appVersion: '',
      buildNumber: '',
      platform: Platform.operatingSystem,
    );
  }
}