import 'package:amana_pos/features/business/data/models/responses/business_response_dto.dart';
import 'package:amana_pos/features/business/presentation/bloc/business_bloc.dart';
import 'package:amana_pos/features/business/presentation/widgets/detail_app_bar.dart';
import 'package:amana_pos/features/business/presentation/widgets/info_section.dart';
import 'package:amana_pos/features/business/presentation/widgets/shops_section.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class BusinessDetailScreen extends StatelessWidget {
  final BusinessData business;
  const BusinessDetailScreen({super.key, required this.business});

  @override
  Widget build(BuildContext context) {
    return BlocSelector<BusinessBloc, BusinessState, BusinessData?>(
      selector: (state) => state.businessList
          ?.firstWhere((b) => b.id == business.id, orElse: () => business),
      builder: (context, data) {
        final b = data ?? business;
        return Scaffold(
          body: CustomScrollView(
            slivers: [
              DetailAppBar(business: b),
              SliverPadding(
                padding: const EdgeInsets.all(AppDims.s4),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    InfoSection(business: b),
                    const SizedBox(height: AppDims.s5),
                    ShopsSection(shops: b.shops ?? []),
                    const SizedBox(height: AppDims.s6),
                  ]),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}