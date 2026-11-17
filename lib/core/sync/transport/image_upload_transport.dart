/// Catalog image upload (BE `PUT /products/<id>/image/` and
/// `PUT /products/categories/<id>/image/`, multipart field `image`).
///
/// A sibling of `SyncTransport` (not a member of it) so the many
/// `SyncTransport` test doubles need no change. The real implementation
/// (Task 6) sends the `X-Content-SHA256` and `Idempotency-Key` headers, both
/// set to the sha256; the server answers the same result for the same bytes, so a
/// retry after a lost response is a no-op (`unchanged: true`).
///
/// Errors are [SyncTransportException]s (see `sync_transport.dart`):
/// network/timeout/5xx as for push; HTTP 400 `code: hash_mismatch` (bytes do
/// not match the hash), 403 `forbidden` (not manager+), 404 `not_found`
/// (row unknown to the server), 413 `too_large`; 401 kinds as everywhere.
abstract class ImageUploadTransport {
  /// [entity] is `product` or `category`; [sha256] is the lowercase hex
  /// sha256 of [bytes] (the value the feed later returns as `image_hash`).
  Future<ImageUploadResult> putImage({
    required String entity,
    required String entityId,
    required List<int> bytes,
    required String sha256,
    required String scope,
  });
}

/// `data` of the image PUT response.
class ImageUploadResult {
  const ImageUploadResult({
    required this.entityId,
    required this.imageHash,
    this.image,
    this.thumbnailUrl,
    this.version,
    this.imageBytes,
    this.thumbnailBytes,
    this.unchanged = false,
  });

  /// Parses the BE `data` object (`id`, `image`, `thumbnail_url`,
  /// `image_hash`, `image_bytes`, `thumbnail_bytes`, `version`, `unchanged`).
  factory ImageUploadResult.fromJson(Map<String, dynamic> j) =>
      ImageUploadResult(
        entityId: '${j['id']}',
        imageHash: (j['image_hash'] as String?) ?? '',
        image: j['image'] as String?,
        thumbnailUrl: j['thumbnail_url'] as String?,
        version: j['version'] is int ? j['version'] as int : null,
        imageBytes: j['image_bytes'] is int ? j['image_bytes'] as int : null,
        thumbnailBytes: j['thumbnail_bytes'] is int
            ? j['thumbnail_bytes'] as int
            : null,
        unchanged: j['unchanged'] == true,
      );

  final String entityId;

  /// sha256 of the uploaded bytes (= the feed `image_hash` change token).
  final String imageHash;
  final String? image;
  final String? thumbnailUrl;

  /// Row version after the upload (adopt it as the local `version`).
  final int? version;
  final int? imageBytes;
  final int? thumbnailBytes;

  /// The same bytes were already stored: nothing changed on the server.
  final bool unchanged;
}

/// Content type of an image by its magic bytes (`image/jpeg`, `image/png`,
/// `image/webp`, `image/gif`, `image/heic`), else
/// `application/octet-stream` (the BE sniffs the bytes itself anyway).
String sniffImageMime(List<int> b) {
  bool at(int off, List<int> sig) {
    if (b.length < off + sig.length) return false;
    for (var i = 0; i < sig.length; i++) {
      if (b[off + i] != sig[i]) return false;
    }
    return true;
  }

  if (at(0, const [0xFF, 0xD8, 0xFF])) return 'image/jpeg';
  if (at(0, const [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A])) {
    return 'image/png';
  }
  if (at(0, 'RIFF'.codeUnits) && at(8, 'WEBP'.codeUnits)) return 'image/webp';
  if (at(0, 'GIF87a'.codeUnits) || at(0, 'GIF89a'.codeUnits)) {
    return 'image/gif';
  }
  if (at(4, 'ftypheic'.codeUnits) || at(4, 'ftypheix'.codeUnits) ||
      at(4, 'ftypmif1'.codeUnits)) {
    return 'image/heic';
  }
  return 'application/octet-stream';
}
