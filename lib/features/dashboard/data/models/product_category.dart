import 'package:flutter/material.dart';

class ProductCategory {
  final String id;
  final String name;
  final IconData icon;
  final Color color;

  const ProductCategory({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
  });
}
