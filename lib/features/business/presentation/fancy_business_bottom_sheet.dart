import 'package:amana_pos/common/auth_bloc/auth_bloc.dart' hide BusinessStatus;
import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/config/router/route_strings.dart';
import 'package:amana_pos/features/business/presentation/bloc/business_bloc.dart';
import 'package:amana_pos/features/business/presentation/widgets/settings/business_form_parts.dart';
import 'package:amana_pos/features/main_screen/data/app_feature.dart';
import 'package:amana_pos/features/main_screen/presentation/bloc/navigation_bloc.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/utilities/dependencies_provider.dart';
import 'package:amana_pos/utilities/global_snackbar.dart';
import 'package:amana_pos/widgets/app_button.dart';
import 'package:amana_pos/widgets/app_form_group.dart';
import 'package:amana_pos/widgets/app_large_title.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// First run: the owner has no business yet. Full-screen, cannot be dismissed.
class FancyBusinessBottomSheet {
  static bool isShowing = false;

  static Future<void> show(BuildContext context) async {
    if (isShowing) return;

    isShowing = true;

    final business = context.read<BusinessBloc>();
    final auth = context.read<AuthBloc>();

    await Navigator.of(context, rootNavigator: true).push<void>(
      PageRouteBuilder<void>(
        pageBuilder: (_, _, _) => MultiBlocProvider(
          providers: [
            BlocProvider.value(value: business),
            BlocProvider.value(value: auth),
          ],
          child: const _CreateBusinessScreen(),
        ),
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );

    isShowing = false;
  }

  static void reset() {
    isShowing = false;
  }
}

class _CreateBusinessScreen extends StatefulWidget {
  const _CreateBusinessScreen();

  @override
  State<_CreateBusinessScreen> createState() => _CreateBusinessScreenState();
}

class _CreateBusinessScreenState extends State<_CreateBusinessScreen> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _nameCtrl.addListener(_refresh);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  bool get _canSubmit => _nameCtrl.text.trim().isNotEmpty;

  void _submit() {
    if (!_canSubmit) return;
    FocusScope.of(context).unfocus();
    final phone = _phoneCtrl.text.trim();
    context.read<BusinessBloc>().add(
      OnAddBusiness(
        name: _nameCtrl.text.trim(),
        phone: phone.isEmpty ? null : phone,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final tr = context.tr;

    return PopScope(
      canPop: false,
      child: BlocListener<BusinessBloc, BusinessState>(
        listenWhen: (prev, curr) => prev.submitStatus != curr.submitStatus,
        listener: (context, state) {
          if (state.submitStatus == BusinessSubmitStatus.success) {
            context.read<AuthBloc>().add(OnLoadBusinessEvent());
            GlobalSnackBar.show(message: tr.bsSaved, isInfo: true);
            getIt<NavigationBloc>().add(
              NavigationFeatureSelected(AppFeature.business),
            );
            Navigator.of(context, rootNavigator: true).pushNamedAndRemoveUntil(
              RouteStrings.mainScreen,
              (route) => false,
            );
          }

          if (state.submitStatus == BusinessSubmitStatus.failure) {
            GlobalSnackBar.show(
              message: state.submitError ?? tr.somethingWentWrong,
              isError: true,
              isAutoDismiss: false,
            );
          }
        },
        child: Scaffold(
          backgroundColor: colors.background,
          body: SafeArea(
            bottom: false,
            child: Column(
              children: [
                const SizedBox(height: 44),
                Expanded(
                  child: SingleChildScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsets.fromLTRB(
                      AppDims.s4,
                      0,
                      AppDims.s4,
                      AppDims.s6,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        AppLargeTitle(
                          title: tr.obCreateTitle,
                          subtitle: tr.obCreateBody,
                        ),
                        const SizedBox(height: AppDims.s2),
                        AppFormGroup(
                          footer: tr.obCreateFoot,
                          children: [
                            AppFormRow(
                              child: Row(
                                children: [
                                  BizRequiredLabel(tr.bsName),
                                  const SizedBox(width: AppDims.s2),
                                  Expanded(
                                    child: AppRowTextField(
                                      controller: _nameCtrl,
                                      hint: tr.bsName,
                                      textCapitalization:
                                          TextCapitalization.words,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            AppFormRow(
                              label: tr.bsPhone,
                              child: AppRowTextField(
                                controller: _phoneCtrl,
                                hint: tr.optional,
                                numeric: true,
                                keyboardType: TextInputType.phone,
                                textInputAction: TextInputAction.done,
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                    RegExp(r'[0-9+ ]'),
                                  ),
                                ],
                                onSubmitted: (_) => _submit(),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                BlocSelector<BusinessBloc, BusinessState, bool>(
                  selector: (s) =>
                      s.submitStatus == BusinessSubmitStatus.loading,
                  builder: (context, loading) => DecoratedBox(
                    decoration: BoxDecoration(
                      color: colors.background,
                      border: Border(
                        top: BorderSide(color: colors.border, width: 0.5),
                      ),
                    ),
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        AppDims.s4,
                        10,
                        AppDims.s4,
                        10 + MediaQuery.viewPaddingOf(context).bottom,
                      ),
                      child: AppButton.wide(
                        label: tr.obCreateAction,
                        isLoading: loading,
                        onPressed: _canSubmit ? _submit : null,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
