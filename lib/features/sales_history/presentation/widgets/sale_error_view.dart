import 'package:amana_pos/common/widgets/error_view.dart';
import 'package:flutter/material.dart';

class SaleErrorView extends StatelessWidget {
  final String? message;
  final VoidCallback onRetry;
  const SaleErrorView({super.key, this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return AppErrorView(message: message, onRetry: onRetry);
  }
}
