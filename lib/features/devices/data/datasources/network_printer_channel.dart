import 'dart:async';
import 'dart:io';

/// ESC/POS RAW printing over TCP (JetDirect port 9100) for LAN/WiFi
/// receipt printers such as the SAM4s GIANT-100.
///
/// Network printers are connectionless per job: [connect] is a reachability
/// probe for UX status, and [writeBytes] opens a fresh socket per print so a
/// dropped link never leaves stale state behind.
class NetworkPrinterChannel {
  static const Duration _connectTimeout = Duration(seconds: 4);
  static const Duration _drainDelay = Duration(milliseconds: 300);

  String? _host;
  int? _port;
  bool _reachable = false;

  Future<bool> connect(String host, int port) async {
    _host = host;
    _port = port;
    _reachable = false;

    try {
      final socket = await Socket.connect(host, port, timeout: _connectTimeout);
      socket.destroy();
      _reachable = true;
      return true;
    } on SocketException {
      return false;
    } on TimeoutException {
      return false;
    }
  }

  Future<bool> isConnected() async => _reachable;

  Future<void> disconnect() async {
    _reachable = false;
  }

  Future<bool> writeBytes(List<int> bytes) async {
    final host = _host;
    final port = _port;
    if (host == null || port == null) return false;

    Socket? socket;
    try {
      socket = await Socket.connect(host, port, timeout: _connectTimeout);
      socket.add(bytes);
      await socket.flush();
      // Give the printer a moment to drain the TCP buffer before the
      // socket closes — some firmwares drop the tail of the job otherwise.
      await Future<void>.delayed(_drainDelay);
      return true;
    } on SocketException {
      _reachable = false;
      return false;
    } on TimeoutException {
      _reachable = false;
      return false;
    } finally {
      socket?.destroy();
    }
  }
}
