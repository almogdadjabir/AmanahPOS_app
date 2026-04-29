import 'package:amana_pos/features/category/presentation/bloc/category_bloc.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/utilities/global_snackbar.dart';
import 'package:amana_pos/widgets/field_label.dart';
import 'package:amana_pos/widgets/form_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

void showAddCategorySheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => BlocProvider.value(
      value: context.read<CategoryBloc>(),
      child: const _AddCategorySheet(),
    ),
  );
}

class _AddCategorySheet extends StatefulWidget {
  const _AddCategorySheet();

  @override
  State<_AddCategorySheet> createState() => _AddCategorySheetState();
}

class _AddCategorySheetState extends State<_AddCategorySheet> {
  final _formKey  = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _nameFocus = FocusNode();
  final _descFocus = FocusNode();

  @override
  void dispose() {
    _nameCtrl.dispose(); _descCtrl.dispose();
    _nameFocus.dispose(); _descFocus.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    context.read<CategoryBloc>().add(OnAddCategory(
      name: _nameCtrl.text.trim(),
      description: _descCtrl.text.trim().isEmpty
          ? null
          : _descCtrl.text.trim(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<CategoryBloc, CategoryState>(
      listenWhen: (prev, curr) => prev.submitStatus != curr.submitStatus,
      listener: (context, state) {
        if (state.submitStatus == CategorySubmitStatus.success) {
          Navigator.of(context).pop();
          GlobalSnackBar.show(
            message: 'Category created successfully',
            isInfo: true,
          );
        }
        if (state.submitStatus == CategorySubmitStatus.failure) {
          GlobalSnackBar.show(
            message: state.submitError ?? 'Something went wrong',
            isError: true,
            isAutoDismiss: false,
          );
        }
      },
      child: Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: Container(
          decoration: BoxDecoration(
            color: context.appColors.surface,
            borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppDims.rXl)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: AppDims.s3),
              Container(
                width: 36, height: 4,
                decoration: BoxDecoration(
                  color: context.appColors.border,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppDims.s4, AppDims.s4, AppDims.s4, 0),
                child: Row(
                  children: [
                    Text(
                      'New Category',
                      style: AppTextStyles.bs600(context).copyWith(
                        fontWeight: FontWeight.w800,
                        color: context.appColors.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        width: 42, height: 42,
                        decoration: BoxDecoration(
                          color: context.appColors.surfaceSoft,
                          borderRadius: BorderRadius.circular(AppDims.rSm),
                        ),
                        child: Icon(Icons.close_rounded,
                            size: 24,
                            color: context.appColors.textSecondary),
                      ),
                    ),
                  ],
                ),
              ),

              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppDims.s4),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FieldLabel(label: 'Category Name', required: true),
                        const SizedBox(height: AppDims.s1),
                        AppFormField(
                          controller: _nameCtrl,
                          focusNode: _nameFocus,
                          nextFocus: _descFocus,
                          hint: 'Beverages',
                          prefixIcon: Icons.layers_rounded,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Category name is required';
                            }
                            if (v.trim().length < 2) {
                              return 'Name must be at least 2 characters';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: AppDims.s4),

                        Row(
                          children: [
                            Expanded(
                                child: Divider(
                                    color: context.appColors.border)),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: AppDims.s2),
                              child: Text(
                                'OPTIONAL',
                                style: AppTextStyles.bs300(context).copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: context.appColors.textHint,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ),
                            Expanded(
                                child: Divider(
                                    color: context.appColors.border)),
                          ],
                        ),
                        const SizedBox(height: AppDims.s4),

                        FieldLabel(label: 'Description'),
                        const SizedBox(height: AppDims.s1),
                        AppFormField(
                          controller: _descCtrl,
                          focusNode: _descFocus,
                          hint: 'Drinks and beverages',
                          prefixIcon: Icons.notes_rounded,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => _submit(),
                        ),
                        const SizedBox(height: AppDims.s5),

                        BlocBuilder<CategoryBloc, CategoryState>(
                          buildWhen: (prev, curr) =>
                          prev.submitStatus != curr.submitStatus,
                          builder: (context, state) {
                            final isLoading = state.submitStatus ==
                                CategorySubmitStatus.loading;
                            return SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: FilledButton(
                                onPressed: isLoading ? null : _submit,
                                style: FilledButton.styleFrom(
                                  backgroundColor: context.appColors.primary,
                                  disabledBackgroundColor:
                                  context.appColors.border,
                                  shape: RoundedRectangleBorder(
                                    borderRadius:
                                    BorderRadius.circular(AppDims.rMd),
                                  ),
                                ),
                                child: isLoading
                                    ? const SizedBox(
                                  width: 20, height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Colors.white,
                                  ),
                                )
                                    : Text(
                                  'Create Category',
                                  style:
                                  AppTextStyles.bs600(context)
                                      .copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}