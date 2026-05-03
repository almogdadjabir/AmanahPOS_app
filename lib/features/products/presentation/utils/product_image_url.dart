import 'package:amana_pos/features/products/data/model/response/category_products_response_dto.dart';

extension ProductImageUrlX on ProductData {
  String? get listImageUrl {
    final thumbnail = thumbnailUrl?.trim();
    if (thumbnail != null && thumbnail.isNotEmpty) return thumbnail;

    final fullImage = image?.trim();
    if (fullImage != null && fullImage.isNotEmpty) return fullImage;

    return null;
  }

  String? get detailImageUrl {
    final fullImage = image?.trim();
    if (fullImage != null && fullImage.isNotEmpty) return fullImage;

    final thumbnail = thumbnailUrl?.trim();
    if (thumbnail != null && thumbnail.isNotEmpty) return thumbnail;

    return null;
  }
}