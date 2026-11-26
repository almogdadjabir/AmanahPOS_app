# Phase 1: One receipt, drawn once, used everywhere Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans (native, this session). Steps use checkbox syntax.

**Goal:** Mobile prints, previews, shares as image and shares as PDF the same receipt as the desktop (`ReceiptVisual.cs`).

**Architecture:** One plain-data `ReceiptDoc` built from the local sale; one `ReceiptPaper` Flutter widget (port of `ReceiptVisual.Build`) drawn at roll width. Image share, PDF share and thermal print all use the PNG rendered from that widget. Old A4 PDF, text share and ESC/POS text receipt are removed (text ESC/POS stays only as a fallback).

**Tech Stack:** Flutter, `share_plus`, `pdf`, `printing`, `print_bluetooth_thermal` (existing). New font asset: Selawik.

**Spec:** `docs/superpowers/plans/2026-11-26-mobile-parity-phases.md` (Phase 1 detail) and desktop `src/AmanaPOS.Presentation/Features/Receipts/ReceiptVisual.cs`.

## Global Constraints

- Paper width: 80 mm = 302.36 px, 58 mm = 219.21 px (mm * 96 / 25.4); paper settings value 58 or 80, anything else = 80.
- Padding left/right 12, top 16, bottom 20. Base font size 12, ink `#111111`, grey `#555555`, white paper in every theme.
- Sizes: business name 17 bold; phone 11 grey; rows 12; line detail 11 grey; Total row 15 bold; status 11 bold in a 1 px black box radius 3, padding 10x1; not-synced 10.5 grey; footer 11 grey; powered-by 10 grey.
- Dashed rule: grey, 1 px, dash 3/3, margin 6 top and bottom.
- Numbers always LTR with Latin digits. Amount `#,##0.00`; quantity `#,##0.###`. Date `dd MMM yyyy · HH:mm` in business time, Latin digits, English month names in both languages (as desktop).
- Footer = owner footer text (max 80) or the localized "Thank you"; then `Powered by AmanaPOS`.
- Never use `PdfGoogleFonts`. Everything works offline.
- No text is attached when sharing; image or PDF file only.
- Git: the owner commits. Do not run git add/commit.

## Review Focus

- A sale with no tax, no discount, one line: no Subtotal/Discount/Tax rows (desktop shows the breakdown only when discount or tax > 0).
- Fractional quantity 1.5 prints `1.5`, not `2`.
- Arabic business name with Latin phone: phone stays LTR.
- Sale on account and split sale with a credit part: part rows without "Paid", "Owes now" row only when a balance is known.
- Refunded sale: `Refund · <method>` rows with `− amount`, status box text changes.
- Rejected refunds are not shown (desktop: refunds the server rejected never happened).
- Sale not synced: not-synced note appears.
- Very long item name wraps; 58 mm paper does not overflow.
- Missing logo / empty business name: header skips them without gaps.

## File structure

- Create `lib/features/receipt/domain/receipt_doc.dart` — plain data (`ReceiptDoc`, `ReceiptDocLine`, `ReceiptDocPayment`, `ReceiptDocRefund`, `ReceiptSettings`).
- Create `lib/features/receipt/domain/receipt_doc_builder.dart` — `ReceiptDoc` from `SaleHistoryItem` + business info + settings.
- Create `lib/features/receipt/data/receipt_context_loader.dart` — loads business name/phone/logo/settings, cashier and customer names for a sale from the local DB.
- Create `lib/features/receipt/presentation/receipt_format.dart` — number/date/tax label helpers.
- Create `lib/features/receipt/presentation/receipt_paper.dart` — the widget.
- Create `lib/features/receipt/services/receipt_export.dart` — widget to PNG, PNG to roll PDF, share image, share PDF.
- Create `lib/features/receipt/services/receipt_raster_encoder.dart` — PNG to ESC/POS raster bytes.
- Create `lib/features/receipt/presentation/receipt_view_sheet.dart` — screen showing the paper with Share image / Share PDF / Print.
- Modify `lib/features/sales_history/data/models/sale_history_item.dart` and `.../local/local_sales_history.dart` — line discount, payment parts, tax name, refund method, cashier, customer.
- Modify `lib/features/pos/presentation/widgets/sale_receipt_sheet.dart`, `lib/features/cart/presentation/expanded_cart.dart`, `lib/features/sales_history/presentation/sale_detail_screen.dart` — use the new view.
- Modify `lib/features/devices/domain/usecases/printer_usecase.dart`, printer bloc — `printReceiptImage`.
- Delete `lib/features/sales_history/services/sale_receipt_pdf_service.dart`.
- Modify `pubspec.yaml`, `lib/l10n/app_en.arb`, `app_ar.arb`; add `assets/fonts/Selawik-*.ttf`, `OFL-selawik.txt`.
- Tests under `test/features/receipt/`.

