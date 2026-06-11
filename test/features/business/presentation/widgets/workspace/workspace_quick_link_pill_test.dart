import 'package:amana_pos/features/business/presentation/widgets/workspace/workspace_quick_link_pill.dart';
import 'package:amana_pos/l10n/app_localizations.dart';
import 'package:amana_pos/theme/app_colors.dart';
import 'package:amana_pos/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:solar_icons/solar_icons.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(
        theme: AppTheme.light,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: child),
      );

  testWidgets('WorkspaceQuickLinkPill renders icon and label', (tester) async {
    await tester.pumpWidget(wrap(WorkspaceQuickLinkPill(
      icon: SolarIconsOutline.layersMinimalistic,
      label: 'Categories',
      accentColor: AppColors.primary,
      onTap: () {},
    )));
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Categories'), findsOneWidget);
    expect(find.byIcon(SolarIconsOutline.layersMinimalistic), findsOneWidget);
  });

  testWidgets('WorkspaceQuickLinkPill calls onTap when tapped', (tester) async {
    var tapped = false;
    await tester.pumpWidget(wrap(WorkspaceQuickLinkPill(
      icon: SolarIconsOutline.layersMinimalistic,
      label: 'Categories',
      accentColor: AppColors.primary,
      onTap: () => tapped = true,
    )));
    await tester.pump(const Duration(milliseconds: 400));

    await tester.tap(find.byType(WorkspaceQuickLinkPill));
    await tester.pump();

    expect(tapped, isTrue);
  });
}
