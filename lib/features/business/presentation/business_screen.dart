import 'package:amana_pos/features/business/presentation/bloc/business_bloc.dart';
import 'package:amana_pos/features/business/presentation/widgets/add_business_sheet.dart';
import 'package:amana_pos/features/business/presentation/widgets/business_card_skeleton.dart';
import 'package:amana_pos/features/business/presentation/widgets/business_empty_view.dart';
import 'package:amana_pos/features/business/presentation/widgets/business_error_view.dart';
import 'package:amana_pos/features/business/presentation/widgets/business_list.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
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
        buildWhen: (prev, curr) => prev.businessStatus != curr.businessStatus ||
            prev.businessList != curr.businessList,
        builder: (context, state) {
          return switch (state.businessStatus) {
            BusinessStatus.initial ||
            BusinessStatus.loading => const _LoadingView(),
            BusinessStatus.failure   => BusinessErrorView(message: state.responseError),
            BusinessStatus.success  => state.businessList?.isEmpty ?? true
                ? const BusinessEmptyView()
                : BusinessList(items: state.businessList!),
          };
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showAddBusinessSheet(context),
        backgroundColor: context.appColors.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text(
          'Add Business',
          style: TextStyle(
            fontFamily: 'NunitoSans', fontSize: 13,
            fontWeight: FontWeight.w800, color: Colors.white,
          ),
        ),
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