---

### Task 1: Receipt data (`ReceiptDoc`) and the sale data it needs

**Files:** create `receipt_doc.dart`, `receipt_doc_builder.dart`; modify `sale_history_item.dart`, `local_sales_history.dart`; test `test/features/receipt/receipt_doc_builder_test.dart`.

**Interfaces:**
- Produces: `class ReceiptDoc { String businessName, phone; Uint8List? logo; String currency, number; DateTime at; String status; List<ReceiptDocLine> lines; double subtotal, discount, tax, net; String paymentMethod; List<ReceiptDocPayment> payments; List<ReceiptDocRefund> refunds; bool isSynced; String? customerName; double? customerOwes; String? cashierName; String taxName; double taxRate; bool taxInclusive; double get refunded; }`
- `ReceiptDocLine(name, quantity, unitPrice, total, returned, discount)`, `ReceiptDocPayment(method, amount)`, `ReceiptDocRefund(at, method, total)`.
- `class ReceiptSettings { int paperMm; bool showLogo; String footer; }` with `ReceiptSettings.defaults` = 80, true, `''` and `static int normalizePaper(int)`.
- `ReceiptDoc buildReceiptDoc(SaleHistoryItem sale, {required ReceiptBusiness business, required ReceiptSettings settings, double? customerOwes})` and `class ReceiptBusiness { String name, phone, currency; Uint8List? logo; }`.
- `SaleHistoryLineItem` gains `double discount`; `SaleHistoryItem` gains `List<SaleHistoryPayment> payments` (`method`, `amount`) and `String taxName`; `SaleHistoryRefund` gains `String method`.

- [ ] **Step 1: Test** `buildReceiptDoc` (names: `plain sale has no breakdown inputs`, `fractional quantity is kept`, `rejected refunds are dropped`, `payments parts are copied`, `isSynced false when offline pending`). Assert `doc.lines.single.quantity == 1.5`, `doc.refunds` empty when the only refund `isRejected`, `doc.payments.length == 2`, `doc.isSynced == false`.
- [ ] **Step 2:** Run `flutter test test/features/receipt/receipt_doc_builder_test.dart`; expected FAIL (files missing).
- [ ] **Step 3:** Implement the data classes and `buildReceiptDoc`; `subtotal` = sum of line totals + sum of line discounts is NOT used: `subtotal = sale.items.fold(subtotal)` equals the sale's stored `subtotal` when available. Add `subtotal` field to `SaleHistoryItem` (stored column `subtotal`), fall back to sum of line `subtotal` when 0.
- [ ] **Step 4:** Extend `SaleHistoryItem`/`SaleHistoryLineItem`/`SaleHistoryRefund` (defaults keep every existing constructor call compiling; update `copyWith`). In `LocalSalesHistory._item`: read `sale_items.discount`, `sale_payments` rows (add `_payments(db, ids)` like `_lines`), `tax_name`, `sale_refunds.method`/`refund` rows' method column where present, `cashier_id` resolved later by the loader. Check the refund table used by local refunds (search `sale_refunds`, `refunds` table creation in `sale_local_store` / refund store) and take its `method`.
- [ ] **Step 5:** Run the new test and `flutter test test/features/sales_history`; expected PASS.

### Task 2: Strings, fonts, settings loader

**Files:** modify `pubspec.yaml`, `app_en.arb`, `app_ar.arb`; add Selawik files; create `receipt_context_loader.dart`; test `receipt_context_loader_test.dart`.

**Interfaces:**
- Produces: `class ReceiptContextLoader { ReceiptContextLoader(OfflineDb db); Future<ReceiptContext> load(SaleHistoryItem sale); }` with `ReceiptContext { ReceiptBusiness business; ReceiptSettings settings; String? cashierName; String? customerName; double? customerOwes; }`.
- ARB keys (same wording as desktop resources): `receiptNumber`, `receiptDate`, `receiptCashier`, `receiptCustomer`, `receiptSubtotal`, `receiptDiscount`, `receiptTax`, `receiptTaxNamed` (`Tax ({name} {rate}%)`), `receiptTaxRated` (`Tax ({rate}%)`), `receiptTaxInclNamed` (`Incl. {name} {rate}%`), `receiptTaxInclRated` (`Incl. {rate}%`), `receiptTotal`, `receiptPaid`, `receiptRefund`, `receiptOwesNow`, `receiptLineDiscount` (`Discount {amount}`), `receiptReturnedQty` (`Returned {qty}`), `receiptNotSynced`, `receiptThanks`, `receiptStatusCompleted|Refunded|PartialRefund|Cancelled|Pending|Failed`, `receiptPayCash|Bankak|Card|Split|Credit`. Copy exact English/Arabic text from the desktop `Receipt_*` and `Sales_Pay_*` resource entries.

