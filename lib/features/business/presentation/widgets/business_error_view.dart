import 'package:amana_pos/common/widgets/error_view.dart';
import 'package:amana_pos/features/business/presentation/bloc/business_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class BusinessErrorView extends StatelessWidget {
  final String? message;
  const BusinessErrorView({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return AppErrorView(
      message: message,
      onRetry: () => context.read<BusinessBloc>().add(OnBusinessInitial()),
    );
  }
}
