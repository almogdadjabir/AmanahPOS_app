class OfflineAssetManifestDto {
  final bool success;
  final String? version;
  final List<OfflineAssetDto> assets;

  const OfflineAssetManifestDto({
    required this.success,
    required this.version,
    required this.assets,
  });

  factory OfflineAssetManifestDto.fromJson(dynamic json) {
    final map = json as Map<String, dynamic>;

    return OfflineAssetManifestDto(
      success: map['success'] == true,
      version: map['version']?.toString(),
      assets: (map['assets'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(OfflineAssetDto.fromJson)
          .toList(),
    );
  }
}

class OfflineAssetDto {
  final String id;
  final String type;
  final String url;
  final String? hash;
  final String? updatedAt;

  const OfflineAssetDto({
    required this.id,
    required this.type,
    required this.url,
    required this.hash,
    required this.updatedAt,
  });

  factory OfflineAssetDto.fromJson(Map<String, dynamic> json) {
    return OfflineAssetDto(
      id: json['id']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      url: json['url']?.toString() ?? '',
      hash: json['hash']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }

  bool get isValid => id.isNotEmpty && type.isNotEmpty && url.isNotEmpty;
}