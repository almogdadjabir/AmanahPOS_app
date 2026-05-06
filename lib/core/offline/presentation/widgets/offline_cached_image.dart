import 'dart:io';

import 'package:amana_pos/core/offline/data/offline_local_cache.dart';
import 'package:amana_pos/utilities/dependencies_provider.dart';
import 'package:flutter/material.dart';

class OfflineCachedImage extends StatefulWidget {
  final String? imageUrl;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;

  const OfflineCachedImage({
    super.key,
    required this.imageUrl,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
  });

  @override
  State<OfflineCachedImage> createState() => _OfflineCachedImageState();
}

class _OfflineCachedImageState extends State<OfflineCachedImage> {
  late String? _resolvedUrl;

  @override
  void initState() {
    super.initState();
    _resolvedUrl = widget.imageUrl?.trim();
  }

  @override
  void didUpdateWidget(OfflineCachedImage oldWidget) {
    super.didUpdateWidget(oldWidget);

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
        _resolvedUrl = newUrl;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final url = _resolvedUrl;

    if (url == null || url.isEmpty) {
      return widget.errorWidget ?? const _DefaultImageFallback();
    }

    return FutureBuilder<String?>(
      key: ValueKey(url),
      future: getIt<OfflineLocalCache>().getLocalAssetPathByUrl(url),
      builder: (context, snapshot) {
        final localPath = snapshot.data;

        if (localPath != null && localPath.isNotEmpty) {
          return Image.file(
            File(localPath),
            fit: widget.fit,
            errorBuilder: (_, _,_) {
              return _NetworkFallbackImage(
                url: url,
                fit: widget.fit,
                placeholder: widget.placeholder,
                errorWidget: widget.errorWidget,
              );
            },
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
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
      color: const Color(0xFFE5E7EB),
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
    return Container(
      color: const Color(0xFFF3F4F6),
      alignment: Alignment.center,
      child: const Icon(
        Icons.image_not_supported_outlined,
        size: 22,
        color: Color(0xFF9CA3AF),
      ),
    );
  }
}