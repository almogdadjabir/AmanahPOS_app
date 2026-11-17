import 'package:amana_pos/theme/app_theme_colors.dart';
import 'dart:io';

import 'package:amana_pos/core/offline/data/local_image_resolver.dart';
import 'package:amana_pos/core/sync/images/pending_image_resolver.dart';
import 'package:amana_pos/utilities/dependencies_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:amana_pos/theme/phosphor_icons.dart';

class OfflineCachedImage extends StatefulWidget {
  final String? imageUrl;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;

  /// Optional owner of the image (`product` / `category` + its id). When
  /// both are set and the entity has a staged upload (`pending_uploads`,
  /// current scope), that file is shown first, before any `synced_assets`
  /// file or the network. Without them the widget behaves as before.
  final String? entityType;
  final String? entityId;

  const OfflineCachedImage({
    super.key,
    required this.imageUrl,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
    this.entityType,
    this.entityId,
  });

  @override
  State<OfflineCachedImage> createState() => _OfflineCachedImageState();
}

/// Image source order: the staged upload of [OfflineCachedImage.entityId]
/// (Task 6; shared [PendingImageResolver], re-resolved on `pending_uploads`
/// notifies, decoded small via `cacheWidth`), then the file AssetSync
/// downloaded (`synced_assets`, by
/// url, file exists), then the network exactly as before. Resolved through
/// the ONE shared [LocalImageResolver] (one query per `synced_assets`
/// notify for all images on screen), so a thumbnail downloaded while the
/// screen is open appears without a reload. Never blocks a screen and never
/// throws (lookup errors = network).
class _OfflineCachedImageState extends State<OfflineCachedImage> {
  String? _resolvedUrl;
  LocalImageResolver? _resolver;
  ValueListenable<LocalImageLookup>? _lookup;
  PendingImageResolver? _pendingResolver;
  ValueListenable<Map<String, String>?>? _pending;

  static const ValueListenable<LocalImageLookup> _network = _ConstLookup(
    LocalImageLookup.resolved(null),
  );

  @override
  void initState() {
    super.initState();
    _subscribe(widget.imageUrl?.trim());
    _subscribePending();
  }

  String? get _entityKey {
    final type = widget.entityType;
    final id = widget.entityId;
    if (type == null || type.isEmpty || id == null || id.isEmpty) return null;
    return PendingImageResolver.keyOf(type, id);
  }

  void _subscribePending() {
    if (_entityKey == null) return;
    try {
      if (getIt.isRegistered<PendingImageResolver>()) {
        final r = getIt<PendingImageResolver>();
        _pending = r.acquire();
        _pendingResolver = r;
      }
    } catch (_) {}
  }

  void _unsubscribePending() {
    _pendingResolver?.release();
    _pendingResolver = null;
    _pending = null;
  }

  void _subscribe(String? url) {
    _resolvedUrl = url;
    _lookup = null;
    _resolver = null;
    if (url == null || url.isEmpty) return;
    try {
      if (getIt.isRegistered<LocalImageResolver>()) {
        final resolver = getIt<LocalImageResolver>();
        _lookup = resolver.acquire(url);
        _resolver = resolver;
        return;
      }
    } catch (_) {}
    _lookup = _network; // no resolver (tests, early boot): network
  }

  void _unsubscribe() {
    final url = _resolvedUrl;
    if (url != null && url.isNotEmpty) _resolver?.release(url);
    _resolver = null;
  }

  @override
  void didUpdateWidget(OfflineCachedImage oldWidget) {
    super.didUpdateWidget(oldWidget);

    final hadEntity =
        (oldWidget.entityType?.isNotEmpty ?? false) &&
        (oldWidget.entityId?.isNotEmpty ?? false);
    if (hadEntity != (_entityKey != null)) {
      setState(() {
        _unsubscribePending();
        _subscribePending();
      });
    }

    final oldUrl = oldWidget.imageUrl?.trim();
    final newUrl = widget.imageUrl?.trim();

    if (oldUrl != newUrl) {
      if (oldUrl != null && oldUrl.isNotEmpty) {
        imageCache.evict(NetworkImage(oldUrl));
      }
      if (newUrl != null && newUrl.isNotEmpty) {
        imageCache.evict(NetworkImage(newUrl));
      }
      setState(() {
        _unsubscribe();
        _subscribe(newUrl);
      });
    }
  }

