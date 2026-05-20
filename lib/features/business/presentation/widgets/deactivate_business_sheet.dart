import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/features/business/data/models/responses/business_response_dto.dart';
import 'package:amana_pos/features/business/presentation/bloc/business_bloc.dart';
import 'package:amana_pos/utilities/global_snackbar.dart';
import 'package:amana_pos/widgets/app_deactivate_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

void showDeactivateBusinessSheet(
    BuildContext context,
    BusinessData business,
    ) {
  AppDeactivateBottomSheet.show(
    context: context,
    child: BlocProvider.value(
      value: context.read<BusinessBloc>(),
      child: BlocConsumer<BusinessBloc, BusinessState>(
        listenWhen: (previous, current) =>
        previous.submitStatus != current.submitStatus,
        listener: (context, state) {
          if (state.submitStatus == BusinessSubmitStatus.success) {
            Navigator.of(context)
              ..pop()
              ..pop();

            GlobalSnackBar.show(
              message: 'Business deactivated',
              isWarning: true,
            );
          }

          if (state.submitStatus == BusinessSubmitStatus.failure) {
            Navigator.of(context).pop();

            GlobalSnackBar.show(
              message: state.submitError ?? 'Something went wrong',
              isError: true,
              isAutoDismiss: false,
            );
          }
        },
        buildWhen: (previous, current) =>
        previous.submitStatus != current.submitStatus,
        builder: (context, state) {
          final isLoading =
              state.submitStatus == BusinessSubmitStatus.loading;

          return AppDeactivateBottomSheet(
            title: context.tr.bizDeactivateTitle,
            description: '"${business.name}" will be deactivated. '
                'All associated shops will stop operating. '
                'You can reactivate it later.',
            isLoading: isLoading,
            onConfirm: () {
              final businessId = business.id;

              if (businessId == null) {
                GlobalSnackBar.show(
                  message: 'Invalid business ID',
                  isError: true,
                );
                return;
              }

              context.read<BusinessBloc>().add(
                OnDeactivateBusiness(businessId: businessId),
              );
            },
          );
        },
      ),
    ),
  );
}