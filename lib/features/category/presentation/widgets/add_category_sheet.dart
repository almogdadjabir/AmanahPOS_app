import 'package:amana_pos/features/category/presentation/bloc/category_bloc.dart';
import 'package:amana_pos/features/category/presentation/widgets/category_sheet_widgets.dart';
import 'package:amana_pos/features/products/presentation/widgets/product_sheet_shell.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/utilities/global_snackbar.dart';
import 'package:amana_pos/widgets/field_label.dart';
import 'package:amana_pos/widgets/form_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solar_icons/solar_icons.dart';

void showAddCategorySheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
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
  final _formKey = GlobalKey<FormState>();

  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  final _nameFocus = FocusNode();
  final _descFocus = FocusNode();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _nameFocus.dispose();
    _descFocus.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() != true) return;

    final name = _nameCtrl.text.trim();
    final description = _descCtrl.text.trim();

    context.read<CategoryBloc>().add(
      OnAddCategory(
        name: name,
        description: description.isEmpty ? null : description,
      ),
    );
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
      child: BlocBuilder<CategoryBloc, CategoryState>(
        buildWhen: (prev, curr) => prev.submitStatus != curr.submitStatus,
        builder: (context, state) {
          final isSubmitting =
              state.submitStatus == CategorySubmitStatus.loading;

          return ProductSheetShell(
            title: 'New Category',
            body: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _CategorySheetIntro(),
                  const SizedBox(height: AppDims.s5),

                  FieldLabel(
                    label: 'Category Name',
                    required: true,
                  ),
                  const SizedBox(height: AppDims.s1),
                  AppFormField(
                    controller: _nameCtrl,
                    focusNode: _nameFocus,
                    nextFocus: _descFocus,
                    hint: 'Beverages',
                    prefixIcon: SolarIconsOutline.layersMinimalistic,
                    validator: CategoryFormValidators.name,
                  ),

                  const SizedBox(height: AppDims.s4),

                  FieldLabel(label: 'Description'),
                  const SizedBox(height: AppDims.s1),
                  AppFormField(
                    controller: _descCtrl,
                    focusNode: _descFocus,
                    hint: 'Drinks, juices, water, and hot beverages',
                    prefixIcon: SolarIconsOutline.notes,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) {
                      if (!isSubmitting) _submit();
                    },
                  ),

                  const SizedBox(height: AppDims.s4),

                  const _CategoryTipsCard(),

                  const SizedBox(height: AppDims.s5),

                  _AmanaCategorySubmitButton(
                    label: 'Create Category',
                    isLoading: isSubmitting,
                    onPressed: isSubmitting ? null : _submit,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _CategorySheetIntro extends StatelessWidget {
  const _CategorySheetIntro();

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDims.s4),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppDims.rLg),
        border: Border.all(color: colors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(AppDims.rLg),
              border: Border.all(
                color: colors.primary.withValues(alpha: 0.16),
              ),
            ),
            child: Icon(
              SolarIconsOutline.layersMinimalistic,
              color: colors.primary,
              size: 28,
            ),
          ),
          const SizedBox(width: AppDims.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Create product group',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bs500(context).copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w900,
                    height: 1.05,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Use categories to organize products and speed up checkout.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bs200(context).copyWith(
                    color: colors.textSecondary,
                    fontWeight: FontWeight.w700,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryTipsCard extends StatelessWidget {
  const _CategoryTipsCard();

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDims.s3),
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppDims.rMd),
        border: Border.all(
          color: colors.primary.withValues(alpha: 0.12),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            SolarIconsOutline.infoCircle,
            size: 20,
            color: colors.primary,
          ),
          const SizedBox(width: AppDims.s2),
          Expanded(
            child: Text(
              'Keep category names short and clear, like Snacks, Drinks, Groceries, or Meals.',
              style: AppTextStyles.bs100(context).copyWith(
                color: colors.textSecondary,
                fontWeight: FontWeight.w700,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AmanaCategorySubmitButton extends StatelessWidget {
  final String label;
  final bool isLoading;
  final VoidCallback? onPressed;

  const _AmanaCategorySubmitButton({
    required this.label,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          elevation: 0,
          shadowColor: Colors.transparent,
          backgroundColor: colors.primary,
          disabledBackgroundColor: colors.primary.withValues(alpha: 0.55),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDims.rXl),
          ),
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          child: isLoading
              ? const SizedBox(
            key: ValueKey('loading'),
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.4,
              color: Colors.white,
            ),
          )
              : Row(
            key: const ValueKey('content'),
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                SolarIconsOutline.addCircle,
                size: 22,
                color: Colors.white,
              ),
              const SizedBox(width: AppDims.s2),
              Text(
                label,
                style: AppTextStyles.bs300(context).copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}