// lib/features/feature_menu/feature_menu.dart
//
// No logic changes — just updates references from selectedIndex to
// currentFeature since NavigationState no longer carries an index.

import 'package:amana_pos/features/feature_menu/feature_menu_sections.dart';
import 'package:amana_pos/features/feature_menu/widgets/menu_sections.dart';
import 'package:amana_pos/features/feature_menu/widgets/section_grid.dart';
import 'package:amana_pos/features/feature_menu/widgets/section_label.dart';
import 'package:amana_pos/features/main_screen/data/section.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/features/main_screen/presentation/bloc/navigation_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'widgets/menu_footer.dart';

class FeatureMenu extends StatefulWidget {
  const FeatureMenu({super.key});

  @override
  State<FeatureMenu> createState() => _FeatureMenuState();
}

class _FeatureMenuState extends State<FeatureMenu> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _closeMenu(BuildContext context) =>
      context.read<NavigationBloc>().add(const SetMenuOpenEvent());

  @override
  Widget build(BuildContext context) {
    final maxH = MediaQuery.of(context).size.height * 0.75;

    return BlocBuilder<NavigationBloc, NavigationState>(
      buildWhen: (prev, curr) =>
      prev.menuOpen != curr.menuOpen ||
          prev.currentFeature != curr.currentFeature ||
          prev.permissions != curr.permissions,
      builder: (context, state) {
        return IgnorePointer(
          ignoring: !state.menuOpen,
          child: Stack(
            children: [
              // ── Scrim ────────────────────────────────────────────────────
              AnimatedOpacity(
                duration: AppDims.fast,
                opacity: state.menuOpen ? 1 : 0,
                child: GestureDetector(
                  onTap: () => _closeMenu(context),
                  child: Container(color: Colors.black.withValues(alpha: 0.45)),
                ),
              ),

              // ── Slide-down panel ─────────────────────────────────────────
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: ClipRect(
                  child: AnimatedSlide(
                    offset:
                    state.menuOpen ? Offset.zero : const Offset(0, -1),
                    duration: AppDims.medium,
                    curve: Curves.easeOutCubic,
                    child: Material(
                      color: context.appColors.surface,
                      elevation: 0,
                      borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(AppDims.rXl),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: SafeArea(
                        bottom: false,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(maxHeight: maxH),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Flexible(
                                child: Scrollbar(
                                  controller: _scrollController,
                                  thumbVisibility: true,
                                  radius: const Radius.circular(999),
                                  child: SingleChildScrollView(
                                    controller: _scrollController,
                                    primary: false,
                                    padding:
                                    const EdgeInsets.all(AppDims.s4),
                                    // buildMenuSections now reads permissions
                                    // from NavigationState directly.
                                    child: Column(
                                      children: buildMenuSections(context, state)
                                          .map<Widget>(_buildSection)  // ← add <Widget>
                                          .toList(),
                                    ),
                                  ),
                                ),
                              ),
                              const MenuFooter(),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSection(Section section) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionLabel(label: section.title),
        const SizedBox(height: AppDims.s2),
        SectionGrid(
          items: section.items,
          onPick: (_) {},
        ),
        const SizedBox(height: AppDims.s5),
      ],
    );
  }
}