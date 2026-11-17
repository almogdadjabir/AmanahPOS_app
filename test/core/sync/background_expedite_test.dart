import 'package:amana_pos/core/sync/background/background_entry.dart';
import 'package:flutter_test/flutter_test.dart';

/// Review I3: expedited one-off work only on Android 12+ (API 31).
/// workmanager_android 0.10.9's BackgroundWorker does not implement
/// getForegroundInfoAsync(), which WorkManager calls for expedited work on
/// API < 31, so an expedited request there fails at run time.
void main() {
  Future<int?> Function() sdk(int? v) =>
      () async => v;

  test('Android 12+ (API 31, 34) is expedited', () async {
    expect(
      await BackgroundSync.shouldExpedite(isAndroid: true, sdkInt: sdk(31)),
      isTrue,
    );
    expect(
      await BackgroundSync.shouldExpedite(isAndroid: true, sdkInt: sdk(34)),
      isTrue,
    );
  });

  test('Android 11 and lower (API 30, 26) is a normal one-off', () async {
    expect(
      await BackgroundSync.shouldExpedite(isAndroid: true, sdkInt: sdk(30)),
      isFalse,
    );
    expect(
      await BackgroundSync.shouldExpedite(isAndroid: true, sdkInt: sdk(26)),
      isFalse,
    );
  });

  test('unknown SDK (null or the lookup throws) is a normal one-off', () async {
    expect(
      await BackgroundSync.shouldExpedite(isAndroid: true, sdkInt: sdk(null)),
      isFalse,
    );
    expect(
      await BackgroundSync.shouldExpedite(
        isAndroid: true,
        sdkInt: () async => throw StateError('no channel'),
      ),
      isFalse,
    );
  });

  test('iOS never asks for the SDK and is never expedited', () async {
    var asked = false;
    expect(
      await BackgroundSync.shouldExpedite(
        isAndroid: false,
        sdkInt: () async {
          asked = true;
          return 34;
        },
      ),
      isFalse,
    );
    expect(asked, isFalse);
  });
}
