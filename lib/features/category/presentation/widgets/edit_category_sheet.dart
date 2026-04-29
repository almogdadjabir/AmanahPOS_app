import 'package:amana_pos/features/category/data/models/responses/category_response_dto.dart';
import 'package:amana_pos/features/category/presentation/bloc/category_bloc.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/utilities/global_snackbar.dart';
import 'package:amana_pos/widgets/field_label.dart';
import 'package:amana_pos/widgets/form_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

void showEditCategorySheet(BuildContext context,
    {required CategoryData category}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => BlocProvider.value(
      value: context.read<CategoryBloc>(),
      child: _EditCategorySheet(category: category),
    ),
  );
}

class _EditCategorySheet extends StatefulWidget {
  final CategoryData category;
  const _EditCategorySheet({required this.category});

  @override
  State<_EditCategorySheet> createState() => _EditCategorySheetState();
}

class _EditCategorySheetState extends State<_EditCategorySheet> {
  final _formKey  = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;
  final _nameFocus = FocusNode();
  final _descFocus = FocusNode();

  bool get _hasChanges =>
      _nameCtrl.text.trim() != (widget.category.name ?? '') ||
          _descCtrl.text.trim() != (widget.category.description ?? '');

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.category.name ?? '');
    _descCtrl = TextEditingController(text: widget.category.description ?? '');
    for (final c in [_nameCtrl, _descCtrl]) {
      c.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); _descCtrl.dispose();
    _nameFocus.dispose(); _descFocus.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (!_hasChanges) return;
    context.read<CategoryBloc>().add(OnEditCategory(
      categoryId:  widget.category.id!,
      name: _nameCtrl.text.trim(),
      description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<CategoryBloc, CategoryState>(
      listenWhen: (prev, curr) => prev.submitStatus != curr.submitStatus,
      listener: (context, state) {
        if (state.submitStatus == CategorySubmitStatus.success) {
          Navigator.of(context).pop();
          GlobalSnackBar.show(message: 'Category updated', isInfo: true);
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
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Edit Category',
                          style: AppTextStyles.bs600(context).copyWith(
                            fontWeight: FontWeight.w800,
                            color: context.appColors.textPrimary,
                          ),
                        ),
                        Text(
                          widget.category.name ?? '',
                          style: AppTextStyles.bs300(context)
                              .copyWith(color: context.appColors.textHint),
                        ),
                      ],
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
                        FieldLabel(label: 'Name', required: true),
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
                        const SizedBox(height: AppDims.s3),

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
                            final canSave = _hasChanges && !isLoading;
                            return SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: FilledButton(
                                onPressed: canSave ? _submit : null,
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
                                  'Save Changes',
                                  style: TextStyle(
                                    fontFamily: 'NunitoSans',
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    color: canSave
                                        ? Colors.white
                                        : context.appColors.textHint,
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