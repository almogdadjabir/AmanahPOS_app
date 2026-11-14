import 'package:amana_pos/core/responsive/adaptive_sheet.dart';
import 'package:amana_pos/features/pin/presentation/widgets/pin_digits_field.dart';
import 'package:amana_pos/features/products/presentation/widgets/product_sheet_shell.dart';
import 'package:amana_pos/features/users/presentation/bloc/users_bloc.dart';
import 'package:amana_pos/features/users/presentation/widgets/user_sheet_widgets.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/utilities/global_snackbar.dart';
import 'package:amana_pos/widgets/field_label.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

void showCashierPinSheet(BuildContext context, {required String userId}) {
  final userBloc = context.read<UserBloc>();
  showAdaptivePanel(
    context,
    builder: (_) => BlocProvider.value(
      value: userBloc,
      child: _CashierPinSheet(userId: userId),
    ),
  );
}

class _CashierPinSheet extends StatefulWidget {
  const _CashierPinSheet({required this.userId});
  final String userId;

  @override
  State<_CashierPinSheet> createState() => _CashierPinSheetState();
}

class _CashierPinSheetState extends State<_CashierPinSheet> {
  final _pinCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _pinCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final pin = _pinCtrl.text.trim();
    if (pin.length != 4) {
      setState(() => _error = 'Enter a 4-digit PIN.');
      return;
    }
    if (pin != _confirmCtrl.text.trim()) {
      setState(() => _error = 'PINs do not match.');
      return;
    }
    context.read<UserBloc>().add(OnSetCashierPin(userId: widget.userId, pin: pin));
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<UserBloc, UserState>(
      listenWhen: (p, c) => p.submitStatus != c.submitStatus,
      listener: (context, state) {
        if (state.submitStatus == UserSubmitStatus.success) {
          Navigator.of(context).pop();
          GlobalSnackBar.show(message: 'PIN updated.', isInfo: true);
        } else if (state.submitStatus == UserSubmitStatus.failure) {
          GlobalSnackBar.show(
            message: state.submitError ?? 'Something went wrong.',
            isError: true,
          );
        }
      },
      child: ProductSheetShell(
        title: 'Set cashier PIN',
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const FieldLabel(label: 'New PIN', required: true),
            const SizedBox(height: AppDims.s1),
            PinDigitsField(controller: _pinCtrl, errorText: _error),
            const SizedBox(height: AppDims.s2),
            const FieldLabel(label: 'Confirm PIN', required: true),
            const SizedBox(height: AppDims.s1),
            PinDigitsField(controller: _confirmCtrl),
            const SizedBox(height: AppDims.s4),
            BlocSelector<UserBloc, UserState, UserSubmitStatus>(
              selector: (s) => s.submitStatus,
              builder: (context, status) => UserSubmitButton(
                label: 'Save PIN',
                onPressed: status == UserSubmitStatus.loading ? null : _submit,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
