class OfflineAssetRecord {
  final String id;
  final String type;
  final String url;
  final String? hash;
  final String? updatedAt;
  final String? localPath;
  final String? downloadedAt;

  const OfflineAssetRecord({
    required this.id,
    required this.type,
    required this.url,
    this.hash,
    this.updatedAt,
    this.localPath,
    this.downloadedAt,
  });

  factory OfflineAssetRecord.fromDb(Map<String, Object?> row) {
    return OfflineAssetRecord(
      id: row['id']?.toString() ?? '',
      type: row['type']?.toString() ?? '',
      url: row['url']?.toString() ?? '',
      hash: row['hash']?.toString(),
      updatedAt: row['updated_at']?.toString(),
      localPath: row['local_path']?.toString(),
      downloadedAt: row['downloaded_at']?.toString(),
    );
  }

  bool get isValid => id.isNotEmpty && type.isNotEmpty && url.isNotEmpty;
}