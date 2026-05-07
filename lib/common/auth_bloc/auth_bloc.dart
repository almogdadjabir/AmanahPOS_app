import 'dart:async';

import 'package:amana_pos/config/constants.dart';
import 'package:amana_pos/config/router/route_strings.dart';
import 'package:amana_pos/core/offline/data/offline_local_cache.dart';
import 'package:amana_pos/core/offline/presentation/bloc/offline_status_bloc.dart';
import 'package:amana_pos/core/permissions/app_permissions.dart';
import 'package:amana_pos/features/business/data/models/responses/business_response_dto.dart';
import 'package:amana_pos/features/business/domain/usecases/business_usecase.dart';
import 'package:amana_pos/features/login/data/models/otp_verify_response.dart';
import 'package:amana_pos/features/login/domain/usecase/login_usecase.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final LoginUseCase useCase;
  final BusinessUseCase businessUseCase;
  final OfflineLocalCache offlineLocalCache;
  final OfflineStatusBloc offlineStatusBloc;

  String? _currentUserXTenantID;
  bool _loggedOut = false;

  AuthBloc({
    required this.useCase,
    required this.businessUseCase,
    required this.offlineLocalCache,
    required this.offlineStatusBloc,
  }) : super(AuthState.initial()) {
    on<OnLoadProfileEvent>(_onLoadProfile);
    on<OnLoadBusinessEvent>(_onLoadBusinessEvent);
    on<OnLogoutEvent>(_onLogout);
  }

  Future<void> _onLoadProfile(
      OnLoadProfileEvent event,
      Emitter<AuthState> emit,
      ) async {
    try {
      if (event.user != null) {
        _emitProfileLoaded(emit, event.user!, userSwitched: false);
        add(OnLoadBusinessEvent());
        return;
      }

      if (state.authStatus == AuthStatus.loading) return;

      final token = await useCase.cacheStorage.read(Constants.authToken);
      if (token == null || token.isEmpty) return;

      emit(state.copyWith(const AuthStateUpdate(authStatus: AuthStatus.loading)));

      final cached = await useCase.cacheStorage.getTypedObject<User>(
        Constants.cachedProfile,
            (json) => User.fromJson(json),
      );

      if (cached != null) {
        final cachedId = _userIdFrom(cached);
        if (_currentUserXTenantID != null && _currentUserXTenantID != cachedId) {
          await useCase.cacheStorage.save(Constants.cachedProfile, null);
        } else {
          _currentUserXTenantID = cachedId;
          // Same user from cache — do NOT bump sessionId.
          _emitProfileLoaded(emit, cached, userSwitched: false);
        }
      }

      final result = await useCase.getProfile();
      final fresh = result.getRight().toNullable();
      final error = result.getLeft().toNullable();

      if (fresh != null) {
        final incomingId = _userIdFrom(fresh.user!);

        final isDifferentUser = _loggedOut ||
            (_currentUserXTenantID != null && _currentUserXTenantID != incomingId);
        _loggedOut = false;


        if (isDifferentUser) {
          // Wipe the DB so old user's data is gone before the new session starts.
          await offlineLocalCache.clearAllOnLogout();
        }

        _currentUserXTenantID = incomingId;
        await useCase.cacheStorage.saveObject(
          Constants.cachedProfile,
          fresh.toJson(),
        );

        // Only bump sessionId when a different user logs in.
        // Same user re-logging in must NOT trigger bloc resets.
        _emitProfileLoaded(emit, fresh.user!, userSwitched: isDifferentUser);
      } else {
        if (cached == null) _emitFailure(emit, error);
      }

      add(OnLoadBusinessEvent());
    } catch (e) {
      if (state.profile == null) _emitFailure(emit, e.toString());
    }
  }

  Future<void> _onLogout(
      OnLogoutEvent event,
      Emitter<AuthState> emit,
      ) async {
    try {
      if (state.authStatus == AuthStatus.loading) return;

      emit(state.copyWith(
        const AuthStateUpdate(authStatus: AuthStatus.loading),
      ));

      final isOnline = await offlineStatusBloc.isDeviceOnline;
      if (!isOnline) {
        emit(state.copyWith(const AuthStateUpdate(
          authStatus: AuthStatus.failure,
          responseError:
          'Sorry, you are offline. Please connect to the internet and sync all sales before logout.',
        )));
        return;
      }

      final pendingSalesCount =
      await offlineStatusBloc.pendingOfflineSalesCount;
      if (pendingSalesCount > 0) {
        emit(state.copyWith(AuthStateUpdate(
          authStatus: AuthStatus.failure,
          responseError:
          'Sorry, you need to sync all sales first before logout. Pending sales: $pendingSalesCount',
        )));
        return;
      }

      await offlineLocalCache.clearAllOnLogout();
      await useCase.cacheStorage.save(Constants.xTenantID, null);
      await useCase.cacheStorage.save(Constants.authToken, null);
      await useCase.cacheStorage.save(Constants.refreshToken, null);
      await useCase.cacheStorage.save(Constants.cachedProfile, null);

      try {
        await useCase.cacheStorage.clearOnLogout();
      } catch (_) {}

      _currentUserXTenantID = null;
      _loggedOut = true;

      emit(AuthState.initial());
      _navigateToWelcome();
    } catch (e) {
      emit(state.copyWith(const AuthStateUpdate(
        authStatus: AuthStatus.failure,
        responseError:
        'Logout failed. Please try again while connected to the internet.',
      )));
    }
  }

  Future<void> _onLoadBusinessEvent(
      OnLoadBusinessEvent event,
      Emitter<AuthState> emit,
      ) async {
    if (state.businessStatus == BusinessStatus.loading) return;

    emit(state.copyWith(const AuthStateUpdate(
      businessStatus: BusinessStatus.loading,
    )));

    BusinessData? cachedBusiness;

    try {
      final cachedBusinesses = await offlineLocalCache.getBusinesses();
      if (cachedBusinesses.isNotEmpty) {
        cachedBusiness = cachedBusinesses.first;
        await useCase.cacheStorage.save(Constants.xTenantID, cachedBusiness.id);
        if (!emit.isDone) {
          emit(state.copyWith(AuthStateUpdate(
            defaultBusiness: cachedBusiness,
            businessStatus: BusinessStatus.success,
          )));
        }
        offlineStatusBloc.add(const OnOfflineStatusStarted());
      }
    } catch (_) {}

    try {
      final response = await businessUseCase.getBusinessList();
      final error = response.getLeft().toNullable();
      final business = response.getRight().toNullable();

      if (error != null) {
        if (cachedBusiness != null) {
          if (!emit.isDone) {
            emit(state.copyWith(AuthStateUpdate(
              defaultBusiness: cachedBusiness,
              businessStatus: BusinessStatus.success,
            )));
          }
          return;
        }
        if (!emit.isDone) {
          emit(state.copyWith(const AuthStateUpdate(
            businessStatus: BusinessStatus.failure,
          )));
        }
        return;
      }

      final businessList = business?.data ?? [];
      if (businessList.isEmpty) {
        if (!emit.isDone) {
          emit(state.copyWith(const AuthStateUpdate(
            businessStatus: BusinessStatus.success,
          )));
        }
        return;
      }

      final defaultBusiness = businessList.first;
      await useCase.cacheStorage.save(Constants.xTenantID, defaultBusiness.id);

      if (!emit.isDone) {
        emit(state.copyWith(AuthStateUpdate(
          defaultBusiness: defaultBusiness,
          businessStatus: BusinessStatus.success,
        )));
      }

      offlineStatusBloc.add(const OnOfflineStatusStarted());
    } catch (e) {
      if (cachedBusiness != null) {
        if (!emit.isDone) {
          emit(state.copyWith(AuthStateUpdate(
            defaultBusiness: cachedBusiness,
            businessStatus: BusinessStatus.success,
          )));
        }
        offlineStatusBloc.add(const OnOfflineStatusStarted());
        return;
      }
      if (!emit.isDone) {
        emit(state.copyWith(const AuthStateUpdate(
          businessStatus: BusinessStatus.failure,
        )));
      }
    }
  }

  String? _userIdFrom(User u) => u.id;

  void _navigateToWelcome() {
    Constants.navigatorKey.currentState
        ?.pushNamedAndRemoveUntil(RouteStrings.splash, (_) => false);
  }

  /// [userSwitched] = true only when a confirmed DIFFERENT user is logging in.
  /// This is the only time we bump sessionId, which triggers data bloc resets.
  void _emitProfileLoaded(
      Emitter<AuthState> emit,
      User p, {
        required bool userSwitched,
      }) {
    emit(state.copyWith(AuthStateUpdate(
      profile: p,
      isLoggedIn: true,
      authStatus: AuthStatus.success,
      sessionId: userSwitched ? state.sessionId + 1 : state.sessionId,
    )));
  }

  void _emitFailure(Emitter<AuthState> emit, String? error) {
    emit(state.copyWith(AuthStateUpdate(
      authStatus: AuthStatus.failure,
      responseError: error,
    )));
  }

  @override
  Future<void> close() {
    _loggedOut = false;
    _currentUserXTenantID = null;
    return super.close();
  }
}