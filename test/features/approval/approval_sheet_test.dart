import 'package:amana_pos/common/auth_bloc/auth_bloc.dart';
import 'package:amana_pos/common/services/local/local_storage.dart';
import 'package:amana_pos/core/permissions/app_permissions.dart';
import 'package:amana_pos/features/approval/domain/owner_approval_service.dart';
import 'package:amana_pos/features/approval/presentation/owner_approval_sheet.dart';
import 'package:amana_pos/features/pin/data/pin_hasher.dart';
import 'package:amana_pos/features/pin/data/pin_user_record.dart';
import 'package:amana_pos/features/pin/data/pin_vault_service.dart';
import 'package:amana_pos/l10n/app_localizations.dart';
import 'package:amana_pos/theme/app_theme.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _Auth extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

class _AuthState extends Mock implements AuthState {}

class _Cache extends Mock implements CacheStorage {}

OwnerApprovalService _service() {
  final salt = PinHasher.generateSalt();
  final owner = PinUserRecord(
    userId: 'o',
    businessId: 'b',
    tenantId: 't',
    fullName: 'O',
    role: 'owner',
    phone: '1',
    pinSalt: salt,
    pinHash: PinHasher.hashPin('1234', salt),
    accessToken: '',
    refreshToken: '',
    profileJson: const {},
    enrolledAt: 'x',
    lastUnlockAt: 'x',
  );
  final cache = _Cache();
  when(() => cache.getObject('pin_vault')).thenAnswer(
    (_) async => {
      'users': [owner.toJson()],
    },
  );
  when(() => cache.saveObject('pin_vault', any())).thenAnswer((_) async => true);
  return OwnerApprovalService(PinVaultService(cache));
}

Widget _app(AppUserRole role, OwnerApprovalService svc, ValueSetter<bool> got) {
  final authState = _AuthState();
  when(() => authState.permissions).thenReturn(
    AppPermissions(
      businessType: AppBusinessType.shop,
      role: role,
      enabledFeatures: const {},
    ),
  );
  final auth = _Auth();
  when(() => auth.state).thenReturn(authState);
  return BlocProvider<AuthBloc>.value(
    value: auth,
    child: MaterialApp(
      theme: AppTheme.light,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        ...GlobalMaterialLocalizations.delegates,
      ],
      home: Builder(
        builder: (c) => Scaffold(
          body: TextButton(
            onPressed: () async =>
                got(await ensureOwnerApproval(c, what: 'to test', service: svc)),
            child: const Text('go'),
          ),
        ),
      ),
    ),
  );
}

Future<void> _type(WidgetTester t, String pin) async {
  for (final d in pin.split('')) {
    await t.tap(find.text(d).first);
    await t.pump();
  }
  await t.pump(const Duration(milliseconds: 50));
  await t.pump(const Duration(milliseconds: 600));
}

void main() {
  testWidgets('owner passes straight through, no sheet', (t) async {
    bool? got;
    await t.pumpWidget(_app(AppUserRole.owner, _service(), (v) => got = v));
    await t.tap(find.text('go'));
    await t.pumpAndSettle();
    expect(got, isTrue);
    expect(find.text('Owner approval'), findsNothing);
  });

  testWidgets('cashier: wrong PIN shows tries left, right PIN approves', (
    t,
  ) async {
    t.view.physicalSize = const Size(800, 1800);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    bool? got;
    await t.pumpWidget(_app(AppUserRole.cashier, _service(), (v) => got = v));
    await t.tap(find.text('go'));
    await t.pumpAndSettle();
    expect(find.text('Owner approval'), findsOneWidget);

    await t.runAsync(() async => _type(t, '0000'));
    await t.pump(const Duration(milliseconds: 100));
    expect(find.text('Wrong PIN. 4 tries left.'), findsOneWidget);

    await t.runAsync(() async => _type(t, '1234'));
    await t.pumpAndSettle();
    expect(got, isTrue);
  });

  testWidgets('cashier cancelling the sheet says no', (t) async {
    t.view.physicalSize = const Size(800, 1800);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    bool? got;
    await t.pumpWidget(_app(AppUserRole.cashier, _service(), (v) => got = v));
    await t.tap(find.text('go'));
    await t.pumpAndSettle();
    await t.tap(find.text('Cancel'));
    await t.pumpAndSettle();
    expect(got, isFalse);
  });
}
