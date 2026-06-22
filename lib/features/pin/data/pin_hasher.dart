import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

/// PBKDF2-HMAC-SHA256 PIN hashing. dkLen = 32 (== SHA-256 output) so exactly
/// one PBKDF2 block is required.
class PinHasher {
  static const int _iterations = 100000;
  static const int _saltBytes = 16;
  static final Random _rng = Random.secure();

  static String generateSalt() {
    final bytes = Uint8List(_saltBytes);
    for (var i = 0; i < _saltBytes; i++) {
      bytes[i] = _rng.nextInt(256);
    }
    return base64Encode(bytes);
  }

  static String hashPin(String pin, String saltBase64) {
    final salt = base64Decode(saltBase64);
    final hmac = Hmac(sha256, utf8.encode(pin));

    // PBKDF2 block index 1: INT(1) big-endian appended to salt.
    final block = Uint8List(salt.length + 4)
      ..setRange(0, salt.length, salt)
      ..[salt.length + 3] = 1;

    var u = Uint8List.fromList(hmac.convert(block).bytes);
    final result = Uint8List.fromList(u);

    for (var i = 1; i < _iterations; i++) {
      u = Uint8List.fromList(hmac.convert(u).bytes);
      for (var j = 0; j < result.length; j++) {
        result[j] ^= u[j];
      }
    }
    return base64Encode(result);
  }
}
