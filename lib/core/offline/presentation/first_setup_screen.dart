import 'package:amana_pos/common/auth_bloc/auth_bloc.dart';
import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/core/offline/presentation/bloc/offline_status_bloc.dart';
import 'package:amana_pos/core/offline/presentation/widgets/offline_hero.dart';
import 'package:amana_pos/core/sync/bootstrap/bootstrapper.dart';
import 'package:amana_pos/core/sync/sync_engine.dart' show SyncBlockReason;
import 'package:amana_pos/l10n/app_localizations.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/theme/phosphor_icons.dart';
import 'package:amana_pos/utilities/dependencies_provider.dart';
import 'package:amana_pos/widgets/app_button.dart';
import 'package:amana_pos/widgets/app_group.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Blocking first-setup host (spec 2026-11-16 phase 2, section 5). Shown by
/// `OfflinePreparationListener` while the signed-in scope was never
/// bootstrapped; closed when the final bootstrap transaction commits. Same
/// dialog-on-root-navigator slot the legacy "preparing offline" screen used.
class FirstSetupScreen {
  static bool isShowing = false;

  static Future<void> show(BuildContext context) async {
    if (isShowing) return;
    isShowing = true;

    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierLabel: context.tr.fsTitle,
      useRootNavigator: true,
      transitionDuration: AppDims.slow,
      pageBuilder: (_, _, _) => BlocProvider.value(
        value: getIt<OfflineStatusBloc>(),
        child: const FirstSetupBody(),
      ),
      transitionBuilder: (_, animation, _, child) => FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: AppDims.ease),
        child: child,
      ),
    );

    isShowing = false;
  }

  static void close(BuildContext context) {
    if (!isShowing) return;
    final navigator = Navigator.of(context, rootNavigator: true);
    if (navigator.canPop()) navigator.pop();
    isShowing = false;
  }

  static void reset() => isShowing = false;
}

/// Bloc-wired page: retry -> [OnOfflineStatusRefreshRequested]; sign out
/// -> the app's existing [OnLogoutEvent] (review I1: a blocked first setup
/// must never trap the user). The logout gate passes in practice (no sale
/// is possible before setup, so the outbox is empty); when it refuses, its
/// own message is shown here.
class FirstSetupBody extends StatelessWidget {
  const FirstSetupBody({super.key, this.authBloc});

  /// Defaults to the app's [AuthBloc] singleton.
  final AuthBloc? authBloc;

  @override
  Widget build(BuildContext context) {
    final auth = authBloc ?? getIt<AuthBloc>();
    return PopScope(
      canPop: false,
      child: BlocListener<AuthBloc, AuthState>(
        bloc: auth,
        listenWhen: (p, c) =>
            c.authStatus == AuthStatus.failure &&
            c.responseError != null &&
            (p.authStatus != c.authStatus ||
                p.responseError != c.responseError),
        listener: (context, state) {
          ScaffoldMessenger.maybeOf(context)
            ?..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(state.responseError!)));
        },
        child: BlocBuilder<OfflineStatusBloc, OfflineStatusState>(
          buildWhen: (p, c) => p.setupStatus != c.setupStatus,
          builder: (context, state) => FirstSetupView(
            status: state.setupStatus,
            onRetry: () => context.read<OfflineStatusBloc>().add(
              const OnOfflineStatusRefreshRequested(),
            ),
            onSignOut: () => auth.add(const OnLogoutEvent(localOnly: true)),
          ),
        ),
      ),
    );
  }
}

/// The user-facing steps; each groups feed entities in bootstrap order
/// ([Bootstrapper.entityOrder]), so a step is done once the run moved past
/// its last entity.
enum FirstSetupStep {
  business(['business', 'shop'], PhosphorIconsRegular.storefront),
  catalog(['category', 'product'], PhosphorIconsRegular.package),
  people([
    'vendor',
    'customer',
    'user',
    'subscription',
    'bankak_account',
  ], PhosphorIconsRegular.users),
  stock(['stock', 'expiry_batch'], PhosphorIconsRegular.stack),
  history([
    'sale',
    'refund',
    'inbound',
    'notification',
  ], PhosphorIconsRegular.receipt);

  const FirstSetupStep(this.entities, this.icon);

  final List<String> entities;
  final IconData icon;

