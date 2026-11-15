import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/config/router/route_strings.dart';
import 'package:amana_pos/features/pin/data/biometric_unlock_service.dart';
import 'package:amana_pos/features/pin/data/pin_user_record.dart';
import 'package:amana_pos/features/pin/data/pin_vault_service.dart';
import 'package:amana_pos/features/pin/presentation/bloc/pin_bloc.dart';
import 'package:amana_pos/features/pin/presentation/widgets/pin_dots.dart';
import 'package:amana_pos/features/pin/presentation/widgets/pin_keypad.dart';
import 'package:amana_pos/features/pin/presentation/widgets/pin_scaffold.dart';
import 'package:amana_pos/features/pin/presentation/widgets/pin_texts.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/utilities/dependencies_provider.dart';
import 'package:amana_pos/widgets/amana_logo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class PinUnlockScreen extends StatefulWidget {
  const PinUnlockScreen({super.key, this.autoBiometric = true});

  /// Offer Face ID as soon as the screen opens. Off when the person pressed
  /// Lock themselves: they locked it on purpose, so wait for them.
  final bool autoBiometric;

  @override
  State<PinUnlockScreen> createState() => _PinUnlockScreenState();
}

class _PinUnlockScreenState extends State<PinUnlockScreen> {
  List<PinUserRecord> _users = const [];
  PinUserRecord? _bioUser;
  BiometricKind? _kind;
  bool _prompting = false;
  bool _bioEnabled = false;

  PinUserRecord? get _only => _users.length == 1 ? _users.first : null;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final users = await getIt<PinVaultService>().allUsers();
    final service = getIt<BiometricUnlockService>();
    final offered = await service.offeredUser();
    final kind = offered == null ? null : await service.availableKind();
    final enabled =
        offered != null && await service.isEnabledFor(offered.userId);
    if (!mounted) return;
    setState(() {
      _users = users;
      _bioUser = offered;
      _kind = kind;
      _bioEnabled = enabled;
    });
    if (enabled && widget.autoBiometric) {
      // Let the screen settle, then offer the biometric like iOS does.
      await Future<void>.delayed(const Duration(milliseconds: 450));
      _promptBiometric();
    }
  }

  /// Tapping the key: confirm with the device, remember the choice the first
  /// time, then unlock.
  Future<void> _promptBiometric() async {
    final user = _bioUser;
    if (user == null || _prompting || !mounted) return;
    final bloc = context.read<PinBloc>();
    if (bloc.state.phase == PinPhase.locked) return;
    final reason = context.tr.pinBiometricReason;
    final service = getIt<BiometricUnlockService>();
    _prompting = true;
    final ok = _bioEnabled
        ? await service.authenticate(reason)
        : await service.enable(user.userId, reason);
    _prompting = false;
    if (!ok || !mounted) return;
    _bioEnabled = true;
    bloc.add(PinBiometricUnlocked(user.userId));
  }

  String _firstName(String full) {
    final t = full.trim();
    return t.isEmpty ? '' : t.split(RegExp(r'\s+')).first;
  }

  String _time(Duration d) {
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '${d.inMinutes}:$s';
  }

  void _useDifferentAccount() => Navigator.of(
    context,
  ).pushNamedAndRemoveUntil(RouteStrings.login, (route) => false);

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    final colors = context.appColors;
    final text = Theme.of(context).textTheme;

    return BlocConsumer<PinBloc, PinState>(
      listenWhen: (prev, curr) => prev.phase != curr.phase,
      listener: (context, state) async {
        if (state.phase == PinPhase.success) {
          final navigator = Navigator.of(context);
          await Future<void>.delayed(const Duration(milliseconds: 350));
          navigator.pushNamedAndRemoveUntil(
            RouteStrings.mainScreen,
            (route) => false,
          );
        }
        if (state.phase == PinPhase.mismatch && context.mounted) {
          schedulePinReset(context);
        }
      },
      builder: (context, state) {
        final locked = state.phase == PinPhase.locked;
        final hasError = state.phase == PinPhase.mismatch;
        final only = _only;
        final name = only == null ? '' : _firstName(only.fullName);
        final bloc = context.read<PinBloc>();

        final Widget header = only != null && name.isNotEmpty
            ? Container(
                width: 64,
                height: 64,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colors.primaryContainer,
                ),
                child: Text(
                  name.characters.first.toUpperCase(),
                  style: text.headlineMedium!.copyWith(color: colors.primary),
                ),
              )
            : const Hero(
                tag: amanaMarkHeroTag,
                child: AmanaPosLogoMark(size: 44),
              );

        final String title = locked
            ? tr.pinLockedTitle
            : name.isNotEmpty
            ? tr.pinWelcomeBack(name)
            : tr.pinEnterTitle;
        final String subtitle = locked
            ? tr.pinLockedSubtitle(_time(state.lockoutRemaining))
            : name.isNotEmpty
            ? tr.pinEnterTitle
            : '';

        final linkStyle = text.bodyMedium!.copyWith(
          fontSize: 15,
          color: colors.primary,
          fontWeight: FontWeight.w500,
        );

        return PinScaffold(
          header: header,
          title: title,
          subtitle: subtitle,
          subtitleIsError: locked,
          errorText: hasError ? tr.pinWrong : null,
          dots: PinDots(
            filledCount: state.entered.length,
            hasError: hasError,
            success: state.phase == PinPhase.success,
          ),
          keypad: PinKeypad(
            enabled: !locked && state.phase != PinPhase.success,
            showDelete: state.entered.isNotEmpty,
            leading: _kind == null ? null : BiometricGlyph(kind: _kind!),
            onLeading: _bioUser == null ? null : _promptBiometric,
            leadingLabel: _kind == null ? null : biometricLabel(tr, _kind!),
            onDigit: (d) => bloc.add(PinDigitPressed(d)),
            onBackspace: () => bloc.add(const PinBackspace()),
          ),
          onDigit: (d) => bloc.add(PinDigitPressed(d)),
          onBackspace: () => bloc.add(const PinBackspace()),
          footer: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _useDifferentAccount,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: Text.rich(
                TextSpan(
                  style: linkStyle.copyWith(
                    color: colors.textSecondary,
                    fontWeight: FontWeight.w400,
                  ),
                  children: [
                    if (name.isNotEmpty)
                      TextSpan(text: '${tr.pinNotYou(name)} '),
                    TextSpan(text: tr.pinUseDifferentAccount, style: linkStyle),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        );
      },
    );
  }
}
