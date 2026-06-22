import 'dart:async';

import 'package:amana_pos/common/auth_bloc/auth_bloc.dart';
import 'package:amana_pos/common/services/local/local_storage.dart';
import 'package:amana_pos/config/constants.dart';
import 'package:amana_pos/features/login/data/models/otp_verify_response.dart';
import 'package:amana_pos/features/pin/data/pin_hasher.dart';
import 'package:amana_pos/features/pin/data/pin_user_record.dart';
import 'package:amana_pos/features/pin/data/pin_vault_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'pin_event.dart';
part 'pin_state.dart';

typedef EnrollTokens = ({String access, String refresh, String tenantId});

class PinBloc extends Bloc<PinEvent, PinState> {
  final PinVaultService vault;
  final CacheStorage cache;
  final AuthBloc authBloc;
  final PinMode mode;
  final User? enrollUser;
  final EnrollTokens? enrollTokens;

  Timer? _lockTimer;

  PinBloc({
    required this.vault,
    required this.cache,
    required this.authBloc,
    required this.mode,
    this.enrollUser,
    this.enrollTokens,
  }) : super(PinState.initial(mode)) {
    on<PinDigitPressed>(_onDigit);
    on<PinBackspace>(_onBackspace);
    on<PinCleared>(_onCleared);
    on<PinLockoutTicked>(_onTick);
    if (mode == PinMode.unlock) {
      _initLockout();
    }
  }

  Future<void> _initLockout() async {
    final remaining = await vault.lockoutRemaining();
    if (remaining > Duration.zero && !isClosed) {
      add(const PinLockoutTicked());
    }
  }

  void _startLockTimer() {
    _lockTimer?.cancel();
    _lockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!isClosed) add(const PinLockoutTicked());
    });
  }

  Future<void> _onTick(PinLockoutTicked e, Emitter<PinState> emit) async {
    // First tick after a lockout begins: read remaining from the vault.
    if (state.phase != PinPhase.locked) {
      final remaining = await vault.lockoutRemaining();
      if (remaining <= Duration.zero) return;
      emit(state.copyWith(
          phase: PinPhase.locked, entered: '', lockoutRemaining: remaining));
      _startLockTimer();
      return;
    }
    final next = state.lockoutRemaining - const Duration(seconds: 1);
    if (next <= Duration.zero) {
      _lockTimer?.cancel();
      emit(state.copyWith(
          phase: PinPhase.entering, lockoutRemaining: Duration.zero));
    } else {
      emit(state.copyWith(lockoutRemaining: next));
    }
  }

  Future<void> _onDigit(PinDigitPressed e, Emitter<PinState> emit) async {
    if (state.phase == PinPhase.locked || state.entered.length >= 4) return;
    final entered = state.entered + e.digit;
    final phase =
        mode == PinMode.setup && state.firstEntry.isNotEmpty
            ? PinPhase.confirming
            : PinPhase.entering;
    emit(state.copyWith(entered: entered, clearError: true, phase: phase));
    if (entered.length == 4) {
      if (mode == PinMode.setup) {
        await _handleSetup(entered, emit);
      } else {
        await _handleUnlock(entered, emit);
      }
    }
  }

  void _onBackspace(PinBackspace e, Emitter<PinState> emit) {
    if (state.entered.isEmpty) return;
    emit(state.copyWith(
        entered: state.entered.substring(0, state.entered.length - 1),
        clearError: true));
  }

  void _onCleared(PinCleared e, Emitter<PinState> emit) {
    emit(state.copyWith(entered: '', clearError: true));
  }

  Future<void> _handleSetup(String pin, Emitter<PinState> emit) async {
    if (state.firstEntry.isEmpty) {
      emit(state.copyWith(
          firstEntry: pin, entered: '', phase: PinPhase.confirming));
      return;
    }
    if (pin != state.firstEntry) {
      emit(state.copyWith(
          phase: PinPhase.mismatch, entered: '', firstEntry: '',
          errorText: 'PINs did not match. Try again.'));
      return;
    }
    if (await vault.isPinTaken(pin)) {
      emit(state.copyWith(
          phase: PinPhase.error, entered: '', firstEntry: '',
          errorText: 'This PIN is already in use. Choose another.'));
      return;
    }
    final u = enrollUser;
    final t = enrollTokens;
    if (u == null || t == null) {
      emit(state.copyWith(phase: PinPhase.error, errorText: 'Setup unavailable.'));
      return;
    }
    final salt = PinHasher.generateSalt();
    final now = DateTime.now().toIso8601String();
    await vault.enrollUser(PinUserRecord(
      userId: u.id ?? '',
      businessId: u.businessId ?? '',
      tenantId: t.tenantId,
      fullName: u.fullName ?? '',
      role: u.role ?? '',
      phone: u.phone ?? '',
      pinSalt: salt,
      pinHash: PinHasher.hashPin(pin, salt),
      accessToken: t.access,
      refreshToken: t.refresh,
      profileJson: u.toJson(),
      enrolledAt: now,
      lastUnlockAt: now,
    ));
    emit(state.copyWith(phase: PinPhase.success));
  }

  Future<void> _handleUnlock(String pin, Emitter<PinState> emit) async {
    final match = await vault.findUserByPin(pin);
    if (match == null) {
      await vault.recordFailedAttempt();
      final remaining = await vault.lockoutRemaining();
      if (remaining > Duration.zero) {
        emit(state.copyWith(
            phase: PinPhase.locked, entered: '', lockoutRemaining: remaining));
        _startLockTimer();
      } else {
        emit(state.copyWith(
            phase: PinPhase.mismatch, entered: '',
            errorText: 'Incorrect PIN. Try again.'));
      }
      return;
    }
    await cache.save(Constants.authToken, match.accessToken);
    await cache.save(Constants.refreshToken, match.refreshToken);
    await cache.save(Constants.xTenantID, match.tenantId);
    authBloc.add(OnLoadProfileEvent(user: User.fromJson(match.profileJson)));
    emit(state.copyWith(phase: PinPhase.success, unlockedUser: match));
  }

  @override
  Future<void> close() {
    _lockTimer?.cancel();
    return super.close();
  }
}
