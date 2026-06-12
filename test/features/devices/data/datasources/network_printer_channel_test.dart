import 'dart:async';
import 'dart:io';

import 'package:amana_pos/features/devices/data/datasources/network_printer_channel.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NetworkPrinterChannel against a local TCP server', () {
    late ServerSocket server;
    late NetworkPrinterChannel channel;

    setUp(() async {
      server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
      channel = NetworkPrinterChannel();
    });

    tearDown(() => server.close());

    test('connect probes reachability and reports connected', () async {
      expect(await channel.connect('127.0.0.1', server.port), isTrue);
      expect(await channel.isConnected(), isTrue);
    });

    test('writeBytes delivers the exact ESC/POS payload', () async {
      final received = Completer<List<int>>();
      server.listen((client) {
        final bytes = <int>[];
        client.listen(bytes.addAll, onDone: () {
          // The connect() reachability probe opens and closes an empty
          // connection first — only the print job carries data.
          if (bytes.isNotEmpty && !received.isCompleted) {
            received.complete(bytes);
          }
        });
      });

      await channel.connect('127.0.0.1', server.port);
      final payload = [0x1B, 0x40, 0x48, 0x65, 0x6C, 0x6C, 0x6F];

      expect(await channel.writeBytes(payload), isTrue);
      expect(await received.future.timeout(const Duration(seconds: 5)),
          payload);
    });

    test('connect to a closed port fails without throwing', () async {
      final port = server.port;
      await server.close();

      expect(await channel.connect('127.0.0.1', port), isFalse);
      expect(await channel.isConnected(), isFalse);
    });

    test('writeBytes without a configured host fails gracefully', () async {
      expect(await channel.writeBytes([0x1B, 0x40]), isFalse);
    });

    test('disconnect clears reachability state', () async {
      await channel.connect('127.0.0.1', server.port);
      await channel.disconnect();

      expect(await channel.isConnected(), isFalse);
    });
  });
}
