import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:amana_pos/features/pin/data/pin_hasher.dart';

void main() {
  group('PinHasher', () {
    test('generateSalt returns distinct non-empty base64 salts', () {
      final a = PinHasher.generateSalt();
      final b = PinHasher.generateSalt();
      expect(a.isNotEmpty, isTrue);
      expect(a == b, isFalse);
    });

    test('hashPin is deterministic for same pin + salt', () {
      final salt = PinHasher.generateSalt();
      expect(PinHasher.hashPin('1234', salt), PinHasher.hashPin('1234', salt));
    });

    test('hashPin differs for different pins on same salt', () {
      final salt = PinHasher.generateSalt();
      expect(
        PinHasher.hashPin('1234', salt) == PinHasher.hashPin('5678', salt),
        isFalse,
      );
    });

    test('hashPin differs for same pin on different salts', () {
      expect(
        PinHasher.hashPin('1234', PinHasher.generateSalt()) ==
            PinHasher.hashPin('1234', PinHasher.generateSalt()),
        isFalse,
      );
    });

    test('hash decodes to 32 bytes', () {
      final salt = PinHasher.generateSalt();
      final bytes = base64Decode(PinHasher.hashPin('1234', salt));
      expect(bytes.length, 32);
    });
  });
}
