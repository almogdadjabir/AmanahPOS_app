import 'package:amana_pos/common/auth_bloc/auth_bloc.dart';
import 'package:amana_pos/features/inventory/presentation/basic_inventory_view.dart';
import 'package:amana_pos/features/inventory/presentation/premium/premium_inventory_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class InventoryScreen extends StatelessWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isPremium = context.select<AuthBloc, bool>(
      (b) => b.state.permissions.canUseInventoryInboundReceiving,
    );
    return isPremium ? const PremiumInventoryShell() : const BasicInventoryView();
  }
}
