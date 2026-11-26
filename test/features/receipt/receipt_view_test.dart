import 'package:amana_pos/core/offline/offline_db.dart';
import 'package:amana_pos/features/devices/presentation/bloc/printer_bloc.dart';
import 'package:amana_pos/features/receipt/presentation/receipt_paper.dart';
import 'package:amana_pos/features/receipt/domain/receipt_doc.dart';
import 'package:amana_pos/features/receipt/presentation/receipt_view.dart';
import 'package:amana_pos/features/receipt/services/receipt_export.dart';
import 'package:amana_pos/l10n/app_localizations.dart';
import 'package:amana_pos/l10n/app_localizations_en.dart';
import 'package:amana_pos/theme/app_theme.dart';
import 'package:amana_pos/utilities/dependencies_provider.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../core/sync/support/test_db.dart';

class _FakePrinterBloc extends MockBloc<PrinterEvent, PrinterState>
    implements PrinterBloc {}

void main() {
  for (final showPaper in [true, false]) {
    testWidgets('showPaper=$showPaper: three actions, no share-text action', (
      t,
    ) async {
      await t.runAsync(() async {
        final odb = await openTestDb();
        final db = await odb.database;
        if (getIt.isRegistered<OfflineDb>()) getIt.unregister<OfflineDb>();
        getIt.registerSingleton<OfflineDb>(odb);
        await db.insert('synced_entities', {
          'entity': 'business',
          'id': 'b1',
          'json': '{"name":"Al Noor","currency":"SDG"}',
        });
        await db.insert('sales', {
          'id': 's1',
          'shop_id': 'sh',
          'status': 'completed',
          'payment_method': 'cash',
          'subtotal': '10',
          'discount': '0',
          'tax_amount': '0',
          'net_amount': '10',
          'receipt_number': 'R-9',
          'occurred_at': '2026-11-26T12:05:00.000Z',
          'sync_state': 'synced',
        });
        await db.insert('sale_items', {
          'id': 'i1',
          'sale_id': 's1',
          'product_name': 'Sugar',
          'quantity': '1.5',
          'unit_price': '6.6667',
          'line_total': '10',
        });
      });

      final printer = _FakePrinterBloc();
      whenListen(
        printer,
        const Stream<PrinterState>.empty(),
        initialState: const PrinterState(),
      );
      await t.runAsync(
        () => t.pumpWidget(
          MaterialApp(
            theme: AppTheme.light,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: SingleChildScrollView(
                child: BlocProvider<PrinterBloc>.value(
                  value: printer,
                  child: ReceiptView(saleId: 's1', showPaper: showPaper),
                ),
              ),
            ),
          ),
        ),
      );
      await t.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 300)),
      );
      await t.pump();
      await t.pump();

      // The sale-complete sheet (showPaper false) never shows the receipt.
      expect(
        find.byType(ReceiptPaper),
        showPaper ? findsOneWidget : findsNothing,
      );
      expect(find.text('Share as image'), findsOneWidget);
      expect(find.text('Share as PDF'), findsOneWidget);
      expect(find.textContaining('WhatsApp'), findsNothing);
      if (showPaper) {
        expect(find.text('Al Noor'), findsOneWidget);
        expect(find.textContaining('1.5 ×'), findsOneWidget);
      }
    });
  }

  testWidgets('the receipt is drawn off screen into a PNG of the paper size', (
    t,
  ) async {
    late BuildContext ctx;
    await t.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (c) {
            ctx = c;
            return const SizedBox();
          },
        ),
      ),
    );
    final doc = ReceiptDoc(
      businessName: 'Al Noor',
      phone: '',
      currency: 'SDG',
      number: 'R1',
      at: DateTime.utc(2026),
      status: 'completed',
      lines: [
        for (var i = 0; i < 60; i++)
          ReceiptDocLine(name: 'Item $i', quantity: 1, unitPrice: 1, total: 1),
      ],
      subtotal: 60,
      discount: 0,
      tax: 0,
      net: 60,
      paymentMethod: 'cash',
      isSynced: true,
    );
    final width = ReceiptPaper.widthFor(80);
    final paper = ReceiptPaper(
      doc: doc,
      settings: ReceiptSettings.defaults,
      l: AppLocalizationsEn(),
      isRtl: false,
    );
    final r = await t.runAsync(() async {
      final f = renderReceiptWidgetPng(ctx, paper, width: width);
      await t.pump();
      await t.pump();
      return f;
    });
    expect(r!.width, closeTo(width, 0.01));
    // 60 lines is much taller than the 600 px test screen: height is free.
    expect(r.height, greaterThan(800));
    expect(String.fromCharCodes(r.png.sublist(1, 4)), 'PNG');
  });
}
