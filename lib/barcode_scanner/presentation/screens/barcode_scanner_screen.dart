import 'dart:async';

import 'package:amana_pos/barcode_scanner/presentation/widgets/camera_scanner_view.dart';
import 'package:amana_pos/barcode_scanner/presentation/widgets/permission_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../bloc/barcode_scanner_bloc.dart';

class BarcodeScannerScreen extends StatefulWidget {
  const BarcodeScannerScreen({super.key});

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  late final MobileScannerController _controller;
  late final AnimationController _animationController;
  late final Animation<double> _scanLineAnimation;

  String? _lastCode;
  DateTime? _lastScanAt;

  static const Duration _scanThrottle = Duration(milliseconds: 900);

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    _controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
      torchEnabled: false,
      formats: const [
        BarcodeFormat.ean13,
        BarcodeFormat.ean8,
        BarcodeFormat.upcA,
        BarcodeFormat.upcE,
        BarcodeFormat.code128,
        BarcodeFormat.code39,
        BarcodeFormat.code93,
        BarcodeFormat.itf,
        BarcodeFormat.qrCode,
      ],
    );

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _scanLineAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOutCubic,
      ),
    );

    context.read<BarcodeScannerBloc>().add(const BarcodeScannerStarted());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _animationController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final bloc = context.read<BarcodeScannerBloc>();

    if (state == AppLifecycleState.resumed) {
      bloc.add(const BarcodeScannerPermissionRefreshed());
      unawaited(_controller.start());
      return;
    }

    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      bloc.add(const BarcodeScannerPaused());
      unawaited(_controller.stop());
    }
  }

  bool _shouldAcceptCode(String code) {
    final now = DateTime.now();

    if (_lastCode == code &&
        _lastScanAt != null &&
        now.difference(_lastScanAt!) < _scanThrottle) {
      return false;
    }

    _lastCode = code;
    _lastScanAt = now;
    return true;
  }

  void _onDetect(BarcodeCapture capture) {
    final code = capture.barcodes
        .map((barcode) => barcode.rawValue)
        .whereType<String>()
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .firstOrNull;

    if (code == null) return;
    if (!_shouldAcceptCode(code)) return;

    context.read<BarcodeScannerBloc>().add(
      BarcodeScannerCodeDetected(code),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<BarcodeScannerBloc, BarcodeScannerState>(
      listenWhen: (previous, current) {
        return previous.scannedCode != current.scannedCode &&
            current.scannedCode != null;
      },
      listener: (context, state) {
        Navigator.of(context).pop(state.scannedCode);
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: Colors.black,
          body: SafeArea(
            top: false,
            bottom: false,
            child: _buildBody(state),
          ),
        );
      },
    );
  }

  Widget _buildBody(BarcodeScannerState state) {
    switch (state.status) {
      case BarcodeScannerStatus.initial:
      case BarcodeScannerStatus.checkingPermission:
        return const _LoadingView();

      case BarcodeScannerStatus.permissionDenied:
        return PermissionView(
          title: 'Camera permission needed',
          message: state.errorMessage ??
              'Please allow camera permission to scan product barcodes.',
          buttonText: 'Allow Camera',
          secondaryButtonText: 'Close',
          onPressed: () {
            context.read<BarcodeScannerBloc>().add(
              const BarcodeScannerPermissionRequested(),
            );
          },
          onSecondaryPressed: () => Navigator.of(context).pop(),
        );

      case BarcodeScannerStatus.permissionPermanentlyDenied:
        return PermissionView(
          title: 'Camera permission disabled',
          message: state.errorMessage ??
              'Open settings and enable camera permission for AmanaPOS.',
          buttonText: 'Open Settings',
          secondaryButtonText: 'Close',
          onPressed: () {
            context.read<BarcodeScannerBloc>().add(
              const BarcodeScannerOpenSettingsRequested(),
            );
          },
          onSecondaryPressed: () => Navigator.of(context).pop(),
        );

      case BarcodeScannerStatus.permissionRestricted:
        return PermissionView(
          title: 'Camera restricted',
          message: state.errorMessage ??
              'Camera access is restricted on this device.',
          buttonText: 'Open Settings',
          secondaryButtonText: 'Close',
          onPressed: () {
            context.read<BarcodeScannerBloc>().add(
              const BarcodeScannerOpenSettingsRequested(),
            );
          },
          onSecondaryPressed: () => Navigator.of(context).pop(),
        );

      case BarcodeScannerStatus.permissionGranted:
      case BarcodeScannerStatus.scanning:
      case BarcodeScannerStatus.detected:
      case BarcodeScannerStatus.failure:
        return CameraScannerView(
          controller: _controller,
          scanLineAnimation: _scanLineAnimation,
          onDetect: _onDetect,
          onBackPressed: () => Navigator.of(context).pop(),
          onTorchPressed: () => _controller.toggleTorch(),
        );
    }
  }
}



class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Colors.black,
      child: Center(
        child: CircularProgressIndicator(
          color: Colors.greenAccent,
        ),
      ),
    );
  }
}


extension _FirstOrNullExtension<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    if (iterator.moveNext()) return iterator.current;
    return null;
  }
}