- [ ] **Step 1:** Download Selawik Regular, Semibold/Bold (SIL OFL, `github.com/microsoft/Selawik`) to `assets/fonts/`, add `OFL-selawik.txt`, declare family `Selawik` weights 400 and 700 in `pubspec.yaml`. If download is not possible, stop and report; do not substitute silently.
- [ ] **Step 2:** Add ARB keys (both languages); run `flutter gen-l10n`; expected no errors.
- [ ] **Step 3: Test** loader: with a stored business row JSON `{name, phone, currency, receipt_footer, receipt_paper_width: 58, logo_url...}` expect `settings.paperMm == 58`, `footer` trimmed to 80 chars; with no row expect `ReceiptSettings.defaults`.
- [ ] **Step 4:** Implement the loader: business row from `businesses.json` (`name`, `phone`, `currency`), settings from `synced_entities` business feed row keys `receipt_footer`, `receipt_paper_width`, and logo flag (`receipt_show_logo` when present, else true); cashier name from the users table by `cashier_id`; customer name and balance from `customers` (balance only if the column exists, else null); logo bytes from the cached asset for `logo_url` if present in `synced_assets`, else null.
- [ ] **Step 5:** Run test; PASS.

### Task 3: `ReceiptPaper` widget (port of `ReceiptVisual.Build`)

**Files:** create `receipt_format.dart`, `receipt_paper.dart`; tests `receipt_format_test.dart`, `receipt_paper_golden_test.dart`.

**Interfaces:**
- Produces: `class ReceiptPaper extends StatelessWidget { const ReceiptPaper({required ReceiptDoc doc, required ReceiptSettings settings, required AppLocalizations l, required bool isRtl}); static double widthFor(int paperMm); }` and in `receipt_format.dart`: `String receiptAmount(double)`, `String receiptQty(double)`, `String receiptWhen(DateTime utc, String timezone)`, `String receiptTaxLabel(ReceiptDoc, AppLocalizations)`.

- [ ] **Step 1: Tests** for format: `receiptAmount(1234.5) == '1,234.50'`, `receiptQty(1.5) == '1.5'`, `receiptQty(2) == '2'`, `receiptTaxLabel` returns `Tax (VAT 15%)` for added tax with name, `Incl. 15%` for inclusive without name, `Tax` when rate 0; rate printed with `0.##` and wrapped in LRI/PDI (U+2066/U+2069) like desktop.
- [ ] **Step 2:** Run; FAIL. Implement `receipt_format.dart`; run; PASS.
- [ ] **Step 3:** Implement `ReceiptPaper` in the order of desktop `Build`: header (logo 44x44 if `settings.showLogo` and bytes, name, phone LTR), rule, meta (number, date, cashier if any, customer if any), rule, lines, rule, totals, payments, refunds, rule, footer. Row = label `Expanded` (ellipsis, or wrap for line names) + value LTR; label side margin 8. Use `Directionality` from `isRtl`; wrap numbers in `Directionality(ltr)`. Font family `Selawik` for Latin, fallback `IBMPlexSansArabic`. Logic copied from `AddLines`, `AddTotals`, `AddPayments`, `AddRefunds`, `AddFooter` (credit parts have no "Paid ·"; Owes-now row only when `customerOwes != null` and a credit part exists; status text from ARB, fallback to raw status).
- [ ] **Step 4: Golden tests** (`matchesGoldenFile`) for fixtures: plain, discount+tax added, tax inclusive, split with credit, refunded, not synced, long names; English 80 mm, Arabic 80 mm, English 58 mm. Generate with `flutter test --update-goldens`, then view the PNGs (Read tool) and check them against the desktop layout before accepting.
- [ ] **Step 5:** Run `flutter test test/features/receipt`; PASS.

### Task 4: Export: PNG, image share, PDF share

**Files:** create `receipt_export.dart`; test `receipt_export_test.dart`.

**Interfaces:**
- Produces: `Future<Uint8List> renderReceiptPng(GlobalKey boundaryKey, {double pixelRatio = 3})`; `Uint8List receiptPdfFromPng(Uint8List png, {required double widthPx, required double heightPx})` (page = roll width in points: `widthPx * 72 / 96`, height from content, margin 0, image fills the page); `Future<void> shareReceiptImage(Uint8List png, {required String fileName, required Rect origin})` (file only, no `text`); `Future<void> shareReceiptPdf(Uint8List pdf, {required String fileName, required Rect origin})` (file only).

