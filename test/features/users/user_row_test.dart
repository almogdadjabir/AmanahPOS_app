import 'dart:async';

import 'package:amana_pos/common/auth_bloc/auth_bloc.dart';
import 'package:amana_pos/core/sync/sync_scope.dart';
import 'package:amana_pos/features/users/data/models/responses/user_response_dto.dart';
import 'package:amana_pos/features/users/presentation/bloc/users_bloc.dart';
import 'package:amana_pos/features/users/presentation/widgets/user_conflict_banner.dart';
import 'package:amana_pos/features/users/presentation/widgets/user_row.dart';
import 'package:amana_pos/l10n/app_localizations.dart';
import 'package:amana_pos/theme/app_theme.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:amana_pos/features/users/presentation/widgets/user_format.dart';
import 'package:amana_pos/features/login/data/models/otp_verify_response.dart'
    show User;

class _MockAuth extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

class _MockUserBloc extends MockBloc<UserEvent, UserState>
    implements UserBloc {}

void main() {
  late _MockAuth auth;
  late _MockUserBloc users;
  late StreamController<UserState> ctrl;
  setUp(() {
    auth = _MockAuth();
    when(() => auth.state).thenReturn(const AuthState());
    users = _MockUserBloc();
    when(() => users.state).thenReturn(UserState.initial());
    ctrl = StreamController<UserState>.broadcast();
    when(() => users.stream).thenAnswer((_) => ctrl.stream);
  });
  tearDown(() => ctrl.close());

  Widget wrap(Widget child) => MaterialApp(
    theme: AppTheme.light,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>.value(value: auth),
        BlocProvider<UserBloc>.value(value: users),
      ],
      child: Scaffold(body: child),
    ),
  );

  const base = UserData(
    id: 'u2',
    phone: '+249911',
    fullName: 'Sara',
    role: 'cashier',
    isActive: true,
    isVerified: true,
    version: 3,
  );

  testWidgets('chips: pending, invite pending, failed', (t) async {
    await t.pumpWidget(
      wrap(
        Column(
          children: [
            UserRow(user: base.withMarks(UserSyncMark.pending, null)),
            UserRow(
              user: const UserData(
                id: 'u3',
                fullName: 'Nour',
                role: 'cashier',
                isActive: true,
              ).withMarks(UserSyncMark.pending, null),
            ),
            UserRow(
              user: base.withMarks(
                UserSyncMark.failed,
                const UserConflict(
                  mutationId: 'm',
                  op: 'set_role',
                  code: 'conflict_version',
                ),
              ),
            ),
          ],
        ),
      ),
    );
    expect(find.text('Waiting to sync'), findsOneWidget);
    expect(find.text('Invite pending'), findsOneWidget);
    expect(find.text('Not applied'), findsOneWidget);
  });

  testWidgets('banner buttons dispatch the conflict events', (t) async {
    final u = base.withMarks(
      UserSyncMark.failed,
      const UserConflict(
        mutationId: 'm9',
        op: 'set_role',
        code: 'conflict_version',
        payload: {'role': 'manager'},
      ),
    );
    await t.pumpWidget(wrap(UserConflictBanner(user: u)));
    expect(find.text('Change not applied'), findsOneWidget);
    expect(find.textContaining('Your change: Role: Manager'), findsOneWidget);
    await t.tap(find.text('Apply mine again'));
    await t.pump();
    verify(() => users.add(const OnApplyUserConflict('m9'))).called(1);
    await t.tap(find.text('Dismiss'));
    await t.pump();
    verify(() => users.add(const OnDismissUserConflict('m9'))).called(1);
    ctrl.add(
      UserState.initial().copyWith(submitStatus: UserSubmitStatus.loading),
    );
    ctrl.add(
      UserState.initial().copyWith(submitStatus: UserSubmitStatus.success),
    );
    await t.pump();
  });

  testWidgets('canEdit guard: owner row and self are not editable', (t) async {
    when(() => auth.state).thenReturn(const AuthState(profile: User(id: 'me')));
    late bool owner, self, other;
    await t.pumpWidget(
      wrap(
        Builder(
          builder: (c) {
            owner = canEditTeamMember(
              c,
              const UserData(id: 'o', role: 'owner'),
            );
            self = canEditTeamMember(
              c,
              const UserData(id: 'me', role: 'manager'),
            );
            other = canEditTeamMember(c, base);
            return const SizedBox();
          },
        ),
      ),
    );
    expect([owner, self, other], [false, false, true]);
  });

  testWidgets('no profile yet: the signed-in scope still names me', (t) async {
    SyncScope.current = 'me|t1';
    addTearDown(() => SyncScope.current = null);
    late bool self, other;
    await t.pumpWidget(
      wrap(
        Builder(
          builder: (c) {
            self = canEditTeamMember(
              c,
              const UserData(id: 'me', role: 'manager'),
            );
            other = canEditTeamMember(c, base);
            return const SizedBox();
          },
        ),
      ),
    );
    expect([self, other], [false, true]);
  });

  testWidgets('nobody known: nothing is editable', (t) async {
    late bool other;
    await t.pumpWidget(
      wrap(
        Builder(
          builder: (c) {
            other = canEditTeamMember(c, base);
            return const SizedBox();
          },
        ),
      ),
    );
    expect(other, isFalse);
  });
}
