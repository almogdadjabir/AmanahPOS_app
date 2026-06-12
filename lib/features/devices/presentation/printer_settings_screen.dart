import 'package:amana_pos/common/auth_bloc/auth_bloc.dart';
import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/common/widgets/section_label.dart';
import 'package:amana_pos/core/responsive/layout_metrics.dart';
import 'package:amana_pos/features/devices/domain/entities/printer_device.dart';
import 'package:amana_pos/features/devices/presentation/bloc/printer_bloc.dart';
import 'package:amana_pos/features/devices/presentation/printer_l10n.dart';
import 'package:amana_pos/features/settings/presentation/widgets/settings_group_card.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/utilities/global_snackbar.dart';
import 'package:amana_pos/widgets/directional_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solar_icons/solar_icons.dart';

/// Settings → Devices → Add Printer.
///
/// Shows the saved default printer with live connection status and actions
/// (connect, test print, remove), plus a scan list to pick a new printer.
class PrinterSettingsScreen extends StatefulWidget {
  const PrinterSettingsScreen({super.key});

  @override
  State<PrinterSettingsScreen> createState() => _PrinterSettingsScreenState();
}

class _PrinterSettingsScreenState extends State<PrinterSettingsScreen> {
  @override
  void initState() {
    super.initState();
    context.read<PrinterBloc>().add(const PrinterScanRequested());
  }