- [ ] **Step 1: Test** `receiptPdfFromPng`: build a 3x3 PNG, expect output starts with `%PDF`, and parsing page size via `pdf` document is not required; assert byte length > 0 and that `shareReceiptPdf` is not called in the test (pure function only).
- [ ] **Step 2:** Run; FAIL. Implement (copy the `RepaintBoundary.toImage` approach of Baraka `lib/utilities/sharing_utils.dart`: wait one frame, `toImage(pixelRatio: 3)`, `toByteData(png)`, white background). File names `receipt_<number>.png|pdf` sanitised like Baraka `_sanitizeFileName`. Files written to `getTemporaryDirectory()`.
- [ ] **Step 3:** Run; PASS.

### Task 5: Receipt view, wired into sale-complete and sale detail

**Files:** create `receipt_view_sheet.dart`; modify `sale_receipt_sheet.dart`, `expanded_cart.dart`, `sale_detail_screen.dart`; delete `sale_receipt_pdf_service.dart`; test `receipt_view_sheet_test.dart` (widget test).

**Interfaces:**
- Produces: `class ReceiptViewSheet { static Future<void> show(BuildContext, {required String saleId}); }` — loads the sale (`LocalSalesHistory.byId`) and context (`ReceiptContextLoader`), shows `ReceiptPaper` in a scrollable white card, buttons: Share image, Share PDF, Print (if printer saved, else Set up printer), New sale (on the sale-complete path).

- [ ] **Step 1: Test:** pump the sheet with a fake loader; expect `ReceiptPaper` is found, two share buttons found, and no widget with a `Text` containing `Share text`.
- [ ] **Step 2:** Run; FAIL. Implement the sheet; the POS completion path calls it with `state.lastClientSaleId`; sale detail "share" icon opens the same sheet. Remove `_buildReceiptText`, `_shareWhatsApp`, `_shareGeneral` and the `ReceiptData` builder from `sale_receipt_sheet.dart` (keep the success mark and offline banner); remove imports of the deleted PDF service.
- [ ] **Step 3:** Run `flutter analyze` on touched files (0 new issues) and `flutter test test/features`; PASS.

### Task 6: Thermal print as an image

**Files:** create `receipt_raster_encoder.dart`; modify `printer_usecase.dart`, `printer_bloc.dart` (event `PrinterReceiptImagePrintRequested(Uint8List png, int paperMm)`); tests `receipt_raster_encoder_test.dart`.

**Interfaces:**
- Produces: `List<int> encodeReceiptRaster(Uint8List png, {required int paperMm})` — decode PNG, scale to printer dots (80 mm = 576 dots, 58 mm = 384 dots), threshold to 1 bit, emit `GS v 0` raster (`1D 76 30 00 xL xH yL yH data`) in strips of at most 255 rows, then feed 3 and cut (`1D 56 42 00`). `PrinterUseCase.printReceiptImage(Uint8List png, int paperMm)`.

- [ ] **Step 1: Test:** a 16x8 all-black PNG at `paperMm: 58` produces bytes starting `1B 40` (init) then `1D 76 30 00`, width bytes = 48 (384/8), and ends with the cut command; an all-white PNG has all data bytes `0x00`.
- [ ] **Step 2:** Run; FAIL. Implement using `package:image` (add dependency if absent) for decode/resize; black pixel = bit 1.
- [ ] **Step 3:** Run; PASS. The Print button in the view sheet renders the PNG and calls `printReceiptImage`; on `PrinterException` of kind unsupported it falls back to the existing text `printReceipt(ReceiptData)` (keep `ReceiptData` for that fallback, English labels replaced by localized ones).

### Task 7: Desktop comparison

**Files:** docs `docs/audits/receipt-compare/` (fixtures JSON + instructions); test `receipt_fixtures_test.dart`.

- [ ] **Step 1:** Put the golden fixtures as JSON in `docs/audits/receipt-compare/fixtures/*.json` in the desktop `Receipt` field names, so the desktop test project can render the same data.
- [ ] **Step 2:** Render the mobile PNGs for each fixture to `docs/audits/receipt-compare/mobile/`.
- [ ] **Step 3:** Ask the owner for the desktop PNGs from the same fixtures (or an instruction for the desktop agent), build an HTML side-by-side page, and get the owner's sign-off. Do not claim the match before that.

---

## Self-review

- Spec coverage: one widget (T3), image share without text (T4/T5), PDF as image on roll page (T4), thermal image + text fallback (T6), offline fonts (T2/T4), hard-coded English removed (T2/T5), desktop comparison (T7), receipt settings read from business row (T2).
- Open assumption to verify while building T2: the business feed row stored in `synced_entities` carries `receipt_footer`, `receipt_paper_width` and `logo_url`; if `receipt_show_logo` is missing it is treated as true (BE_GAPS_PARITY G4).
