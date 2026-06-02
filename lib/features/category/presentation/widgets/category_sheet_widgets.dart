import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/features/category/presentation/bloc/category_bloc.dart';
import 'package:amana_pos/widgets/app_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CategorySubmitButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool enabled;

  const CategorySubmitButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return BlocSelector<CategoryBloc, CategoryState, bool>(
      selector: (state) => state.submitStatus == CategorySubmitStatus.loading,
      builder: (context, isLoading) {
        final canAct = enabled && !isLoading;
        return AppButton.wide(
          label: label,
          isLoading: isLoading,
          onPressed: canAct ? onPressed : null,
        );
      },
    );
  }
}

class CategoryFormValidators {
  CategoryFormValidators._();

  static String? name(BuildContext context, String? value) {
    final text = value?.trim() ?? '';

    if (text.isEmpty) {
      return context.tr.categoryNameRequired;
    }

    if (text.length < 2) {
      return context.tr.nameMustBeAtLeast2Characters;
    }

    return null;
  }
}