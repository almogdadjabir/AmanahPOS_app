import 'package:amana_pos/common/auth_bloc/auth_bloc.dart';
import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/core/responsive/layout_metrics.dart';
import 'package:amana_pos/features/category/presentation/widgets/category_states.dart';
import 'package:amana_pos/features/devices/domain/entities/printer_device.dart';
import 'package:amana_pos/features/devices/domain/printer_error.dart';
import 'package:amana_pos/features/devices/presentation/bloc/printer_bloc.dart';
import 'package:amana_pos/features/devices/presentation/printer_l10n.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/theme/phosphor_icons.dart';
import 'package:amana_pos/utilities/global_snackbar.dart';
import 'package:amana_pos/widgets/app_form_group.dart';
import 'package:amana_pos/widgets/app_large_title.dart';
import 'package:amana_pos/widgets/app_sheet.dart';
import 'package:amana_pos/widgets/directional_icon.dart';
import 'package:amana_pos/widgets/pressable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:permission_handler/permission_handler.dart';

/// Settings → Receipt printer.
///
/// iOS Settings style page: the default printer is a card with its status and
/// two actions; nearby search and add-by-IP sit below it.
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
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom + 24;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: context.maxContentWidth),
            child: Column(
              children: [
                const _NavBar(),
                Expanded(
                  child: BlocConsumer<PrinterBloc, PrinterState>(
                    listenWhen: (p, c) => p.status != c.status,
                    listener: _onStateChanged,
                    builder: (context, state) => ListView(
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      padding: EdgeInsets.fromLTRB(
                        AppDims.s4,
                        0,
                        AppDims.s4,
                        bottomInset,
                      ),
                      children: [
                        AppLargeTitle(title: context.tr.printerScreenTitle),
                        _Body(state: state),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavBar extends StatelessWidget {
  const _NavBar();

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return SizedBox(
      height: 44,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: [
            Pressable(
              onTap: () => Navigator.of(context).maybePop(),
              child: SizedBox(
                height: 44,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(width: 4),
                    DirectionalIcon(
                      icon: PhosphorIconsRegular.caretLeft,
                      size: 24,
                      color: colors.primary,
                    ),
                    Text(
                      context.tr.back,
                      style: TextStyle(
                        fontSize: 17,
                        height: 1.3,
                        color: colors.primary,
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

bool _isPermissionError(PrinterError? e) =>
    e == PrinterError.bluetoothOff || e == PrinterError.permissionDenied;

// ── Body ─────────────────────────────────────────────────────────────────────

class _Body extends StatelessWidget {
  final PrinterState state;

  const _Body({required this.state});

  Future<void> _addByIp(BuildContext context) async {
    final bloc = context.read<PrinterBloc>();
    final tr = context.tr;
    final device = await showAppSheet<PrinterDevice>(
      context,
      builder: (_) => const _NetworkPrinterSheet(),
    );
    if (device != null) {
      bloc.add(PrinterDeviceSelected(device));
      GlobalSnackBar.showSuccess(message: tr.printerSavedAsDefault);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    final error = state.error;
    final permError = _isPermissionError(error) && !state.isScanning;
    final otherError = error != null && !permError && !state.isScanning;
    final devices = state.availableDevices
        .where((d) => d != state.savedPrinter)
        .toList();
    final showEmpty =
        !state.hasSavedPrinter &&
        !state.isScanning &&
        devices.isEmpty &&
        !permError;

    final ipRow = _IconRow(
      icon: PhosphorIconsRegular.plus,
      tone: _BadgeTone.indigo,
      title: tr.prnAddByIp,
      titleColor: context.appColors.textPrimary,
      trailing: DirectionalIcon(
        icon: PhosphorIconsRegular.caretRight,
        size: 18,
        color: context.appColors.borderStrong,
      ),
      onTap: () => _addByIp(context),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (permError) ...[
          const SizedBox(height: 6),
          _Banner(
            icon: PhosphorIconsRegular.bluetooth,
            title: tr.prnBtOffTitle,
            body: tr.prnBtOffBody,
          ),
          AppFormGroup(
            children: [
              _ActionRow(
                label: tr.prnOpenSettings,
                onTap: () => openAppSettings(),
              ),
            ],
          ),
          if (state.hasSavedPrinter) ...[
            const SizedBox(height: 12),
            _SavedCard(state: state),
            const SizedBox(height: 22),
          ],
        ] else ...[
          if (otherError) ...[
            const SizedBox(height: 6),
            _Banner(
              icon: PhosphorIconsRegular.info,
              body: printerErrorMessage(context, error),
            ),
          ],
          if (state.hasSavedPrinter) ...[
            _SavedCard(state: state),
            const SizedBox(height: 22),
          ],
        ],
        if (showEmpty) ...[
          const SizedBox(height: 12),
          CategoryStateCard(
            icon: PhosphorIconsRegular.printer,
            title: tr.prnNoPrinterTitle,
            body: tr.prnNoPrinterBody,
            actionLabel: tr.prnSearchNearby,
            onAction: () =>
                context.read<PrinterBloc>().add(const PrinterScanRequested()),
          ),
          const SizedBox(height: 22),
          AppFormGroup(footer: tr.prnIpFoot, children: [ipRow]),
        ] else if (permError && !state.hasSavedPrinter) ...[
          const SizedBox(height: 22),
          AppFormGroup(footer: tr.prnIpFoot, children: [ipRow]),
        ] else ...[
          AppFormGroup(
            header: tr.prnOther,
            footer: state.isScanning ? tr.prnNearFoot : tr.prnIpFoot,
            children: [
              if (!permError)
                _IconRow(
                  icon: PhosphorIconsRegular.magnifyingGlass,
                  tone: _BadgeTone.brand,
                  spinner: state.isScanning,
                  title: state.isScanning
                      ? tr.prnSearching
                      : tr.prnSearchNearby,
                  onTap: state.isScanning
                      ? null
                      : () => context.read<PrinterBloc>().add(
                          const PrinterScanRequested(),
                        ),
                ),
              for (final d in devices) _DeviceRow(device: d),
              ipRow,
            ],
          ),
        ],
      ],
    );
  }
}

// ── Saved printer card ───────────────────────────────────────────────────────

class _SavedCard extends StatelessWidget {
  final PrinterState state;

  const _SavedCard({required this.state});

  Future<void> _forget(BuildContext context) async {
    final tr = context.tr;
    final bloc = context.read<PrinterBloc>();
    final ok = await showAppConfirmSheet(
      context,
      title: tr.printerForgetConfirmTitle,
      message: tr.printerForgetConfirmBody,
      confirmLabel: tr.prnForget,
    );
    if (ok) bloc.add(const PrinterForgotten());
  }

  void _testPrint(BuildContext context) {
    final name =
        context.read<AuthBloc>().state.defaultBusiness?.name ?? 'AmanaPOS';
    context.read<PrinterBloc>().add(
      PrinterTestPrintRequested(businessName: name),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final tr = context.tr;
    final text = Theme.of(context).textTheme;
    final printer = state.savedPrinter!;
    final status = state.status;
    final connected = status.isConnected;
    final busy = status.isBusy;
    final statusColor = busy
        ? colors.warning
        : connected
        ? colors.success
        : colors.textHint;
    final statusLabel = busy
        ? status.label(context)
        : connected
        ? tr.printerStatusConnected
        : tr.printerStatusNotConnected;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: AppDims.borderLg,
        border: Border.all(color: colors.border),
      ),
      child: ClipRRect(
        borderRadius: AppDims.borderLg,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: connected
                          ? colors.primaryContainer
                          : colors.surfaceSoft,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      PhosphorIconsRegular.printer,
                      size: 28,
                      color: connected ? colors.primary : colors.textHint,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          printer.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: text.titleLarge!.copyWith(
                            fontSize: 19,
                            height: 1.3,
                            fontWeight: FontWeight.w600,
                            color: colors.textPrimary,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 1),
                          child: Directionality(
                            textDirection: TextDirection.ltr,
                            child: Align(
                              alignment: AlignmentDirectional.centerStart,
                              child: Text(
                                printer.displayAddress,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13,
                                  height: 1.3,
                                  color: colors.textHint,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 7,
                              height: 7,
                              decoration: BoxDecoration(
                                color: statusColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              statusLabel,
                              style: TextStyle(
                                fontSize: 13,
                                height: 1.3,
                                fontWeight: FontWeight.w600,
                                color: statusColor,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 0.5, thickness: 0.5, color: colors.border),
            if (connected)
              _ActionRow(
                label: tr.prnTestReceipt,
                icon: PhosphorIconsRegular.receipt,
                onTap: busy ? null : () => _testPrint(context),
              )
            else
              _ActionRow(
                label: tr.printerConnect,
                spinner: busy,
                onTap: busy
                    ? null
                    : () => context.read<PrinterBloc>().add(
                        const PrinterConnectRequested(),
                      ),
              ),
            Divider(
              height: 0.5,
              thickness: 0.5,
              indent: AppDims.s4,
              color: colors.border,
            ),
            _ActionRow(
              label: tr.prnForget,
              destructive: true,
              onTap: busy ? null : () => _forget(context),
            ),
          ],
        ),
      ),
    );
  }
}

/// Centered 50px row button (Test receipt / Connect / Forget / Open Settings).
class _ActionRow extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool destructive;
  final bool spinner;
  final VoidCallback? onTap;

  const _ActionRow({
    required this.label,
    required this.onTap,
    this.icon,
    this.destructive = false,
    this.spinner = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final color = destructive ? colors.danger : colors.primary;

    return Pressable(
      onTap: onTap,
      scale: 1,
      child: SizedBox(
        height: 50,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (spinner) ...[
              _Spinner(size: 18, color: color),
              const SizedBox(width: 8),
            ] else if (icon != null) ...[
              Icon(icon, size: 20, color: color),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 17,
                height: 1.3,
                fontWeight: FontWeight.w500,
                color: onTap == null && !spinner ? colors.disabled : color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Spinner extends StatelessWidget {
  final double size;
  final Color color;

  const _Spinner({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: 2.4,
        color: color,
        backgroundColor: context.appColors.surfaceSoft,
      ),
    );
  }
}

// ── Rows ─────────────────────────────────────────────────────────────────────

enum _BadgeTone { neutral, brand, indigo }

class _IconRow extends StatelessWidget {
  final IconData icon;
  final _BadgeTone tone;
  final String title;
  final Color? titleColor;
  final bool spinner;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _IconRow({
    required this.icon,
    required this.tone,
    required this.title,
    required this.onTap,
    this.titleColor,
    this.spinner = false,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final (bg, fg) = switch (tone) {
      _BadgeTone.neutral => (colors.surfaceSoft, colors.textSecondary),
      _BadgeTone.brand => (colors.primaryContainer, colors.primary),
      _BadgeTone.indigo => (colors.digitalTint, colors.digitalInk),
    };

    return Pressable(
      onTap: onTap,
      scale: 1,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 54),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppDims.s4),
          child: Row(
            children: [
              _Badge(
                bg: bg,
                child: spinner
                    ? _Spinner(size: 18, color: colors.primary)
                    : Icon(icon, size: 20, color: fg),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 17,
                    height: 1.3,
                    fontWeight: FontWeight.w500,
                    color: titleColor ?? colors.primary,
                  ),
                ),
              ),
              ?trailing,
            ],
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final Color bg;
  final Widget child;

  const _Badge({required this.bg, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: child,
    );
  }
}

class _DeviceRow extends StatelessWidget {
  final PrinterDevice device;

  const _DeviceRow({required this.device});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final tr = context.tr;
    final network = device.isNetwork;
    final tone = network ? _BadgeTone.indigo : _BadgeTone.neutral;
    final (bg, fg) = tone == _BadgeTone.indigo
        ? (colors.digitalTint, colors.digitalInk)
        : (colors.surfaceSoft, colors.textSecondary);

    return Pressable(
      onTap: () {
        context.read<PrinterBloc>().add(PrinterDeviceSelected(device));
        GlobalSnackBar.showSuccess(message: tr.printerSavedAsDefault);
      },
      scale: 1,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 64),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppDims.s4),
          child: Row(
            children: [
              _Badge(
                bg: bg,
                child: Icon(
                  network
                      ? PhosphorIconsRegular.wifiHigh
                      : PhosphorIconsRegular.bluetooth,
                  size: 20,
                  color: fg,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      device.name.isEmpty ? device.address : device.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 17,
                        height: 1.3,
                        color: colors.textPrimary,
                      ),
                    ),
                    Directionality(
                      textDirection: TextDirection.ltr,
                      child: Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: Text(
                          device.displayAddress,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.3,
                            color: colors.textHint,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                tr.printerConnect,
                style: TextStyle(
                  fontSize: 17,
                  height: 1.3,
                  fontWeight: FontWeight.w500,
                  color: colors.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Banner ───────────────────────────────────────────────────────────────────

class _Banner extends StatelessWidget {
  final IconData icon;
  final String? title;
  final String body;

  const _Banner({required this.icon, required this.body, this.title});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: colors.dangerContainer,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: title != null
            ? CrossAxisAlignment.center
            : CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22, color: colors.danger),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title != null)
                  Text(
                    title!,
                    style: TextStyle(
                      fontSize: 15,
                      height: 20 / 15,
                      fontWeight: FontWeight.w600,
                      color: colors.danger,
                    ),
                  ),
                Text(
                  body,
                  style: TextStyle(
                    fontSize: 15,
                    height: 20 / 15,
                    color: colors.danger,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Add by IP sheet ──────────────────────────────────────────────────────────

class _NetworkPrinterSheet extends StatefulWidget {
  const _NetworkPrinterSheet();

  @override
  State<_NetworkPrinterSheet> createState() => _NetworkPrinterSheetState();
}

class _NetworkPrinterSheetState extends State<_NetworkPrinterSheet> {
  static final _ipPattern = RegExp(
    r'^((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)\.){3}'
    r'(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)$',
  );

  final _nameController = TextEditingController();
  final _ipController = TextEditingController();
  final _portController = TextEditingController(
    text: '${PrinterDevice.defaultNetworkPort}',
  );

  @override
  void dispose() {
    _nameController.dispose();
    _ipController.dispose();
    _portController.dispose();
    super.dispose();
  }

  bool get _ipValid => _ipPattern.hasMatch(_ipController.text.trim());

  bool get _portValid {
    final port = int.tryParse(_portController.text.trim());
    return port != null && port > 0 && port <= 65535;
  }

  void _submit() {
    if (!_ipValid || !_portValid) return;
    final name = _nameController.text.trim();
    Navigator.of(context).pop(
      PrinterDevice(
        name: name.isEmpty ? context.tr.printerNetworkLabel : name,
        address: _ipController.text.trim(),
        type: PrinterConnectionType.network,
        port: int.parse(_portController.text.trim()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final tr = context.tr;

    return AppSheet(
      title: tr.prnNetworkTitle,
      leadingAction: AppSheetAction(
        label: tr.cancel,
        onTap: () => Navigator.of(context).pop(),
      ),
      trailingAction: AppSheetAction(
        label: tr.save,
        emphasized: true,
        onTap: _ipValid && _portValid ? _submit : null,
      ),
      child: AppFormGroup(
        footer: tr.prnIpFoot,
        children: [
          AppFormRow(
            label: tr.prnName,
            child: AppRowTextField(
              controller: _nameController,
              hint: tr.fmOptional,
              onChanged: (_) => setState(() {}),
            ),
          ),
          AppFormRow(
            child: Row(
              children: [
                ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: 104),
                  child: Text.rich(
                    TextSpan(
                      text: tr.printerIpAddress,
                      children: [
                        TextSpan(
                          text: '*',
                          style: TextStyle(color: colors.danger),
                        ),
                      ],
                    ),
                    maxLines: 1,
                    softWrap: false,
                    style: TextStyle(
                      fontSize: 17,
                      height: 1.3,
                      color: colors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: AppDims.s2),
                Expanded(
                  child: AppRowTextField(
                    controller: _ipController,
                    hint: '192.168.1.50',
                    numeric: true,
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ],
            ),
          ),
          AppFormRow(
            label: tr.printerPort,
            child: AppRowTextField(
              controller: _portController,
              numeric: true,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) => _submit(),
            ),
          ),
        ],
      ),
    );
  }
}