  @override
  void dispose() {
    _unsubscribe();
    _unsubscribePending();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pending = _pending;
    final key = _entityKey;
    if (pending == null || key == null) return _buildFromUrl(context);
    return ValueListenableBuilder<Map<String, String>?>(
      valueListenable: pending,
      builder: (context, paths, _) {
        // T6 M4: first load still running: a placeholder, not a flash of
        // the url / error tile before the staged file appears.
        if (paths == null) {
          return widget.placeholder ?? const _DefaultImagePlaceholder();
        }
        final staged = paths[key];
        if (staged == null) return _buildFromUrl(context);
        return LayoutBuilder(
          builder: (context, constraints) {
            final dpr = MediaQuery.maybeDevicePixelRatioOf(context) ?? 2.0;
            final w = constraints.maxWidth.isFinite
                ? (constraints.maxWidth * dpr).round().clamp(1, 2048)
                : 512;
            return Image.file(
              File(staged),
              key: ValueKey(staged),
              fit: widget.fit,
              cacheWidth: w,
              errorBuilder: (_, _, _) => _buildFromUrl(context),
            );
          },
        );
      },
    );
  }

  Widget _buildFromUrl(BuildContext context) {
    final url = _resolvedUrl;
    final lookup = _lookup;

    if (url == null || url.isEmpty || lookup == null) {
      return widget.errorWidget ?? const _DefaultImageFallback();
    }

    return ValueListenableBuilder<LocalImageLookup>(
      key: ValueKey(url),
      valueListenable: lookup,
      builder: (context, value, _) {
        final localPath = value.path;

        if (localPath != null && localPath.isNotEmpty) {
          return Image.file(
            File(localPath),
            fit: widget.fit,
            errorBuilder: (_, __, ___) => _NetworkFallbackImage(
              url: url,
              fit: widget.fit,
              placeholder: widget.placeholder,
              errorWidget: widget.errorWidget,
            ),
          );
        }

        if (!value.resolved) {
          return widget.placeholder ?? const _DefaultImagePlaceholder();
        }

        return _NetworkFallbackImage(
          url: url,
          fit: widget.fit,
          placeholder: widget.placeholder,
          errorWidget: widget.errorWidget,
        );
      },
    );
  }
}

/// A lookup that never changes (no resolver registered).
class _ConstLookup implements ValueListenable<LocalImageLookup> {
  const _ConstLookup(this.value);

  @override
  final LocalImageLookup value;

  @override
  void addListener(VoidCallback listener) {}

  @override
  void removeListener(VoidCallback listener) {}
}

class _NetworkFallbackImage extends StatelessWidget {
  final String url;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;

  const _NetworkFallbackImage({
    required this.url,
    required this.fit,
    this.placeholder,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    return Image.network(
      url,
      fit: fit,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return placeholder ?? const _DefaultImagePlaceholder();
      },
      errorBuilder: (_, __, ___) {
        return errorWidget ?? const _DefaultImageFallback();
      },
    );
  }
}

class _DefaultImagePlaceholder extends StatelessWidget {
  const _DefaultImagePlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: context.appColors.surfaceSoft,
      alignment: Alignment.center,
      child: const SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }
}

class _DefaultImageFallback extends StatelessWidget {
  const _DefaultImageFallback();

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      color: colors.surfaceSoft,
      alignment: Alignment.center,
      child: Icon(
        PhosphorIconsRegular.imageBroken,
        size: 22,
        color: colors.textHint,
      ),
    );
  }
}
