// lib/common/motion/device_memory_probe.dart
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
    } catch (_) {
      return null;
    }
  }
}
