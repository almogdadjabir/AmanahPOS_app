import 'package:amana_pos/features/customers/presentation/bloc/customers_bloc.dart';
import 'package:amana_pos/widgets/app_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CustomerSubmitButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const CustomerSubmitButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return BlocSelector<CustomersBloc, CustomersState, bool>(
      selector: (state) => state.submitStatus == CustomerSubmitStatus.loading,
      builder: (context, isLoading) => AppButton.wide(
        label: label,
        isLoading: isLoading,
        onPressed: isLoading ? null : onPressed,
      ),
    );
  }
}

class CustomerFormValidators {
  CustomerFormValidators._();

  static String? name(String? v) {
    final value = v?.trim() ?? '';
    if (value.isEmpty) return 'Name is required';
    if (value.length < 2) return 'Name is too short';
    return null;
  }

  static String? phone(String? v) {
    final value = v?.trim() ?? '';
    if (value.isEmpty) return 'Phone is required';
    if (value.length < 8) return 'Invalid phone number';
    return null;
  }

  static String? email(String? v) {
    final value = v?.trim() ?? '';
    if (value.isEmpty) return null;
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value)) {
      return 'Enter a valid email';
    }
    return null;
  }

  static String? loyaltyPoints(String? v) {
    final value = v?.trim() ?? '';
    if (value.isEmpty) return null;
    final parsed = int.tryParse(value);
    if (parsed == null) return 'Enter valid points';
    if (parsed < 0) return 'Points cannot be negative';
    return null;
  }
}