import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/features/customers/data/models/responses/customer_response_dto.dart';
import 'package:amana_pos/features/customers/presentation/bloc/customers_bloc.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/utilities/global_snackbar.dart';
import 'package:amana_pos/widgets/app_deactivate_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solar_icons/solar_icons.dart';

void showDeleteCustomerSheet(BuildContext context, {required CustomerData customer}) {
  AppDeactivateBottomSheet.show(
    context: context,
    child: BlocProvider.value(
      value: context.read<CustomersBloc>(),
      child: _DeleteCustomerSheet(customer: customer),
    ),
  );
}

class _DeleteCustomerSheet extends StatelessWidget {
  final CustomerData customer;
  const _DeleteCustomerSheet({required this.customer});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final tr = context.tr;

    return BlocListener<CustomersBloc, CustomersState>(
      listenWhen: (prev, curr) => prev.submitStatus != curr.submitStatus,
      listener: (context, state) {
        if (state.submitStatus == CustomerSubmitStatus.success) {
          Navigator.of(context).pop();
          Navigator.of(context).maybePop();
          return;
        }
        if (state.submitStatus == CustomerSubmitStatus.failure) {
          Navigator.of(context).pop();
          GlobalSnackBar.show(
            message: state.submitError ?? tr.somethingWentWrong,
            isError: true,
            isAutoDismiss: false,
          );
        }
      },
      child: BlocSelector<CustomersBloc, CustomersState, bool>(
        selector: (state) => state.submitStatus == CustomerSubmitStatus.loading,
        builder: (context, isLoading) => AppDeactivateBottomSheet(
          title: tr.deleteCustomerTitle,
          description: tr.deleteCustomerConfirm(customer.name ?? tr.customers),
          icon: SolarIconsOutline.trashBinTrash,
          confirmText: tr.delete,
          confirmColor: colors.danger,
          isLoading: isLoading,
          onConfirm: () {
            final customerId = customer.id;
            if (customerId == null) {
              GlobalSnackBar.show(message: tr.invalidCustomer, isError: true);
              return;
            }
            context.read<CustomersBloc>().add(OnDeleteCustomer(customerId: customerId));
          },
        ),
      ),
    );
  }
}