  void _onStateChanged(BuildContext context, PrinterState state) {
    switch (state.status) {
      case PrinterStatus.printSuccess:
        GlobalSnackBar.showSuccess(message: context.tr.printerStatusPrintSuccess);
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
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final tr = context.tr;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        elevation: 0,
        leading: IconButton(
          icon: DirectionalIcon(
            icon: SolarIconsOutline.altArrowLeft,
            color: colors.textPrimary,
            size: 22,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          tr.printerScreenTitle,
          style: AppTextStyles.bs400(context).copyWith(
            color: colors.textPrimary,
            fontWeight: FontWeight.w900,
          ),
        ),
        centerTitle: false,
      ),
      body: BlocConsumer<PrinterBloc, PrinterState>(
        listenWhen: (previous, current) => previous.status != current.status,
        listener: _onStateChanged,
        builder: (context, state) {
          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: context.maxContentWidth),
              child: ListView(
                padding: const EdgeInsets.all(AppDims.s4),
                children: [
                  if (state.hasSavedPrinter) ...[
                    SectionLabel(label: tr.printerDefaultLabel),
                    const SizedBox(height: AppDims.s2),
                    _SavedPrinterCard(state: state),
                    const SizedBox(height: AppDims.s5),
                  ],
                  SectionLabel(label: tr.printerAvailable),
                  const SizedBox(height: AppDims.s2),
                  _ScanSection(state: state),
                  const SizedBox(height: AppDims.s6),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Saved printer ────────────────────────────────────────────────────────────

class _SavedPrinterCard extends StatelessWidget {
  final PrinterState state;

  const _SavedPrinterCard({required this.state});

  Future<void> _confirmForget(BuildContext context) async {
    final tr = context.tr;
    final colors = context.appColors;

    final shouldForget = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: colors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDims.rXl),
          side: BorderSide(color: colors.border),
        ),
        title: Text(
          tr.printerForgetConfirmTitle,
          style: AppTextStyles.bs500(context).copyWith(
            fontWeight: FontWeight.w900,
            color: colors.textPrimary,
          ),
        ),
        content: Text(
          tr.printerForgetConfirmBody,
          style: AppTextStyles.bs200(context).copyWith(
            color: colors.textSecondary,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: Text(tr.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: colors.danger,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(dialogCtx, true),
            child: Text(tr.printerForget),
          ),
        ],
      ),
    );

    if (shouldForget == true && context.mounted) {
      context.read<PrinterBloc>().add(const PrinterForgotten());
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final tr = context.tr;
    final printer = state.savedPrinter!;
    final status = state.status;
    final statusColor = status.color(context);
    final isBusy = status.isBusy;

    return Container(
      padding: const EdgeInsets.all(AppDims.s4),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppDims.rLg),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(SolarIconsOutline.printer,
                    color: statusColor, size: 24),
              ),
              const SizedBox(width: AppDims.s3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      printer.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bs400(context).copyWith(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      printer.address,
                      style: AppTextStyles.bs100(context).copyWith(
                        color: colors.textHint,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppDims.s2),
              _StatusChip(status: status),
            ],
          ),
          const SizedBox(height: AppDims.s4),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: isBusy
                      ? null
                      : () => context.read<PrinterBloc>().add(
                            status.isConnected
                                ? const PrinterDisconnectRequested()
                                : const PrinterConnectRequested(),
                          ),
                  icon: isBusy
                      ? SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: colors.textHint,
                          ),
                        )
                      : Icon(
                          status.isConnected
                              ? SolarIconsOutline.linkBroken
                              : SolarIconsOutline.link,
                          size: 16,
                        ),
                  label: Text(
                    status.isConnected ? tr.printerDisconnect : tr.printerConnect,
                  ),
                ),
              ),
              const SizedBox(width: AppDims.s2),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: isBusy
                      ? null
                      : () {
                          final businessName = context
                                  .read<AuthBloc>()
                                  .state
                                  .defaultBusiness
                                  ?.name ??
                              'AmanaPOS';
                          context.read<PrinterBloc>().add(
                                PrinterTestPrintRequested(
                                  businessName: businessName,
                                ),
                              );
                        },
                  icon: const Icon(SolarIconsOutline.documentText, size: 16),
                  label: Text(tr.printerTestPrint),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDims.s2),
          TextButton.icon(
            onPressed: isBusy ? null : () => _confirmForget(context),
            icon: Icon(SolarIconsOutline.trashBinTrash,
                size: 16, color: colors.danger),
            label: Text(
              tr.printerForget,
              style: AppTextStyles.bs200(context).copyWith(
                color: colors.danger,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final PrinterStatus status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = status.color(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDims.s2,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            status.label(context),
            style: AppTextStyles.sm100(context).copyWith(
              color: color,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Scan section ─────────────────────────────────────────────────────────────

class _ScanSection extends StatelessWidget {
  final PrinterState state;

  const _ScanSection({required this.state});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final tr = context.tr;

    final visibleDevices = state.availableDevices
        .where((d) => d != state.savedPrinter)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (state.error != null && !state.isScanning) ...[
          _ErrorBanner(message: printerErrorMessage(context, state.error!)),
          const SizedBox(height: AppDims.s3),
        ],
        if (visibleDevices.isNotEmpty) ...[
          SettingsGroupCard(
            items: [
              for (final device in visibleDevices)
                _DeviceTile(device: device),
            ],
          ),
          const SizedBox(height: AppDims.s3),
        ] else if (!state.isScanning && state.error == null) ...[
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDims.s2,
              vertical: AppDims.s2,
            ),
            child: Text(
              tr.printerNoDevicesFound,
              style: AppTextStyles.bs200(context).copyWith(
                color: colors.textSecondary,
              ),
            ),
          ),
        ],
        OutlinedButton.icon(
          onPressed: state.isScanning
              ? null
              : () => context
                  .read<PrinterBloc>()
                  .add(const PrinterScanRequested()),
          icon: state.isScanning
              ? SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: colors.textHint,
                  ),
                )
              : const Icon(SolarIconsOutline.refresh, size: 16),
          label: Text(state.isScanning ? tr.printerScanning : tr.printerScan),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
            side: BorderSide(color: colors.border),
          ),
        ),
        const SizedBox(height: AppDims.s3),
        Text(
          tr.printerScanHint,
          style: AppTextStyles.bs100(context).copyWith(
            color: colors.textHint,
            height: 1.45,
          ),
        ),
      ],
    );
  }
}

class _DeviceTile extends StatelessWidget {
  final PrinterDevice device;

  const _DeviceTile({required this.device});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final tr = context.tr;

    return InkWell(
      onTap: () {
        context.read<PrinterBloc>().add(PrinterDeviceSelected(device));
        GlobalSnackBar.showSuccess(message: tr.printerSavedAsDefault);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDims.s4,
          vertical: AppDims.s3,
        ),
        child: Row(
          children: [
            Icon(SolarIconsOutline.printer, color: colors.primary, size: 22),
            const SizedBox(width: AppDims.s3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    device.name.isEmpty ? device.address : device.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bs300(context).copyWith(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    device.address,
                    style: AppTextStyles.bs100(context).copyWith(
                      color: colors.textHint,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
            DirectionalIcon(
              icon: SolarIconsOutline.altArrowRight,
              size: 15,
              color: colors.textHint,
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;

  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
      padding: const EdgeInsets.all(AppDims.s3),
      decoration: BoxDecoration(
        color: colors.danger.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.danger.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, size: 18, color: colors.danger),
          const SizedBox(width: AppDims.s2),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.bs100(context).copyWith(
                color: colors.textPrimary,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
