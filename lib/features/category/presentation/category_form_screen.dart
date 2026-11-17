import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/common/motion/motion_route.dart';
import 'package:amana_pos/common/services/image/app_image_picker.dart';
import 'package:amana_pos/common/widgets/image_upload_box.dart';
import 'package:amana_pos/features/category/data/models/responses/category_response_dto.dart';
import 'package:amana_pos/features/category/presentation/bloc/category_bloc.dart';
import 'package:amana_pos/features/category/presentation/widgets/category_sheet_widgets.dart';
import 'package:amana_pos/features/products/presentation/widgets/product_form_widgets.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/theme/phosphor_icons.dart';
import 'package:amana_pos/utilities/global_snackbar.dart';
import 'package:amana_pos/widgets/app_confirm_sheet.dart';
import 'package:amana_pos/widgets/app_form_group.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Opens the new / edit category screen. [category] null = new category.
/// [fromDetail] is true when the category detail screen sits right under the
/// form, so deleting the category also closes the detail. [bloc] defaults to
/// the one in [context] (the pending-sync screen passes its own).
Future<void> openCategoryForm(
  BuildContext context, {
  CategoryData? category,
  bool fromDetail = false,
  CategoryBloc? bloc,
}) {
  bloc ??= context.read<CategoryBloc>();

  return Navigator.of(context).push(
    motionPageRoute(
      BlocProvider.value(
        value: bloc,
        child: _CategoryFormScreen(category: category, fromDetail: fromDetail),
      ),
    ),
  );
}

/// Waits for the next finished submit on [bloc] (success or failure).
Future<CategoryState> _nextSubmitResult(CategoryBloc bloc) {
  return bloc.stream.firstWhere(
    (s) =>
        s.submitStatus == CategorySubmitStatus.success ||
        s.submitStatus == CategorySubmitStatus.failure,
  );
}

/// Confirms, deletes and reports the result with a snackbar.
/// Resolves to true when the category was deleted.
Future<bool> confirmDeleteCategory(
  BuildContext context,
  CategoryData category,
) async {
  final tr = context.tr;
  final bloc = context.read<CategoryBloc>();
  final id = category.id?.trim();
  final name = category.name?.trim();
  final displayName = name?.isNotEmpty == true ? name! : tr.category;

  if (id == null || id.isEmpty) {
    GlobalSnackBar.show(message: tr.invalidCategory, isError: true);
    return false;
  }

  final confirmed = await showAppConfirmSheet(
    context,
    title: tr.deleteCategoryTitle,
    message: tr.deleteCategoryMessage(displayName),
    confirmLabel: tr.delete,
  );
  if (!confirmed) return false;

  final result = _nextSubmitResult(bloc);
  bloc.add(OnDeleteCategory(categoryId: id));
  final state = await result;

  if (state.submitStatus == CategorySubmitStatus.success) {
    GlobalSnackBar.show(message: tr.categoryDeletedSuccessfully, isInfo: true);
    return true;
  }

  GlobalSnackBar.show(
    message: state.submitError ?? tr.somethingWentWrong,
    isError: true,
    isAutoDismiss: false,
  );
  return false;
}

class _CategoryFormScreen extends StatefulWidget {
  final CategoryData? category;
  final bool fromDetail;
  const _CategoryFormScreen({this.category, this.fromDetail = false});

  @override
  State<_CategoryFormScreen> createState() => _CategoryFormScreenState();
}

class _CategoryFormScreenState extends State<_CategoryFormScreen> {
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  bool _saving = false;
  PickedAppImage? _image;

  bool get _isEdit => widget.category != null;

