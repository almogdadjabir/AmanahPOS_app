import 'package:amana_pos/barcode_scanner/presentation/widgets/scan_line.dart';
import 'package:amana_pos/barcode_scanner/presentation/widgets/scanner_overlay_painter.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class CameraScannerView extends StatelessWidget {
  final MobileScannerController controller;
  final Animation<double> scanLineAnimation;
  final void Function(BarcodeCapture capture) onDetect;
  final VoidCallback onBackPressed;
  final VoidCallback onTorchPressed;

  const CameraScannerView({super.key,
    required this.controller,
    required this.scanLineAnimation,
    required this.onDetect,
    required this.onBackPressed,
    required this.onTorchPressed,
  });

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.paddingOf(context).top;
    final bottomPadding = MediaQuery.paddingOf(context).bottom;

    return Stack(
      children: [
        Positioned.fill(
          child: MobileScanner(
            controller: controller,
            onDetect: onDetect,
            fit: BoxFit.cover,
          ),
        ),

        Positioned.fill(
          child: CustomPaint(
            painter: ScannerOverlayPainter(),
            child: const SizedBox.expand(),
          )
        ),

        ScanLine(animation: scanLineAnimation),

        Positioned(
          top: topPadding + 12,
          left: 16,
          child: circleActionButton(
            icon: Icons.arrow_back_rounded,
            onTap: onBackPressed,
          ),
        ),

        Positioned(
          top: topPadding + 12,
          right: 16,
          child: circleActionButton(
            icon: Icons.flash_on_rounded,
            onTap: onTorchPressed,
          ),
        ),

        Positioned(
          left: 24,
          right: 24,
          bottom: bottomPadding + 42,
          child: scannerInstruction(),
        ),
      ],
    );
  }


  Widget scannerInstruction(){
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.32),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white.withOpacity(0.08),
        ),
      ),
      child: const Padding(
        padding: EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        child: Text(
          'Place the barcode inside the frame',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w700,
            height: 1.3,
            letterSpacing: 0.1,
          ),
        ),
      ),
    );
  }

  Widget circleActionButton({
    required IconData icon,
    required VoidCallback onTap,
  }){
    return Material(
      color: Colors.black.withOpacity(0.42),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: 48,
          height: 48,
          child: Icon(
            icon,
            color: Colors.white,
            size: 24,
          ),
        ),
      ),
    );
  }
}