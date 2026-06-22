import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:amana_pos/common/auth_bloc/auth_bloc.dart';
import 'package:amana_pos/common/services/local/local_storage.dart';
import 'package:amana_pos/common/services/notifications/fcm_token_service.dart';
import 'package:amana_pos/features/login/data/models/otp_verify_response.dart';
import 'package:amana_pos/features/login/data/models/password_login_request.dart';
import 'package:amana_pos/features/login/domain/usecase/login_usecase.dart';
import 'package:amana_pos/features/login/presentation/bloc/login_bloc.dart';
import 'package:amana_pos/utilities/dependencies_provider.dart';

class _MockUseCase extends Mock implements LoginUseCase {}
class _MockCache extends Mock implements CacheStorage {}
class _MockFcm extends Mock implements FcmTokenService {}
class _MockAuthBloc extends Mock implements AuthBloc {}

void main() {
  late _MockUseCase useCase;
  late _MockCache cache;
  late _MockFcm fcm;
  late _MockAuthBloc authBloc;

  setUpAll(() {
    registerFallbackValue(OnLoadProfileEvent());
    registerFallbackValue(PasswordLoginRequest());
  });

  setUp(() {
    useCase = _MockUseCase();
    cache = _MockCache();
    fcm = _MockFcm();
    authBloc = _MockAuthBloc();

    if (getIt.isRegistered<AuthBloc>()) getIt.unregister<AuthBloc>();
    getIt.registerSingleton<AuthBloc>(authBloc);

    when(() => authBloc.add(any())).thenReturn(null);
    when(() => cache.save(any(), any())).thenAnswer((_) async => true);
    when(() => useCase.passwordLogin(any())).thenAnswer(
      (_) async => Right(OtpVerifyResponse(
        success: true,
        loginData: LoginData(
          access: 'acc',
          refresh: 'ref',
          user: const User(id: 'u1', businessId: 'b1', role: 'cashier'),
        ),
      )),
    );
  });

  tearDown(() {
    if (getIt.isRegistered<AuthBloc>()) getIt.unregister<AuthBloc>();
  });

  blocTest<LoginBloc, LoginState>(
    'password login success carries the logged-in user in state',
    build: () => LoginBloc(useCase: useCase, cacheStorage: cache, fcmTokenService: fcm),
    seed: () => LoginState.initial().copyWith(
      phoneNumber: '912345678',
      isMobileValid: true,
      isFormValid: true,
    ),
    act: (b) => b.add(const OnPasswordLoginEvent(password: 'secret')),
    wait: const Duration(milliseconds: 50),
    verify: (bloc) {
      expect(bloc.state.loginStatus, LoginStatus.competed);
      expect(bloc.state.loggedInUser?.id, 'u1');
    },
  );
}
