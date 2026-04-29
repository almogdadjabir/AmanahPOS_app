import 'package:amana_pos/config/constants.dart';
import 'package:amana_pos/config/router/route_strings.dart';
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


  String? _currentUserPinfl;

  AuthBloc({required this.useCase, required this.businessUseCase,}) : super(AuthState.initial()) {
    on<OnLoadProfileEvent>(_onLoadProfile);
    on<OnLoadBusinessEvent>(_onLoadBusinessEvent);
    on<OnLogoutEvent>(_onLogout);
  }

  Future<void> _onLoadProfile(
      OnLoadProfileEvent event,
      Emitter<AuthState> emit,
      ) async {
    try {

      if(event.user != null){
        _emitProfileLoaded(emit, event.user!);
        add(OnLoadBusinessEvent());
        return;
      }

      if (state.authStatus == AuthStatus.loading) return;

      final token = await useCase.cacheStorage.read(Constants.authToken);
      if (token == null || token.isEmpty) return;

      emit(state.copyWith(const AuthStateUpdate(authStatus: AuthStatus.loading)));

      // 1. Serve cached profile immediately for fast perceived load.
      final cached = await useCase.cacheStorage.getTypedObject<User>(
        Constants.cachedProfile,
            (json) => User.fromJson(json),
      );

      if (cached != null) {
        final cachedId = _userIdFrom(cached);
        if (_currentUserPinfl != null && _currentUserPinfl != cachedId) {
          // Different account — discard stale cache.
          await useCase.cacheStorage.save(Constants.cachedProfile, null);
        } else {
          _currentUserPinfl = cachedId;
          _emitProfileLoaded(emit, cached);
        }
      }

      // 2. Fetch fresh profile from API.
      final result = await useCase.getProfile();
      final fresh  = result.getRight().toNullable();
      final error  = result.getLeft().toNullable();

      if (fresh != null) {
        _currentUserPinfl = _userIdFrom(fresh.user!);
        useCase.cacheStorage.saveObject(Constants.cachedProfile, fresh.toJson());
        _emitProfileLoaded(emit, fresh.user!);
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
      final refreshToken = await useCase.cacheStorage.getValue(Constants.refreshToken);
      final authToken    = await useCase.cacheStorage.getValue(Constants.authToken);

      // Wipe tokens first — session checks see no active session immediately.
      await useCase.cacheStorage.save(Constants.xTenantID, null);
      await useCase.cacheStorage.save(Constants.authToken, null);
      await useCase.cacheStorage.save(Constants.refreshToken, null);

      _navigateToWelcome();

      _currentUserPinfl = null;
      emit(AuthState.initial());

      // Background: call logout API then clear remaining cached data.
      _backgroundLogout(refreshToken, authToken);
    } catch (e) {
      if (state.profile == null) _emitFailure(emit, e.toString());
    }
  }

  Future<void> _backgroundLogout(String? refreshToken, String? authToken) async {
    // try {
    //   if (refreshToken == null || refreshToken.isEmpty) return;
    //
    //   String? freshToken;
    //   try {
    //     final r = await useCase.refreshTokenSilently(refreshToken);
    //     freshToken = r.getRight().toNullable()?.accessToken;
    //   } catch (_) {
    //     freshToken = authToken;
    //   }
    //
    //   try {
    //     await useCase.logout({'refreshToken': refreshToken}, freshToken ?? authToken);
    //   } catch (_) {
    //     // Server session will expire on its own.
    //   }
    // } finally {
    //   await useCase.cacheStorage.clearOnLogout();
    // }
  }


  String? _userIdFrom(User u) => u.id;

  void _navigateToWelcome() {
    Constants.navigatorKey.currentState
        ?.pushNamedAndRemoveUntil(RouteStrings.splash, (_) => false);
  }

  void _emitProfileLoaded(Emitter<AuthState> emit, User p) {
    emit(state.copyWith(AuthStateUpdate(
      profile: p,
      isLoggedIn: true,
      authStatus: AuthStatus.success,
    )));
  }

  void _emitFailure(Emitter<AuthState> emit, String? error) {
    emit(state.copyWith(AuthStateUpdate(
      authStatus: AuthStatus.failure,
      responseError: error,
    )));
  }

  Future<void> _onLoadBusinessEvent(
      OnLoadBusinessEvent event,
      Emitter<AuthState> emit,
      ) async {
    if (state.businessStatus == BusinessStatus.loading ||
        state.businessStatus == BusinessStatus.success) return;

    emit(state.copyWith(AuthStateUpdate(
      businessStatus: BusinessStatus.loading,
    )));

    try {
      final response = await businessUseCase.getBusinessList();

      final error = response.getLeft().toNullable();
      final business = response.getRight().toNullable();

      if (error != null) {
        emit(state.copyWith(AuthStateUpdate(
          businessStatus: BusinessStatus.failure,
        )));
        return;
      }

      if (business != null) {
        await useCase.cacheStorage.save(
          Constants.xTenantID,
          business.data?.first.id,
        );

        if (!emit.isDone) {
          emit(state.copyWith(AuthStateUpdate(
            defaultBusiness: business.data?.first,
            businessStatus:  BusinessStatus.success,
          )));
        }
      }
    } catch (e) {
      if (!emit.isDone) {
        emit(state.copyWith(AuthStateUpdate(
          businessStatus: BusinessStatus.failure,
        )));
      }
    }
  }


  @override
  Future<void> close() {
    _currentUserPinfl = null;
    return super.close();
  }
}