import 'package:amana_pos/features/customers/presentation/bloc/customers_bloc.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CustomerSubmitButton extends StatelessWidget {
  final String       label;
  final VoidCallback onPressed;

  const CustomerSubmitButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CustomersBloc, CustomersState>(
      buildWhen: (prev, curr) => prev.submitStatus != curr.submitStatus,
      builder: (context, state) {
        final isLoading = state.submitStatus == CustomerSubmitStatus.loading;
        return SizedBox(
          width:  double.infinity,
          height: 50,
          child: FilledButton(
            onPressed: isLoading ? null : onPressed,
            style: FilledButton.styleFrom(
              backgroundColor:        context.appColors.primary,
              disabledBackgroundColor: context.appColors.border,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDims.rMd),
              ),
            ),
            child: isLoading
                ? const SizedBox(
              width: 20, height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2.5, color: Colors.white,
              ),
            )
                : Text(
              label,
              style: AppTextStyles.bs500(context).copyWith(
                color: Colors.white, fontWeight: FontWeight.w900,
              ),
            ),
          ),
        );
      },
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