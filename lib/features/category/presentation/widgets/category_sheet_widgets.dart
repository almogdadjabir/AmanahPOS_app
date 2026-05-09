import 'package:amana_pos/features/category/presentation/bloc/category_bloc.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CategorySubmitButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final bool enabled;

  const CategorySubmitButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CategoryBloc, CategoryState>(
      buildWhen: (prev, curr) => prev.submitStatus != curr.submitStatus,
      builder: (context, state) {
        final isLoading = state.submitStatus == CategorySubmitStatus.loading;
        final canAct = enabled && !isLoading;

        return SizedBox(
          width:  double.infinity,
          height: 50,
          child: FilledButton(
            onPressed: canAct ? onPressed : null,
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
              style: AppTextStyles.bs600(context).copyWith(
                fontWeight: FontWeight.w800,
                color: canAct ? Colors.white : context.appColors.textHint,
              ),
            ),
          ),
        );
      },
    );
  }
}

class CategoryFormValidators {
  CategoryFormValidators._();

  static String? name(String? v) {
    if (v == null || v.trim().isEmpty) return 'Category name is required';
    if (v.trim().length < 2) return 'Name must be at least 2 characters';
    return null;
  }
}