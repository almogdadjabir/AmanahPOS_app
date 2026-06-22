import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:amana_pos/features/pin/presentation/widgets/pin_digits_field.dart';
import 'package:amana_pos/theme/app_theme.dart';

void main() {
  testWidgets('accepts only 4 digits', (tester) async {
    final controller = TextEditingController();
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(body: PinDigitsField(controller: controller)),
    ));
    await tester.enterText(find.byType(TextField), '12345678');
    expect(controller.text.length, 4);
    expect(controller.text, '1234');
  });
}
