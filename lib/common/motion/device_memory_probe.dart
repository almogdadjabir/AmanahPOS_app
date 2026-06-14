import 'package:system_info_plus/system_info_plus.dart';

/// Reports total physical RAM. Abstracted so it can be mocked in tests.
abstract class DeviceMemoryProbe {
  /// Total physical memory in megabytes, or null if it cannot be determined.
  Future<int?> totalMemoryMb();
}

class SystemMemoryProbe implements DeviceMemoryProbe {
  const SystemMemoryProbe();

  @override
  Future<int?> totalMemoryMb() async {
    try {
      // system_info_plus returns physical memory in MB.
      return await SystemInfoPlus.physicalMemory;
    // PlatformException / MissingPluginException both map to null so the
    // resolver falls back to the safe default (animations on).
    } catch (_) {
      return null;
    }
  }
}
