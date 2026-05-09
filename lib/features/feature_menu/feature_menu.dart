import 'package:amana_pos/features/feature_menu/feature_menu_sections.dart';
import 'package:amana_pos/features/feature_menu/widgets/section_grid.dart';
import 'package:amana_pos/features/feature_menu/widgets/section_label.dart';
import 'package:amana_pos/features/main_screen/data/section.dart';
import 'package:amana_pos/features/main_screen/presentation/bloc/navigation_bloc.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
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

  void _closeMenu(BuildContext ctx) =>
      ctx.read<NavigationBloc>().add(const SetMenuOpenEvent(open: false));

  @override
  Widget build(BuildContext context) {
    final maxH = MediaQuery.sizeOf(context).height * 0.75;

    return BlocBuilder<NavigationBloc, NavigationState>(
      buildWhen: (prev, curr) =>
      prev.menuOpen != curr.menuOpen       ||
          prev.currentFeature != curr.currentFeature ||
          prev.permissions != curr.permissions,
      builder: (context, state) {
        final sections = buildMenuSections(context, state);
        final sectionWidgets = sections
            .map((s) => _buildSection(context, s))
            .toList();

        return IgnorePointer(
          ignoring: !state.menuOpen,
          child: Stack(
            children: [

              AnimatedOpacity(
                duration: AppDims.fast,
                opacity:  state.menuOpen ? 1.0 : 0.0,
                child: GestureDetector(
                  onTap:  () => _closeMenu(context),
                  child:  Container(
                      color: Colors.black.withValues(alpha: 0.40)),
                ),
              ),

              Positioned(
                bottom: 0, left: 0, right: 0,
                child: AnimatedSlide(
                  offset: state.menuOpen ? Offset.zero : const Offset(0, 1),
                  duration: const Duration(milliseconds: 380),
                  curve: Curves.easeOutCubic,
                  child: Material(
                    color: context.appColors.surface,
                    elevation: 0,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: SafeArea(
                      top: false,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxHeight: maxH),
                        child: Column(
                          mainAxisSize:       MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [

                            // ── Drag handle ────────────────────────────
                            Center(
                              child: Container(
                                width:  36, height: 4,
                                margin: const EdgeInsets.only(top: 12, bottom: 4),
                                decoration: BoxDecoration(
                                  color: context.appColors.border,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                              ),
                            ),

                            Flexible(
                              child: Scrollbar(
                                controller: _scrollController,
                                thumbVisibility: false,
                                child: SingleChildScrollView(
                                  controller: _scrollController,
                                  primary: false,
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.stretch,
                                    children: sectionWidgets,
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
            ],
          ),
        );
      },
    );
  }

  Widget _buildSection(BuildContext context, Section section) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionLabel(label: section.title),
        SectionGrid(
          items:  section.items,
          onPick: () => _closeMenu(context),
        ),
      ],
    );
  }
}