  String label(AppLocalizations tr) => switch (this) {
    FirstSetupStep.business => tr.fsStepBusiness,
    FirstSetupStep.catalog => tr.fsStepCatalog,
    FirstSetupStep.people => tr.fsStepPeople,
    FirstSetupStep.stock => tr.fsStepStock,
    FirstSetupStep.history => tr.fsStepHistory,
  };

  int get _lastOrder => entities
      .map(Bootstrapper.entityOrder.indexOf)
      .reduce((a, b) => a > b ? a : b);
}

enum _StepState { waiting, current, done }

/// Pure first-setup page (testable without the bloc).
class FirstSetupView extends StatelessWidget {
  const FirstSetupView({
    super.key,
    required this.status,
    required this.onRetry,
    required this.onSignOut,
  });

  static const retryKey = ValueKey('fs-retry');
  static const signOutKey = ValueKey('fs-sign-out');

  final FirstSetupStatus status;
  final VoidCallback onRetry;

  /// Way out of a blocking setup (wrong account, server never ready).
  final VoidCallback onSignOut;

  bool get _canRetry => switch (status.phase) {
    FirstSetupPhase.required ||
    FirstSetupPhase.blockedOffline ||
    FirstSetupPhase.blockedServer ||
    FirstSetupPhase.blockedAccount => true,
    _ => false,
  };

