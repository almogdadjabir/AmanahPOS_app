import 'dart:async';

import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/config/router/route_strings.dart';
import 'package:amana_pos/features/pairing/domain/pairing_service.dart';
import 'package:amana_pos/features/settings/presentation/widgets/settings_widgets.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/utilities/dependencies_provider.dart';
import 'package:amana_pos/utilities/global_snackbar.dart';
import 'package:amana_pos/widgets/app_button.dart';
import 'package:amana_pos/widgets/app_large_title.dart';
import 'package:flutter/material.dart';

enum _Phase {
  intro,
  loading,
  code,
  choosing,
  linked,
  expired,
  replaced,
  rateLimited,
  offline,
  forbidden,
  failed,
}

String formatCountdown(int seconds) {
  final s = seconds < 0 ? 0 : seconds;
  return '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';
}

/// Owner/manager makes the 6-digit code the desktop till types. Online only.
class LinkPosScreen extends StatefulWidget {
  const LinkPosScreen({
    super.key,
    this.service,
    this.businessId,
    this.pollEvery = const Duration(seconds: 3),
    this.scan,
    this.now = DateTime.now,
  });

  final PairingService? service;
  final String? businessId;
  final Duration pollEvery;

  /// Returns the scanned text (null = cancelled). Default opens the camera.
  final Future<String?> Function(BuildContext context)? scan;

  /// The clock, replaceable in tests.
  final DateTime Function() now;

  @override
  State<LinkPosScreen> createState() => _LinkPosScreenState();
}

class _LinkPosScreenState extends State<LinkPosScreen> {
  late final PairingService _service;
  _Phase _phase = _Phase.intro;
  PairingCode? _code;
  String? _deviceName;
  int _left = 0;
  DateTime? _endsAt;
  Timer? _tick;
  Timer? _poll;
  bool _polling = false;

  @override
  void initState() {
    super.initState();
    _service = widget.service ?? getIt<PairingService>();
  }

  @override
  void dispose() {
    _stopTimers();
    super.dispose();
  }

  void _stopTimers() {
    _tick?.cancel();
    _poll?.cancel();
    _tick = null;
    _poll = null;
  }

  Future<void> _scan() async {
    final tr = context.tr;
    final navigator = Navigator.of(context);
    while (mounted) {
      final raw = widget.scan != null
          ? await widget.scan!(context)
          : await navigator.pushNamed<String>(
              RouteStrings.barcodeScannerScreen,
            );
      if (!mounted || raw == null) return;
      if (PairingService.isLinkDeviceCode(raw)) {
        return _make();
      }
      GlobalSnackBar.showError(message: tr.plNotDesktopQr);
    }
  }

  Future<void> _make() async {
    _stopTimers();
    setState(() => _phase = _Phase.loading);
    try {
      final c = await _service.create(businessId: widget.businessId);
      if (!mounted) return;
      _code = c;
      _deviceName = null;
      _endsAt = widget.now().add(Duration(seconds: c.ttlSeconds));
      _left = c.ttlSeconds;
      setState(() => _phase = _Phase.code);
      _tick = Timer.periodic(const Duration(seconds: 1), (_) => _onTick());
      _poll = Timer.periodic(widget.pollEvery, (_) => _check());
    } on PairingException catch (e) {
      if (!mounted) return;
      setState(
        () => _phase = switch (e.failure) {
          PairingFailure.rateLimited => _Phase.rateLimited,
          PairingFailure.offline => _Phase.offline,
          PairingFailure.forbidden => _Phase.forbidden,
          PairingFailure.other => _Phase.failed,
        },
      );
    }
  }

  void _onTick() {
    final end = _endsAt;
    if (end == null || !mounted) return;
    final left = end.difference(widget.now()).inSeconds;
    if (left <= 0 && _phase == _Phase.code) {
      _stopTimers();
      setState(() {
        _left = 0;
        _phase = _Phase.expired;
      });
    } else {
      setState(() => _left = left);
    }
  }

