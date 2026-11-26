import 'package:amana_pos/common/auth_bloc/auth_bloc.dart';
import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/features/approval/domain/owner_approval_service.dart';
import 'package:amana_pos/features/pin/presentation/widgets/pin_dots.dart';
import 'package:amana_pos/features/pin/presentation/widgets/pin_keypad.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/utilities/dependencies_provider.dart';
import 'package:amana_pos/widgets/app_button.dart';
import 'package:amana_pos/widgets/app_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The gate for risky actions. Owners and managers pass straight through; a
/// cashier needs the owner's PIN, typed here. One approval = one action.
/// True = go ahead.
Future<bool> ensureOwnerApproval(
  BuildContext context, {
  required String what,
  OwnerApprovalService? service,
}) async {
  final perms = context.read<AuthBloc>().state.permissions;
  if (!perms.isCashier) return true;
  final ok = await showAppSheet<bool>(
    context,
    builder: (_) => OwnerApprovalSheet(
      what: what,
      service: service ?? getIt<OwnerApprovalService>(),
    ),
  );
  return ok == true;
}

class OwnerApprovalSheet extends StatefulWidget {
  const OwnerApprovalSheet({
    super.key,
    required this.what,
    required this.service,
  });

  final String what;
  final OwnerApprovalService service;

  @override
  State<OwnerApprovalSheet> createState() => _OwnerApprovalSheetState();
}

class _OwnerApprovalSheetState extends State<OwnerApprovalSheet> {
  String _pin = '';
  String? _error;
  bool _locked = false;
  bool _noOwner = false;
  bool _busy = false;

  Future<void> _digit(String d) async {
    if (_busy || _locked || _pin.length >= 4) return;
    setState(() {
      _pin += d;
      _error = null;
    });
    if (_pin.length < 4) return;
    _busy = true;
    final tr = context.tr;
    final navigator = Navigator.of(context);
    final r = await widget.service.check(_pin);
    if (!mounted) return;
    _busy = false;
    switch (r) {
      case Approved():
        navigator.pop(true);
      case WrongPin(:final triesLeft):
        setState(() {
          _pin = '';
          _error = tr.oaWrong(triesLeft);
        });
      case Locked(:final seconds):
        setState(() {
          _pin = '';
          _locked = true;
          _error = tr.oaLocked(seconds);
        });
      case NoOwnerPin():
        setState(() {
          _pin = '';
          _noOwner = true;
        });
    }
  }

  void _back() {
    if (_busy || _pin.isEmpty) return;
    setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    final colors = context.appColors;
    final text = Theme.of(context).textTheme;

    if (_noOwner) {
      return AppSheet(
        title: tr.oaTitle,
        child: Padding(
          padding: const EdgeInsets.all(AppDims.s4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                tr.oaNoOwner,
                textAlign: TextAlign.center,
                style: text.bodyMedium!.copyWith(color: colors.warning),
              ),
              const SizedBox(height: AppDims.s4),
              AppButton.wide(
                label: tr.oaOk,
                onPressed: () => Navigator.of(context).pop(false),
              ),
            ],
          ),
        ),
      );
    }

    return AppSheet(
      title: tr.oaTitle,
      leadingAction: AppSheetAction(
        label: tr.cancel,
        onTap: () => Navigator.of(context).pop(false),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppDims.s4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              tr.oaAsk(widget.what),
              textAlign: TextAlign.center,
              style: text.bodyMedium!.copyWith(color: colors.textSecondary),
            ),
            const SizedBox(height: AppDims.s4),
            PinDots(filledCount: _pin.length, hasError: _error != null),
            const SizedBox(height: AppDims.s2),
            SizedBox(
              height: 22,
              child: _error == null
                  ? null
                  : Text(
                      _error!,
                      style: text.bodyMedium!.copyWith(
                        color: colors.danger,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
            const SizedBox(height: AppDims.s2),
            PinKeypad(
              onDigit: _digit,
              onBackspace: _back,
              enabled: !_locked,
              showDelete: _pin.isNotEmpty,
            ),
            const SizedBox(height: AppDims.s4),
          ],
        ),
      ),
    );
  }
}
