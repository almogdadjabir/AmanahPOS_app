import 'package:amana_pos/common/widgets/products_not_found_view.dart';
import 'package:flutter/material.dart';

class ProductsEmpty extends StatelessWidget {
  final String? query;
  const ProductsEmpty({super.key, this.query});

  @override
  Widget build(BuildContext context) {
    return ProductsNotFoundView(query: query ?? '');
  }
}
