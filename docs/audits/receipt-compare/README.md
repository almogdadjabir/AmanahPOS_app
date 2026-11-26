# Receipt comparison: desktop vs mobile

1. Desktop side: render each entry of `fixtures.json` (fields = the desktop `Receipt` record) with `ReceiptVisual.Build(receipt, new ReceiptSettings(null, 80, false, true, ""), loc)` in the English and Arabic cultures, 96 dpi, white background, and save as `desktop/<name>_<en|ar>_80.png` (width must be 302 px for 80 mm).
   Business time zone for the date: Africa/Khartoum (UTC+2), so `26 Nov 2026 · 14:05`.
2. Mobile side: the PNGs in `mobile/` are produced by `flutter test test/features/receipt/receipt_paper_golden_test.dart --update-goldens` (copied from `test/features/receipt/goldens/`).
3. Open `index.html` to compare side by side. Differences that are expected: Selawik replaces Segoe UI (same metrics) and Arabic uses IBM Plex Sans Arabic instead of Tahoma/Arial.
