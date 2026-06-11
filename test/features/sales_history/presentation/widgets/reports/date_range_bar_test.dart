import 'package:amana_pos/features/sales_history/presentation/bloc/sales_report_bloc.dart';
import 'package:amana_pos/features/sales_history/presentation/bloc/sales_report_event.dart';
import 'package:amana_pos/features/sales_history/presentation/bloc/sales_report_state.dart';
import 'package:amana_pos/features/sales_history/presentation/widgets/reports/date_range_bar.dart';
import 'package:amana_pos/l10n/app_localizations.dart';
import 'package:amana_pos/theme/app_theme.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockSalesReportBloc extends MockBloc<SalesReportEvent, SalesReportState>
    implements SalesReportBloc {}

void main() {
  late MockSalesReportBloc bloc;

  setUpAll(() => registerFallbackValue(const SalesReportRangeChanged(preset: ReportPreset.today)));

  setUp(() {
    bloc = MockSalesReportBloc();
    when(() => bloc.state).thenReturn(const SalesReportState());
  });

  Widget wrap(Widget w) => MaterialApp(
    theme: AppTheme.light,
    locale: const Locale('en'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: BlocProvider<SalesReportBloc>.value(value: bloc, child: w),
    ),
  );

  testWidgets('renders Today and Yesterday chips', (tester) async {
    await tester.pumpWidget(wrap(const DateRangeBar()));
    await tester.pumpAndSettle();
    expect(find.text('Today'), findsOneWidget);
    expect(find.text('Yesterday'), findsOneWidget);
  });

  testWidgets('tapping Yesterday dispatches SalesReportRangeChanged', (tester) async {
    await tester.pumpWidget(wrap(const DateRangeBar()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Yesterday'));
    verify(() => bloc.add(const SalesReportRangeChanged(preset: ReportPreset.yesterday))).called(1);
  });
}
