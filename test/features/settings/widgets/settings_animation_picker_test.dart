// test/features/settings/widgets/settings_animation_picker_test.dart
import 'package:amana_pos/config/enum.dart';
import 'package:amana_pos/features/settings/presentation/widgets/settings_animation_picker.dart';
import 'package:amana_pos/l10n/app_localizations.dart';
import 'package:amana_pos/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('tapping an option invokes the callback', (tester) async {
    AnimationPreference? picked;

    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: SettingsAnimationPicker(
          selected: AnimationPreference.auto,
          onSelected: (p) => picked = p,
        ),
      ),
    ));
    await tester.pumpAndSettle();

    // Tap the "Always off" option.
    await tester.tap(find.text('Always off'));
    await tester.pump();

    expect(picked, AnimationPreference.alwaysOff);
  });
}
