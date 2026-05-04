import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

class NetworkMonitor {
  NetworkMonitor(this._connectivity);

  final Connectivity _connectivity;

  final StreamController<bool> _controller = StreamController<bool>.broadcast();

  Stream<bool> get onStatusChanged => _controller.stream;

  StreamSubscription<List<ConnectivityResult>>? _subscription;

  Future<bool> get isOnline async {
    final result = await _connectivity.checkConnectivity();
    return _hasConnection(result);
  }

  void start() {
    _subscription?.cancel();
    _subscription = _connectivity.onConnectivityChanged.listen((result) {
      _controller.add(_hasConnection(result));
    });
  }

  bool _hasConnection(List<ConnectivityResult> result) {
    return result.any((e) =>
    e == ConnectivityResult.mobile ||
        e == ConnectivityResult.wifi ||
        e == ConnectivityResult.ethernet ||
        e == ConnectivityResult.vpn);
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
    await _controller.close();
  }
}