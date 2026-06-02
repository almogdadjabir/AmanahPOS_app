import 'package:amana_pos/common/widgets/error_view.dart';
import 'package:amana_pos/features/inventory/presentation/bloc/inventory_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class InventoryErrorView extends StatelessWidget {
  final String? message;
  const InventoryErrorView({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return AppErrorView(
      message: message,
      onRetry: () =>
          context.read<InventoryBloc>().add(const OnInventoryInitial()),
    );
  }
}
