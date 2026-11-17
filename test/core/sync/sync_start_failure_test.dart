import 'dart:async';

import 'package:amana_pos/common/auth_bloc/auth_bloc.dart';
import 'package:amana_pos/core/sync/sync_scope.dart';
import 'package:amana_pos/features/business/data/models/responses/business_response_dto.dart';
import 'package:amana_pos/features/login/data/models/otp_verify_response.dart';
import 'package:amana_pos/utilities/dependencies_provider.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';

class _MockAuth extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

AuthState _session(String user, String tenant) => AuthState(
  isLoggedIn: true,
  profile: User(id: user),
  defaultBusiness: BusinessData(id: tenant),
);

/// Review I4: when the sync core fails to start, SyncScope.current must
/// still follow the session, or every sale write throws (no scope to
/// enqueue under) for the whole session.
void main() {
  late StreamController<AuthState> auth;

  setUp(() async {
    await getIt.reset();
    DependenciesProvider.resetScopeFollowerForTesting();
    SyncScope.current = null;
    auth = StreamController<AuthState>.broadcast();
    final bloc = _MockAuth();
    whenListen(bloc, auth.stream, initialState: _session('u1', 't1'));
    getIt.registerSingleton<AuthBloc>(bloc);
  });
  tearDown(() async {
    DependenciesProvider.resetScopeFollowerForTesting();
    SyncScope.current = null;
    await auth.close();
    await getIt.reset();
  });

  test(
    'a failing core start falls back to following the session scope',
    () async {
      await DependenciesProvider.startSyncIfEnabled(
        startCore: () async => throw StateError('DI failure at launch'),
      );
      expect(SyncScope.current, 'u1|t1');

      auth.add(_session('u2', 't1'));
      await Future<void>.delayed(Duration.zero);
      expect(SyncScope.current, 'u2|t1');

      auth.add(const AuthState());
      await Future<void>.delayed(Duration.zero);
      expect(SyncScope.current, isNull);
    },
  );

  test('a successful core start does not install the fallback', () async {
    var started = false;
    await DependenciesProvider.startSyncIfEnabled(
      startCore: () async => started = true,
    );
    expect(started, isTrue);
    expect(SyncScope.current, isNull); // the coordinator owns the scope
  });
}
