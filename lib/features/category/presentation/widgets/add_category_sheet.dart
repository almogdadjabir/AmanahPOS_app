import 'package:amana_pos/common/localization/app_localizations_extension.dart';
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
  final categoryBloc = context.read<CategoryBloc>();

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => BlocProvider.value(
      value: categoryBloc,
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

  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;

  late final FocusNode _nameFocus;
  late final FocusNode _descFocus;

  @override
  void initState() {
    super.initState();

    _nameCtrl = TextEditingController();
    _descCtrl = TextEditingController();

    _nameFocus = FocusNode();
    _descFocus = FocusNode();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();

    _nameFocus.dispose();
    _descFocus.dispose();

    super.dispose();
  }

  void _submit() {
    final formState = _formKey.currentState;
    if (formState == null || !formState.validate()) return;

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
    final tr = context.tr;

    return BlocListener<CategoryBloc, CategoryState>(
      listenWhen: (prev, curr) => prev.submitStatus != curr.submitStatus,
      listener: (context, state) {
        if (state.submitStatus == CategorySubmitStatus.success) {
          Navigator.of(context).pop();

          GlobalSnackBar.show(
            message: context.tr.categoryCreatedSuccessfully,
            isInfo: true,
          );
          return;
        }

        if (state.submitStatus == CategorySubmitStatus.failure) {
          GlobalSnackBar.show(
            message: state.submitError ?? context.tr.somethingWentWrong,
            isError: true,
            isAutoDismiss: false,
          );
        }
      },
      child: ProductSheetShell(
        title: tr.newCategory,
        body: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _CategorySheetIntro(),

              const SizedBox(height: AppDims.s5),

              FieldLabel(
                label: tr.fieldCategoryName,
                required: true,
              ),
              const SizedBox(height: AppDims.s1),
              AppFormField(
                controller: _nameCtrl,
                focusNode: _nameFocus,
                nextFocus: _descFocus,
                hint: tr.categoryNameHint,
                prefixIcon: SolarIconsOutline.layersMinimalistic,
                validator: (value) {
                  return CategoryFormValidators.name(context, value);
                },
              ),

              const SizedBox(height: AppDims.s4),

              FieldLabel(label: tr.fieldDescription),
              const SizedBox(height: AppDims.s1),
              AppFormField(
                controller: _descCtrl,
                focusNode: _descFocus,
                hint: tr.categoryDescriptionHint,
                prefixIcon: SolarIconsOutline.notes,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) {
                  final submitStatus = context.read<CategoryBloc>().state.submitStatus;
                  final isSubmitting = submitStatus == CategorySubmitStatus.loading;

                  if (!isSubmitting) {
                    _submit();
                  }
                },
              ),

              const SizedBox(height: AppDims.s4),

              const _CategoryTipsCard(),

              const SizedBox(height: AppDims.s5),

              _AmanaCategorySubmitButton(
                label: tr.createCategory,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategorySheetIntro extends StatelessWidget {
  const _CategorySheetIntro();

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final tr = context.tr;

    return DecoratedBox(
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
      child: Padding(
        padding: const EdgeInsets.all(AppDims.s4),
        child: Row(
          children: [
            _IntroIcon(color: colors.primary),

            const SizedBox(width: AppDims.s3),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tr.createProductGroup,
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
                    tr.createProductGroupMessage,
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
      ),
    );
  }
}

class _IntroIcon extends StatelessWidget {
  final Color color;

  const _IntroIcon({
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppDims.rLg),
        border: Border.all(
          color: color.withValues(alpha: 0.16),
        ),
      ),
      child: SizedBox(
        width: 56,
        height: 56,
        child: Icon(
          SolarIconsOutline.layersMinimalistic,
          color: color,
          size: 28,
        ),
      ),
    );
  }
}

class _CategoryTipsCard extends StatelessWidget {
  const _CategoryTipsCard();

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppDims.rMd),
        border: Border.all(
          color: colors.primary.withValues(alpha: 0.12),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppDims.s3),
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
                context.tr.categoryTipsMessage,
                style: AppTextStyles.bs100(context).copyWith(
                  color: colors.textSecondary,
                  fontWeight: FontWeight.w700,
                  height: 1.45,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AmanaCategorySubmitButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const _AmanaCategorySubmitButton({
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return BlocSelector<CategoryBloc, CategoryState, CategorySubmitStatus>(
      selector: (state) => state.submitStatus,
      builder: (context, submitStatus) {
        final isLoading = submitStatus == CategorySubmitStatus.loading;

        return SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: isLoading ? null : onPressed,
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
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bs300(context).copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}