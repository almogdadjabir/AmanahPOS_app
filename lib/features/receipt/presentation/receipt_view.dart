import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/config/router/route_strings.dart';
import 'package:amana_pos/core/offline/offline_db.dart';
import 'package:amana_pos/features/devices/presentation/bloc/printer_bloc.dart';
import 'package:amana_pos/features/devices/presentation/printer_l10n.dart';
import 'package:amana_pos/features/receipt/data/receipt_context_loader.dart';
import 'package:amana_pos/features/receipt/domain/receipt_doc.dart';
import 'package:amana_pos/features/receipt/domain/receipt_doc_builder.dart';
import 'package:amana_pos/features/receipt/presentation/receipt_paper.dart';
import 'package:amana_pos/features/receipt/services/receipt_export.dart';
import 'package:amana_pos/features/receipt/services/receipt_raster_encoder.dart';
import 'package:amana_pos/features/sales_history/data/local/local_sales_history.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/theme/phosphor_icons.dart';
import 'package:amana_pos/utilities/dependencies_provider.dart';
import 'package:amana_pos/utilities/global_snackbar.dart';
import 'package:amana_pos/widgets/app_group.dart';
import 'package:amana_pos/widgets/app_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The receipt of one sale: the paper exactly as it prints, and what to do
/// with it (print, share as image, share as PDF). The same paper is used for
/// the screen, the image, the PDF and the thermal printer.
class ReceiptView extends StatefulWidget {
  const ReceiptView({super.key, required this.saleId, this.showPaper = true});

  final String saleId;

  /// False on the sale-complete sheet: the receipt is not shown there (it
  /// would crowd the sheet); the buttons still print and share it.
  final bool showPaper;

  @override
  State<ReceiptView> createState() => _ReceiptViewState();
}

class _ReceiptViewState extends State<ReceiptView> {
  late final Future<(ReceiptDoc, ReceiptSettings)?> _load = _loadDoc();
  bool _busy = false;
  ReceiptSettings _settings = ReceiptSettings.defaults;

  Future<(ReceiptDoc, ReceiptSettings)?> _loadDoc() async {
    final db = getIt<OfflineDb>();
    final sale = await LocalSalesHistory(db: db).byId(widget.saleId);
    if (sale == null) return null;
    final ctx = await ReceiptContextLoader(db).load(sale);
    final doc = buildReceiptDoc(
      sale,
      business: ctx.business,
      cashierName: ctx.cashierName,
      customerName: ctx.customerName,
      customerOwes: ctx.customerOwes,
    );
    return (doc, ctx.settings);
  }

  /// The paper drawn off screen, as a picture.
  Future<RenderedReceipt> _render(ReceiptDoc doc) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return renderReceiptWidgetPng(
      context,
      ReceiptPaper(doc: doc, settings: _settings, l: context.tr, isRtl: rtl),
      width: ReceiptPaper.widthFor(_settings.paperMm),
    );
  }

  Rect? _origin() {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return null;
    return box.localToGlobal(Offset.zero) & box.size;
  }

  Future<void> _run(Future<void> Function() job) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await job();
    } catch (e, st) {
      debugPrint('Receipt action failed: $e\n$st');
      if (mounted) {
        GlobalSnackBar.showError(message: context.tr.shReceiptFailed);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _shareImage(ReceiptDoc doc) => _run(() async {
    final origin = _origin();
    final r = await _render(doc);
    await shareReceiptImage(r.png, number: doc.number, origin: origin);
  });

  Future<void> _sharePdf(ReceiptDoc doc) => _run(() async {
    final origin = _origin();
    final r = await _render(doc);
    final pdf = await buildReceiptPdf(
      r.png,
      widthPx: r.width,
      heightPx: r.height,
    );
    await shareReceiptPdf(pdf, number: doc.number, origin: origin);
  });

  Future<void> _print(ReceiptDoc doc) => _run(() async {
    final r = await _render(doc);
    final bytes = await encodeReceiptRaster(r.png, paperMm: _settings.paperMm);
    if (!mounted) return;
    context.read<PrinterBloc>().add(PrinterRawPrintRequested(bytes));
  });

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    final colors = context.appColors;
    final rtl = Directionality.of(context) == TextDirection.rtl;

    return FutureBuilder<(ReceiptDoc, ReceiptSettings)?>(
      future: _load,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Padding(
            padding: EdgeInsets.all(AppDims.s6),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final data = snap.data;
        if (data == null) {
          return Padding(
            padding: const EdgeInsets.all(AppDims.s6),
            child: Center(child: Text(tr.rcLoadFailed)),
          );
        }
        final (doc, settings) = data;
        _settings = settings;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.showPaper) ...[
              Center(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border.all(color: colors.border),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x14000000),
                        blurRadius: 12,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ReceiptPaper(
                    doc: doc,
                    settings: settings,
                    l: tr,
                    isRtl: rtl,
                  ),
                ),
              ),
              const SizedBox(height: AppDims.s5),
            ],
            AppGroup(
              children: [
                _PrintRow(onPrint: _busy ? null : () => _print(doc)),
                AppGroupRow(
                  title: tr.rcShareImage,
                  icon: PhosphorIconsRegular.export,
                  tint: AppTint.success,
                  onTap: _busy ? null : () => _shareImage(doc),
                ),
                AppGroupRow(
                  title: tr.rcSharePdf,
                  icon: PhosphorIconsRegular.export,
                  tint: AppTint.neutral,
                  onTap: _busy ? null : () => _sharePdf(doc),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _PrintRow extends StatelessWidget {
  const _PrintRow({required this.onPrint});

  final VoidCallback? onPrint;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return BlocConsumer<PrinterBloc, PrinterState>(
      listenWhen: (a, b) => a.status != b.status,
      listener: (context, state) {
        switch (state.status) {
          case PrinterStatus.printSuccess:
            GlobalSnackBar.showSuccess(
              message: context.tr.printerStatusPrintSuccess,
            );
          case PrinterStatus.printFailed:
          case PrinterStatus.connectionFailed:
            final error = state.error;
            if (error != null) {
              GlobalSnackBar.showError(
                message: printerErrorMessage(context, error),
              );
            }
          default:
            break;
        }
      },
      builder: (context, state) {
        if (!state.hasSavedPrinter) {
          return AppGroupRow(
            title: context.tr.printerSetUp,
            icon: PhosphorIconsRegular.printer,
            tint: AppTint.neutral,
            onTap: () => Navigator.of(
              context,
            ).pushNamed(RouteStrings.printerSettingsScreen),
          );
        }
        final isBusy = state.status.isBusy;
        return AppGroupRow(
          title: isBusy ? state.status.label(context) : context.tr.rcPrint,
          icon: PhosphorIconsRegular.printer,
          tint: AppTint.brand,
          showChevron: !isBusy,
          trailing: isBusy
              ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: colors.primary,
                  ),
                )
              : null,
          onTap: isBusy ? null : onPrint,
        );
      },
    );
  }
}

/// Opens the receipt of [saleId] in a sheet (sale detail, history).
Future<void> showReceiptSheet(BuildContext context, String saleId) {
  return showAppSheet<void>(
    context,
    builder: (ctx) => AppSheet(
      title: ctx.tr.receipt,
      maxHeightFactor: 0.94,
      keyboardSafe: false,
      child: ReceiptView(saleId: saleId),
    ),
  );
}
