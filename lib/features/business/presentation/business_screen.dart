import 'package:amana_pos/features/business/presentation/bloc/business_bloc.dart';
import 'package:amana_pos/features/business/presentation/widgets/business_card_skeleton.dart';
import 'package:amana_pos/features/business/presentation/widgets/business_empty_view.dart';
import 'package:amana_pos/features/business/presentation/widgets/business_error_view.dart';
import 'package:amana_pos/features/business/presentation/widgets/single_business_workspace.dart';
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
    context.read<BusinessBloc>().add(OnBusinessInitial());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<BusinessBloc, BusinessState>(
        buildWhen: (prev, curr) =>
        prev.businessStatus != curr.businessStatus ||
            prev.businessList != curr.businessList,
        builder: (context, state) {
          return switch (state.businessStatus) {
            BusinessStatus.initial ||
            BusinessStatus.loading => const _LoadingView(),

            BusinessStatus.failure => BusinessErrorView(
              message: state.responseError,
            ),

            BusinessStatus.success => state.businessList?.isEmpty ?? true
                ? const BusinessEmptyView()
                : SingleBusinessWorkspace(data: state.businessList!.first),
          };
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