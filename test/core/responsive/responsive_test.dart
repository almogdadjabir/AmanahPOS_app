// test/core/responsive/responsive_test.dart
import 'package:amana_pos/core/responsive/breakpoints.dart';
import 'package:amana_pos/core/responsive/layout_metrics.dart';
import 'package:amana_pos/core/responsive/responsive.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child, double width) => MediaQuery(
      data: MediaQueryData(size: Size(width, 800)),
      child: Directionality(textDirection: TextDirection.ltr, child: child),
    );

void main() {
  group('ResponsiveContext.deviceClass', () {
    testWidgets('returns mobile below 600', (tester) async {
      late DeviceClass result;
      await tester.pumpWidget(_wrap(
        Builder(builder: (ctx) { result = ctx.deviceClass; return const SizedBox(); }),
        390,
      ));
      expect(result, DeviceClass.mobile);
    });

    testWidgets('returns tablet at 768', (tester) async {
      late DeviceClass result;
      await tester.pumpWidget(_wrap(
        Builder(builder: (ctx) { result = ctx.deviceClass; return const SizedBox(); }),
        768,
      ));
      expect(result, DeviceClass.tablet);
    });

    testWidgets('returns desktop at 1024', (tester) async {
      late DeviceClass result;
      await tester.pumpWidget(_wrap(
        Builder(builder: (ctx) { result = ctx.deviceClass; return const SizedBox(); }),
        1024,
      ));
      expect(result, DeviceClass.desktop);
    });

    testWidgets('responsive() picks tablet value when provided', (tester) async {
      late String result;
      await tester.pumpWidget(_wrap(
        Builder(builder: (ctx) {
          result = ctx.responsive(mobile: 'mob', tablet: 'tab', desktop: 'desk');
          return const SizedBox();
        }),
        768,
      ));
      expect(result, 'tab');
    });

    testWidgets('responsive() falls back to desktop when tablet omitted', (tester) async {
      late String result;
      await tester.pumpWidget(_wrap(
        Builder(builder: (ctx) {
          result = ctx.responsive(mobile: 'mob', desktop: 'desk');
          return const SizedBox();
        }),
        768,
      ));
      expect(result, 'desk');
    });
  });

  group('LayoutMetrics.gridColumnsFor', () {
    testWidgets('clamps to minimum 2', (tester) async {
      late int result;
      await tester.pumpWidget(_wrap(
        Builder(builder: (ctx) {
          result = ctx.gridColumnsFor(300, tile: 200);
          return const SizedBox();
        }),
        1024,
      ));
      expect(result, 2); // floor(300/200)=1 → clamped to 2
    });

    testWidgets('returns 4 for 800px / 200px tile', (tester) async {
      late int result;
      await tester.pumpWidget(_wrap(
        Builder(builder: (ctx) {
          result = ctx.gridColumnsFor(800, tile: 200);
          return const SizedBox();
        }),
        1024,
      ));
      expect(result, 4);
    });
  });
}
