import 'package:amana_pos/features/business/data/models/responses/business_response_dto.dart';
import 'package:amana_pos/features/main_screen/presentation/widgets/location_chip.dart';
import 'package:amana_pos/l10n/app_localizations.dart';
import 'package:amana_pos/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _app(BusinessData b, String? shopId) => MaterialApp(
  theme: AppTheme.light,
  supportedLocales: AppLocalizations.supportedLocales,
  localizationsDelegates: const [
    AppLocalizations.delegate,
    ...GlobalMaterialLocalizations.delegates,
  ],
  home: Scaffold(body: LocationChip(business: b, selectedShopId: shopId)),
);

BusinessData _biz(List<String> shops) => BusinessData(
  name: 'Amana Shop',
  shopCount: shops.length,
  shops: [
    for (var i = 0; i < shops.length; i++)
      ShopData(id: 's$i', name: shops[i], isActive: true),
  ],
);

void main() {
  testWidgets('one branch: only the business name, never "Main Branch"', (
    t,
  ) async {
    await t.pumpWidget(_app(_biz(['Main Branch']), 's0'));
    expect(find.text('Amana Shop'), findsOneWidget);
    expect(find.text('Main Branch'), findsNothing);
  });

  testWidgets('several branches: only the branch name', (t) async {
    await t.pumpWidget(_app(_biz(['Main Branch', 'Omdurman']), 's1'));
    expect(find.text('Omdurman'), findsOneWidget);
    expect(find.text('Amana Shop'), findsNothing);
  });
}
