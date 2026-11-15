import 'package:amana_pos/features/customers/data/models/requests/customer_request_dto.dart';
import 'package:amana_pos/features/customers/data/models/responses/add_customer_response_dto.dart';
import 'package:amana_pos/features/customers/data/models/responses/customer_response_dto.dart';
import 'package:amana_pos/features/customers/domain/repositories/customer_repository.dart';
import 'package:amana_pos/features/customers/domain/usecases/customer_usecase.dart';
import 'package:amana_pos/features/customers/presentation/bloc/customers_bloc.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class _MockUseCase extends Mock implements CustomerUseCase {}

CustomerResponseDto _page(List<CustomerData> rows, {int? count}) =>
    CustomerResponseDto(
      count: count ?? rows.length,
      totalPages: 1,
      currentPage: 1,
      results: rows,
    );

const _amira = CustomerData(id: 'c1', name: 'Amira', isActive: true);
const _ahmed = CustomerData(id: 'c2', name: 'Ahmed', isActive: true);

void main() {
  late _MockUseCase useCase;

  setUpAll(() {
    registerFallbackValue(CustomerActiveFilter.active);
    registerFallbackValue(const CustomerRequestDto(name: 'x'));
  });

  setUp(() {
    useCase = _MockUseCase();
    when(
      () => useCase.getCustomers(
        page: any(named: 'page'),
        pageSize: any(named: 'pageSize'),
        search: any(named: 'search'),
        isActive: any(named: 'isActive'),
      ),
    ).thenAnswer((_) async => Right(_page(const [_amira, _ahmed], count: 2)));
  });

  CustomersBloc build() =>
      CustomersBloc(useCase: useCase, searchDebounce: Duration.zero);

  blocTest<CustomersBloc, CustomersState>(
    'initial load fetches active customers and exposes the server count',
    build: build,
    act: (b) => b.add(const OnCustomersInitial()),
    verify: (b) {
      verify(
        () => useCase.getCustomers(
          page: 1,
          pageSize: 20,
          search: '',
          isActive: CustomerActiveFilter.active,
        ),
      ).called(1);
      expect(b.state.status, CustomersStatus.success);
      expect(b.state.totalCount, 2);
      expect(b.state.customers.length, 2);
    },
  );

  blocTest<CustomersBloc, CustomersState>(
    'search reloads page 1 with the search param',
    build: build,
    act: (b) => b.add(const OnCustomerSearchChanged('am')),
    wait: const Duration(milliseconds: 20),
    verify: (b) {
      verify(
        () => useCase.getCustomers(
          page: 1,
          pageSize: 20,
          search: 'am',
          isActive: CustomerActiveFilter.active,
        ),
      ).called(1);
      expect(b.state.searchQuery, 'am');
    },
  );

  test('only the last of several quick searches hits the server', () async {
    final bloc = CustomersBloc(
      useCase: useCase,
      searchDebounce: const Duration(milliseconds: 50),
    );
    bloc
      ..add(const OnCustomerSearchChanged('a'))
      ..add(const OnCustomerSearchChanged('am'))
      ..add(const OnCustomerSearchChanged('ami'));
    await Future<void>.delayed(const Duration(milliseconds: 200));

    verify(
      () => useCase.getCustomers(
        page: 1,
        pageSize: 20,
        search: 'ami',
        isActive: CustomerActiveFilter.active,
      ),
    ).called(1);
    verifyNever(
      () => useCase.getCustomers(
        page: any(named: 'page'),
        pageSize: any(named: 'pageSize'),
        search: 'a',
        isActive: any(named: 'isActive'),
      ),
    );
    await bloc.close();
  });

  blocTest<CustomersBloc, CustomersState>(
    'inactive chip requests is_active=false',
    build: build,
    act: (b) =>
        b.add(const OnCustomerFilterChanged(CustomerActiveFilter.inactive)),
    verify: (b) {
      verify(
        () => useCase.getCustomers(
          page: 1,
          pageSize: 20,
          search: '',
          isActive: CustomerActiveFilter.inactive,
        ),
      ).called(1);
      expect(b.state.filter, CustomerActiveFilter.inactive);
    },
  );

  test('inactive filter maps to is_active=false on the wire', () {
    expect(CustomerActiveFilter.active.queryValue, 'true');
    expect(CustomerActiveFilter.inactive.queryValue, 'false');
  });

  blocTest<CustomersBloc, CustomersState>(
    'update replaces the customer in place and succeeds',
    build: () {
      when(
        () => useCase.updateCustomer(
          customerId: any(named: 'customerId'),
          request: any(named: 'request'),
        ),
      ).thenAnswer(
        (_) async => Right(
          AddCustomerResponseDto(
            success: true,
            data: CustomerData(id: 'c1', name: 'Amira H', isActive: true),
          ),
        ),
      );
      return build();
    },
    seed: () => CustomersState.initial().copyWith(
      status: CustomersStatus.success,
      customers: const [_amira, _ahmed],
    ),
    act: (b) => b.add(
      const OnUpdateCustomer(
        customerId: 'c1',
        dto: CustomerRequestDto(name: 'Amira H'),
      ),
    ),
    verify: (b) {
      expect(b.state.submitStatus, CustomerSubmitStatus.success);
      expect(b.state.customers.first.name, 'Amira H');
      expect(b.state.customers.length, 2);
    },
  );

  blocTest<CustomersBloc, CustomersState>(
    'update failure surfaces the error',
    build: () {
      when(
        () => useCase.updateCustomer(
          customerId: any(named: 'customerId'),
          request: any(named: 'request'),
        ),
      ).thenAnswer(
        (_) async => const Left('A customer with this phone exists'),
      );
      return build();
    },
    act: (b) => b.add(
      const OnUpdateCustomer(
        customerId: 'c1',
        dto: CustomerRequestDto(name: 'Amira'),
      ),
    ),
    verify: (b) {
      expect(b.state.submitStatus, CustomerSubmitStatus.failure);
      expect(b.state.submitError, 'A customer with this phone exists');
    },
  );

  blocTest<CustomersBloc, CustomersState>(
    'deactivate PATCHes is_active=false, hides the row and lowers the count',
    build: () {
      when(
        () => useCase.setCustomerActive(
          customerId: any(named: 'customerId'),
          isActive: any(named: 'isActive'),
        ),
      ).thenAnswer(
        (_) async => Right(
          AddCustomerResponseDto(
            success: true,
            data: CustomerData(id: 'c1', name: 'Amira', isActive: false),
          ),
        ),
      );
      return build();
    },
    seed: () => CustomersState.initial().copyWith(
      status: CustomersStatus.success,
      customers: const [_amira, _ahmed],
      totalCount: 2,
    ),
    act: (b) =>
        b.add(const OnSetCustomerActive(customerId: 'c1', isActive: false)),
    verify: (b) {
      verify(
        () => useCase.setCustomerActive(customerId: 'c1', isActive: false),
      ).called(1);
      expect(b.state.submitStatus, CustomerSubmitStatus.success);
      expect(b.state.visibleCustomers.map((c) => c.id), ['c2']);
      // Still known to the bloc so an open detail screen can keep showing it.
      expect(b.state.customers.length, 2);
      expect(b.state.totalCount, 1);
    },
  );

  blocTest<CustomersBloc, CustomersState>(
    'reactivate PATCHes is_active=true',
    build: () {
      when(
        () => useCase.setCustomerActive(
          customerId: any(named: 'customerId'),
          isActive: any(named: 'isActive'),
        ),
      ).thenAnswer(
        (_) async => Right(
          AddCustomerResponseDto(
            success: true,
            data: CustomerData(id: 'c1', name: 'Amira', isActive: true),
          ),
        ),
      );
      return build();
    },
    seed: () => CustomersState.initial().copyWith(
      status: CustomersStatus.success,
      filter: CustomerActiveFilter.inactive,
      customers: const [CustomerData(id: 'c1', name: 'Amira', isActive: false)],
      totalCount: 1,
    ),
    act: (b) =>
        b.add(const OnSetCustomerActive(customerId: 'c1', isActive: true)),
    verify: (b) {
      verify(
        () => useCase.setCustomerActive(customerId: 'c1', isActive: true),
      ).called(1);
      expect(b.state.visibleCustomers, isEmpty);
      expect(b.state.totalCount, 0);
    },
  );

  test('request dto sends is_active and no loyalty points', () {
    final json = const CustomerRequestDto(name: 'A', isActive: false).toJson();
    expect(json['is_active'], false);
    expect(json.containsKey('loyalty_points'), isFalse);
    expect(json.containsKey('phone'), isFalse);
  });
}
