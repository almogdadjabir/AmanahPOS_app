import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/config/router/route_strings.dart';
import 'package:amana_pos/features/category/presentation/bloc/category_bloc.dart';
import 'package:amana_pos/features/category/presentation/category_form_screen.dart';
import 'package:amana_pos/features/category/presentation/widgets/category_row.dart';
import 'package:amana_pos/features/category/presentation/widgets/category_states.dart';
import 'package:amana_pos/features/main_screen/presentation/widgets/nav_shell.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/theme/phosphor_icons.dart';
import 'package:amana_pos/widgets/app_large_title.dart';
import 'package:amana_pos/widgets/directional_icon.dart';
import 'package:amana_pos/widgets/pressable.dart';
import 'package:flutter/cupertino.dart' show CupertinoSliverRefreshControl;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    context.read<CategoryBloc>().add(const OnCategoryInitial());
  }

  Future<void> _refresh() async {
    final bloc = context.read<CategoryBloc>();
    bloc.add(const OnCategoryInitial(force: true));
    try {
      await bloc.stream
          .firstWhere(
            (s) =>
                s.categoryStatus == CategoryStatus.failure ||
                (s.categoryStatus == CategoryStatus.success && !s.isFromCache),
          )
          .timeout(const Duration(seconds: 10));
    } catch (_) {
      // Timed out: let the control settle, cached data stays on screen.
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final bottomInset =
        NavShell.contentHeight + MediaQuery.viewPaddingOf(context).bottom + 20;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const _NavBar(),
            Expanded(
              child: BlocBuilder<CategoryBloc, CategoryState>(
                buildWhen: (prev, curr) =>
                    prev.categoryStatus != curr.categoryStatus ||
                    prev.categoryList != curr.categoryList ||
                    prev.responseError != curr.responseError,
                builder: (context, state) => CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  slivers: [
                    CupertinoSliverRefreshControl(onRefresh: _refresh),
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(
                        AppDims.s4,
                        0,
                        AppDims.s4,
                        bottomInset,
                      ),
                      sliver: SliverToBoxAdapter(child: _content(state)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _content(CategoryState state) {
    final tr = context.tr;
    final loading =
        state.categoryStatus == CategoryStatus.initial ||
        state.categoryStatus == CategoryStatus.loading;

    if (loading) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppLargeTitle(title: tr.fbCategoriesTitle),
          const CategorySkeleton(),
        ],
      );
    }

    if (state.categoryStatus == CategoryStatus.failure) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppLargeTitle(title: tr.fbCategoriesTitle),
          CategoryStateCard(
            icon: PhosphorIconsRegular.wifiSlash,
            tone: CategoryStateTone.danger,
            title: tr.fbCategoriesErrorTitle,
            body: state.responseError ?? tr.pcErrorBody,
            actionLabel: tr.retry,
            secondaryAction: true,
            onAction: () => context.read<CategoryBloc>().add(
              const OnCategoryInitial(force: true),
            ),
          ),
        ],
      );
    }

    if (state.categoryList.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppLargeTitle(title: tr.fbCategoriesTitle),
          CategoryStateCard(
            icon: PhosphorIconsRegular.stack,
            title: tr.noCategoriesYet,
            body: tr.ctEmptyBody,
            actionLabel: tr.pfNewCategory,
            onAction: () => openCategoryForm(context),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppLargeTitle(
          title: tr.fbCategoriesTitle,
          subtitle: tr.ctCountTitle('${state.categoryList.length}'),
        ),
        CategoryListGroup(categories: state.categoryList),
      ],
    );
  }
}

class _NavBar extends StatelessWidget {
  const _NavBar();

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final tr = context.tr;

    return SizedBox(
      height: 44,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: [
            // Categories lives in the shell; the More menu is its parent.
            Pressable(
              onTap: () =>
                  Navigator.of(context).pushNamed(RouteStrings.settingsScreen),
              child: SizedBox(
                height: 44,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(width: 4),
                    DirectionalIcon(
                      icon: PhosphorIconsRegular.caretLeft,
                      size: 24,
                      color: colors.primary,
                    ),
                    Text(
                      tr.navMore,
                      style: TextStyle(fontSize: 17, color: colors.primary),
                    ),
                    const SizedBox(width: 8),
                  ],
                ),
              ),
            ),
            const Spacer(),
            Pressable(
              onTap: () => openCategoryForm(context),
              child: SizedBox(
                width: 44,
                height: 44,
                child: Icon(
                  PhosphorIconsRegular.plus,
                  size: 26,
                  color: colors.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