  String? get _existingImageUrl {
    final c = widget.category;
    for (final u in [c?.image, c?.thumbnailUrl]) {
      final t = u?.trim();
      if (t != null && t.isNotEmpty) return t;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _nameCtrl.text = widget.category?.name?.trim() ?? '';
    _descCtrl.text = widget.category?.description?.trim() ?? '';
    _nameCtrl.addListener(_refresh);
    _descCtrl.addListener(_refresh);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  bool get _canSave =>
      CategoryFormValidators.name(context, _nameCtrl.text) == null;

  Future<void> _save() async {
    if (_saving || !_canSave) return;
    final tr = context.tr;
    final bloc = context.read<CategoryBloc>();
    final name = _nameCtrl.text.trim();
    final description = _descCtrl.text.trim();

    final existing = widget.category;
    if (existing != null) {
      final id = existing.id?.trim();
      if (id == null || id.isEmpty) {
        GlobalSnackBar.show(message: tr.invalidCategory, isError: true);
        return;
      }
      FocusScope.of(context).unfocus();
      setState(() => _saving = true);
      final result = _nextSubmitResult(bloc);
      bloc.add(
        OnEditCategory(
          categoryId: id,
          name: name,
          description: description.isEmpty ? null : description,
          image: _image,
        ),
      );
      await _finish(result, tr.categoryUpdatedSuccessfully);
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _saving = true);
    final result = _nextSubmitResult(bloc);
    bloc.add(
      OnAddCategory(
        name: name,
        description: description.isEmpty ? null : description,
        image: _image,
      ),
    );
    await _finish(result, tr.categoryCreatedSuccessfully);
  }

  Future<void> _finish(Future<CategoryState> result, String success) async {
    final tr = context.tr;
    final state = await result;
    if (!mounted) return;

    if (state.submitStatus == CategorySubmitStatus.success) {
      Navigator.of(context).pop();
      GlobalSnackBar.show(message: success, isInfo: true);
      return;
    }

    setState(() => _saving = false);
    GlobalSnackBar.show(
      message: state.submitError ?? tr.somethingWentWrong,
      isError: true,
      isAutoDismiss: false,
    );
  }

  Future<void> _delete() async {
    final category = widget.category;
    if (category == null) return;
    final navigator = Navigator.of(context);
    final deleted = await confirmDeleteCategory(context, category);
    if (!deleted || !mounted) return;
    // Back to the list: close this form, and the category detail under it.
    navigator.pop();
    if (widget.fromDetail) navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final tr = context.tr;

    final count = context.select<CategoryBloc, int?>((bloc) {
      final id = widget.category?.id;
      for (final c in bloc.state.categoryList) {
        if (c.id == id) return c.productCount;
      }
      return widget.category?.productCount;
    });

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            FormNavBar(
              title: _isEdit ? tr.pfEditCategory : tr.pfNewCategory,
              onCancel: () => Navigator.of(context).maybePop(),
              onSave: _canSave ? _save : null,
              saving: _saving,
            ),
            Expanded(
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: EdgeInsets.fromLTRB(
                  AppDims.s4,
                  AppDims.s4,
                  AppDims.s4,
                  AppDims.s8 + MediaQuery.viewPaddingOf(context).bottom,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Staged locally, uploaded in the background (Task 7).
                    FormPhotoTile(
                      picked: _image,
                      imageUrl: _existingImageUrl,
                      productId: widget.category?.id,
                      entityType: 'category',
                      onTap: () => ImageUploadBox.showPicker(
                        context,
                        (image) => setState(() => _image = image),
                      ),
                    ),
                    const SizedBox(height: AppDims.s4),
                    AppFormGroup(
                      children: [
                        AppFormRow(
                          label: tr.pfName,
                          child: AppRowTextField(
                            controller: _nameCtrl,
                            hint: tr.categoryNameHint,
                          ),
                        ),
                        AppFormRow(
                          minHeight: 96,
                          align: CrossAxisAlignment.start,
                          child: AppRowTextField(
                            controller: _descCtrl,
                            hint: tr.ctDescHint,
                            maxLines: 4,
                            keyboardType: TextInputType.multiline,
                            textInputAction: TextInputAction.newline,
                          ),
                        ),
                      ],
                    ),
                    if (_isEdit) ...[
                      if (count != null) ...[
                        const SizedBox(height: AppDims.s4),
                        AppFormGroup(
                          children: [
                            AppFormRow(
                              child: AppRowValue(tr.ctInThis('$count')),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: AppDims.s6),
                      AppFormGroup(
                        footer: tr.ctDeleteNote,
                        children: [
                          AppFormRow(
                            onTap: _saving ? null : _delete,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  PhosphorIconsRegular.trash,
                                  size: 20,
                                  color: colors.danger,
                                ),
                                const SizedBox(width: AppDims.s2),
                                Text(
                                  tr.ctDelete,
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w500,
                                    color: colors.danger,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
