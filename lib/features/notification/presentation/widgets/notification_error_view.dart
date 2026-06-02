import 'package:amana_pos/common/widgets/error_view.dart';
import 'package:flutter/material.dart';

class NotificationErrorView extends StatelessWidget {
  final String? message;
  final VoidCallback onRetry;
  const NotificationErrorView({super.key, this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return AppErrorView(message: message, onRetry: onRetry);
  }
}
