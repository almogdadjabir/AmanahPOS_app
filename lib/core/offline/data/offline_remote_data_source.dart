import 'package:amana_pos/core/api/request_handler.dart';
import 'package:amana_pos/core/offline/models/offline_asset_manifest_dto.dart';
import 'package:amana_pos/core/offline/models/offline_bootstrap_dto.dart';

class OfflineRemoteDataSource {
  OfflineRemoteDataSource(this._requestHandler);

  final RequestHandler _requestHandler;

  Future<OfflineBootstrapDto> getBootstrap() async {
    final result = await _requestHandler.handleGetRequest<OfflineBootstrapDto>(
      '/api/v1/offline/bootstrap/',
      OfflineBootstrapDto.fromJson,
    );

    return result.match(
          (error) => throw Exception(error ?? 'Session expired'),
          (data) => data,
    );
  }

  Future<OfflineAssetManifestDto> getAssetManifest() async {
    final result = await _requestHandler.handleGetRequest<OfflineAssetManifestDto>(
      '/api/v1/offline/assets/manifest/',
      OfflineAssetManifestDto.fromJson,
    );

    return result.match(
          (error) => throw Exception(error ?? 'Session expired'),
          (data) => data,
    );
  }
}