  Future<void> _check() async {
    final c = _code;
    if (c == null || _polling) return;
    _polling = true;
    try {
      final p = await _service.status(c.pairingId);
      if (!mounted || _code != c) return;
      switch (p.status) {
        case PairingStatus.pending:
          break;
        case PairingStatus.choosing:
          setState(() {
            _deviceName = p.deviceName;
            _phase = _Phase.choosing;
          });
        case PairingStatus.used:
          _stopTimers();
          setState(() {
            _deviceName = p.deviceName ?? _deviceName;
            _phase = _Phase.linked;
          });
        case PairingStatus.expired:
          _stopTimers();
          setState(() => _phase = _Phase.expired);
        case PairingStatus.replaced:
          _stopTimers();
          setState(() => _phase = _Phase.replaced);
      }
    } on PairingException {
      // A missed check is fine: the next one tries again.
    } finally {
      _polling = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    final colors = context.appColors;
    final text = Theme.of(context).textTheme;

    Widget digits({bool dim = false}) {
      final code = _code?.code ?? '';
      return Directionality(
        textDirection: TextDirection.ltr,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (final ch in code.split(''))
              Container(
                width: 40,
                height: 52,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: dim ? colors.surfaceSoft : colors.surface,
                  borderRadius: BorderRadius.circular(AppDims.s3),
                  border: Border.all(color: colors.border),
                ),
                child: Text(
                  ch,
                  style: text.headlineSmall!.copyWith(
                    fontWeight: FontWeight.w700,
                    color: dim ? colors.textSecondary : colors.textPrimary,
                  ),
                ),
              ),
          ],
        ),
      );
    }

    Widget note(String msg, Color fg, Color bg) => Container(
      padding: const EdgeInsets.all(AppDims.s3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppDims.s3),
      ),
      child: Text(
        msg,
        style: text.bodyMedium!.copyWith(color: fg, fontWeight: FontWeight.w600),
      ),
    );

    Widget message(String title, String body) => Padding(
      padding: const EdgeInsets.symmetric(vertical: AppDims.s6),
      child: Column(
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: text.titleLarge!.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppDims.s2),
          Text(
            body,
            textAlign: TextAlign.center,
            style: text.bodyMedium!.copyWith(color: colors.textSecondary),
          ),
        ],
      ),
    );

    final name = _deviceName ?? tr.plDeviceFallback;
    final List<Widget> body;
    switch (_phase) {
      case _Phase.intro:
        body = [
          message(tr.plIntro, tr.plIntroSub),
          for (final s in [tr.plStep1, tr.plStep2, tr.plStep3])
            Padding(
              padding: const EdgeInsets.only(bottom: AppDims.s2),
              child: Text(s, style: text.bodyMedium),
            ),
          const SizedBox(height: AppDims.s4),
          AppButton.wide(label: tr.plScan, onPressed: _scan),
          const SizedBox(height: AppDims.s2),
          AppButton.wide(
            label: tr.plShow,
            variant: AppButtonVariant.outline,
            onPressed: _make,
          ),
        ];
      case _Phase.loading:
        body = [
          const SizedBox(height: AppDims.s8),
          Center(child: CircularProgressIndicator(color: colors.primary)),
        ];
      case _Phase.code:
      case _Phase.choosing:
        final total = _code?.ttlSeconds ?? 300;
        body = [
          const SizedBox(height: AppDims.s4),
          digits(dim: _phase == _Phase.choosing),
          const SizedBox(height: AppDims.s3),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppDims.s2),
            child: LinearProgressIndicator(
              value: (_left / total).clamp(0.0, 1.0),
              minHeight: 6,
              color: _left < 60 ? colors.warning : colors.primary,
              backgroundColor: colors.border,
            ),
          ),
          const SizedBox(height: AppDims.s2),
          Text(
            tr.plExpiresIn(formatCountdown(_left)),
            textAlign: TextAlign.center,
            style: text.bodySmall!.copyWith(color: colors.textSecondary),
          ),
          const SizedBox(height: AppDims.s4),
          if (_phase == _Phase.code)
            note(tr.plWaiting, colors.info, colors.infoContainer)
          else
            note(
              '${tr.plChoosing}: ${tr.plChoosingBody(name)}',
              colors.info,
              colors.infoContainer,
            ),
          const SizedBox(height: AppDims.s4),
          AppButton.wide(
            label: tr.plNewCode,
            variant: AppButtonVariant.outline,
            onPressed: _make,
          ),
        ];
      case _Phase.linked:
        body = [
          message(tr.plLinked(name), tr.plLinkedBody),
          AppButton.wide(
            label: tr.done,
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          const SizedBox(height: AppDims.s2),
          AppButton.wide(
            label: tr.plLinkAnother,
            variant: AppButtonVariant.outline,
            onPressed: _make,
          ),
        ];
      case _Phase.expired:
      case _Phase.replaced:
        body = [
          const SizedBox(height: AppDims.s4),
          digits(dim: true),
          const SizedBox(height: AppDims.s4),
          note(
            _phase == _Phase.expired ? tr.plExpired : tr.plReplaced,
            colors.warning,
            colors.warningContainer,
          ),
          const SizedBox(height: AppDims.s4),
          AppButton.wide(label: tr.plNewCode, onPressed: _make),
        ];
      case _Phase.rateLimited:
        body = [
          message(tr.plTooMany, tr.plTooManyBody),
          AppButton.wide(
            label: tr.back,
            variant: AppButtonVariant.outline,
            onPressed: () => Navigator.of(context).maybePop(),
          ),
        ];
      case _Phase.offline:
        body = [
          message(tr.plOffline, tr.plOfflineBody),
          AppButton.wide(label: tr.plTryAgain, onPressed: _make),
        ];
      case _Phase.forbidden:
        body = [message(tr.plTitle, tr.plForbidden)];
      case _Phase.failed:
        body = [
          message(tr.plTitle, tr.plError),
          AppButton.wide(label: tr.plTryAgain, onPressed: _make),
        ];
    }

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Column(
          children: [
            SettingsNavBar(backLabel: tr.back),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: AppDims.s4),
                children: [AppLargeTitle(title: tr.plTitle), ...body],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
