import 'package:amana_pos/features/business/presentation/bloc/business_bloc.dart';
import 'package:amana_pos/features/business/presentation/widgets/business_card_skeleton.dart';
import 'package:amana_pos/features/business/presentation/widgets/business_empty_view.dart';
import 'package:amana_pos/features/business/presentation/widgets/business_error_view.dart';
import 'package:amana_pos/features/business/presentation/widgets/workspace/single_business_workspace.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class BusinessScreen extends StatefulWidget {
  const BusinessScreen({super.key});

  @override
  State<BusinessScreen> createState() => _BusinessScreenState();
}

class _BusinessScreenState extends State<BusinessScreen> {
  @override
  void initState() {
    super.initState();

    final state = context.read<BusinessBloc>().state;
    if (state.businessList == null || state.businessList!.isEmpty) {
      context.read<BusinessBloc>().add(OnBusinessInitial());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<BusinessBloc, BusinessState>(
        buildWhen: (prev, curr) =>
        prev.businessStatus != curr.businessStatus ||
            prev.businessList != curr.businessList ||
            prev.responseError != curr.responseError,
        builder: (context, state) {
          final businesses = state.businessList ?? [];

          if (state.businessStatus == BusinessStatus.loading ||
              state.businessStatus == BusinessStatus.initial) {
            return const _LoadingView();
          }

          if (state.businessStatus == BusinessStatus.failure) {
            return BusinessErrorView(
              message: state.responseError,
            );
          }

          if (businesses.isEmpty) {
            return const BusinessEmptyView();
          }

          return SingleBusinessWorkspace(
            data: businesses.first,
          );
        },
      ),
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(AppDims.s4),
      itemCount: 4,
      separatorBuilder: (_, _) => const SizedBox(height: AppDims.s3),
      itemBuilder: (_, _) => const BusinessCardSkeleton(),
    );
  }
}