  _StepState _stepState(FirstSetupStep step) {
    if (status.phase == FirstSetupPhase.done) return _StepState.done;
    if (!status.isRunning) return _StepState.waiting;
    final current = Bootstrapper.entityOrder.indexOf(status.entity ?? '');
    if (current < 0) return _StepState.waiting;
    if (step.entities.contains(status.entity)) return _StepState.current;
    return step._lastOrder < current ? _StepState.done : _StepState.waiting;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final text = Theme.of(context).textTheme;
    final tr = context.tr;

    final subtitle = switch (status.phase) {
      FirstSetupPhase.running => tr.fsSubRunning,
      FirstSetupPhase.done => tr.fsImagesDownloading,
      FirstSetupPhase.blockedAccount => tr.fsSubBlockedAccount,
      _ => tr.fsSubRequired,
    };

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppDims.s4,
            AppDims.s6,
            AppDims.s4,
            AppDims.s6,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(child: _Header(phase: status.phase)),
              const SizedBox(height: AppDims.s5),
              Text(
                status.phase == FirstSetupPhase.done
                    ? tr.fsDoneTitle
                    : tr.fsTitle,
                textAlign: TextAlign.center,
                style: text.titleLarge!.copyWith(color: colors.textPrimary),
              ),
              const SizedBox(height: AppDims.s2),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: text.bodyMedium!.copyWith(
                  color: colors.textSecondary,
                  height: 1.4,
                ),
              ),
              if (status.phase == FirstSetupPhase.blockedOffline)
                _Notice(
                  icon: PhosphorIconsRegular.wifiSlash,
                  danger: false,
                  title: tr.fsOfflineTitle,
                  body: tr.fsOfflineBody,
                ),
              if (status.phase == FirstSetupPhase.blockedServer)
                _Notice(
                  icon: PhosphorIconsRegular.warningCircle,
                  danger: true,
                  title: tr.fsServerTitle,
                  body: tr.fsServerBody,
                ),
              if (status.phase == FirstSetupPhase.blockedAccount)
                _accountNotice(tr, status.blockReason),
              const SizedBox(height: AppDims.s5),
              if (status.isRunning && status.count > 0) ...[
                ClipRRect(
                  borderRadius: AppDims.borderPill,
                  child: LinearProgressIndicator(
                    value: (status.index / status.count).clamp(0.0, 1.0),
                    minHeight: 6,
                    color: colors.primary,
                    backgroundColor: colors.chartTrack,
                  ),
                ),
                const SizedBox(height: AppDims.s4),
              ],
              AppGroup(
                children: [
                  for (final (i, step) in FirstSetupStep.values.indexed)
                    _StepRow(
                      index: i,
                      step: step,
                      state: _stepState(step),
                      detail: _stepState(step) == _StepState.current
                          ? '${tr.fsStepOf(status.index + 1, status.count)}'
                                ' · ${tr.fsRowsSaved(status.rowsApplied)}'
                          : null,
                    ),
                ],
              ),
              const SizedBox(height: AppDims.s5),
              if (_canRetry) ...[
                AppButton.wide(
                  key: retryKey,
                  label: tr.fsRetry,
                  onPressed: onRetry,
                  variant: status.phase == FirstSetupPhase.required
                      ? AppButtonVariant.secondary
                      : AppButtonVariant.primary,
                  prefixIcon: const Icon(
                    PhosphorIconsRegular.arrowsClockwise,
                    size: 18,
                  ),
                ),
                const SizedBox(height: AppDims.s4),
              ],
              if (status.phase != FirstSetupPhase.done)
                Text(
                  tr.fsResumeNote,
                  textAlign: TextAlign.center,
                  style: text.bodySmall!.copyWith(color: colors.textHint),
                ),
              if (status.blocksApp) ...[
                const SizedBox(height: AppDims.s2),
                Center(
                  child: AppButton(
                    key: signOutKey,
                    label: tr.fsSignOut,
                    onPressed: onSignOut,
                    variant: AppButtonVariant.ghost,
                    size: AppButtonSize.small,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// F7: the session/account reason behind a [FirstSetupPhase.blockedAccount]
/// (sign-out stays offered below it).
Widget _accountNotice(AppLocalizations tr, SyncBlockReason? reason) {
  final (String title, String body) = switch (reason) {
    SyncBlockReason.accountDisabled => (
      tr.fsAccountDisabledTitle,
      tr.fsAccountDisabledBody,
    ),
    SyncBlockReason.deviceRevoked => (
      tr.fsDeviceRevokedTitle,
      tr.fsDeviceRevokedBody,
    ),
    SyncBlockReason.noSession => (tr.fsNoSessionTitle, tr.fsNoSessionBody),
    _ => (tr.fsTokenExpiredTitle, tr.fsTokenExpiredBody),
  };
  return _Notice(
    icon: PhosphorIconsRegular.warningCircle,
    danger: true,
    title: title,
    body: body,
  );
}

class _Header extends StatelessWidget {
  const _Header({required this.phase});

  final FirstSetupPhase phase;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final (IconData? icon, Color bg, Color fg) = switch (phase) {
      FirstSetupPhase.blockedOffline => (
        PhosphorIconsRegular.wifiSlash,
        colors.warningContainer,
        colors.warning,
      ),
      FirstSetupPhase.blockedServer || FirstSetupPhase.blockedAccount => (
        PhosphorIconsRegular.warningCircle,
        colors.dangerContainer,
        colors.danger,
      ),
      FirstSetupPhase.done => (
        PhosphorIconsRegular.check,
        colors.successContainer,
        colors.success,
      ),
      _ => (null, colors.primaryContainer, colors.primary),
    };
    if (icon == null) return const OfflineHero();
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Icon(icon, size: 34, color: fg),
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({
    required this.icon,
    required this.danger,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final bool danger;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final text = Theme.of(context).textTheme;
    final fg = danger ? colors.danger : colors.warning;
    final bg = danger ? colors.dangerContainer : colors.warningContainer;

    return Padding(
      padding: const EdgeInsets.only(top: AppDims.s4),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: AppDims.borderLg,
          border: Border.all(color: fg.withValues(alpha: 0.25)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppDims.s4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 22, color: fg),
              const SizedBox(width: AppDims.s3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: text.titleSmall!.copyWith(
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      body,
                      style: text.bodyMedium!.copyWith(
                        color: colors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({
    required this.index,
    required this.step,
    required this.state,
    this.detail,
  });

  final int index;
  final FirstSetupStep step;
  final _StepState state;
  final String? detail;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final row = AppGroupRow(
      title: step.label(context.tr),
      subtitle: detail,
      icon: step.icon,
      showChevron: false,
      tint: switch (state) {
        _StepState.done => AppTint.success,
        _StepState.current => AppTint.brand,
        _StepState.waiting => AppTint.neutral,
      },
      trailing: switch (state) {
        _StepState.done => Icon(
          PhosphorIconsRegular.check,
          size: 18,
          color: colors.success,
        ),
        _StepState.current => SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: colors.primary,
          ),
        ),
        _StepState.waiting => null,
      },
    );
    return switch (state) {
      _StepState.current => ColoredBox(
        key: const ValueKey('fs-step-current'),
        color: colors.primaryContainer.withValues(alpha: 0.45),
        child: row,
      ),
      _StepState.done => KeyedSubtree(
        key: ValueKey('fs-step-done-$index'),
        child: row,
      ),
      _StepState.waiting => KeyedSubtree(
        key: ValueKey('fs-step-waiting-$index'),
        child: row,
      ),
    };
  }
}
