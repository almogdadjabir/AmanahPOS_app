import 'dart:async';

import 'package:amana_pos/core/errors/friendly_error.dart';
import 'package:amana_pos/features/customers/data/models/requests/customer_request_dto.dart';
import 'package:amana_pos/features/customers/data/models/responses/customer_response_dto.dart';
import 'package:amana_pos/features/customers/domain/repositories/customer_repository.dart';
import 'package:amana_pos/features/customers/domain/usecases/customer_usecase.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'customers_event.dart';
part 'customers_state.dart';

class CustomersBloc extends Bloc<CustomersEvent, CustomersState> {
  static const int pageSize = 20;

  final CustomerUseCase useCase;
  final Duration searchDebounce;

  /// Bumped by every page-1 load and every search keystroke, so a slow
  /// response for an older query never overwrites a newer one.
  int _seq = 0;

  CustomersBloc({
    required this.useCase,
    this.searchDebounce = const Duration(milliseconds: 300),
  }) : super(CustomersState.initial()) {
    on<OnCustomersInitial>(_initial);
    on<OnLoadMoreCustomers>(_loadMore);
    on<OnCustomerSearchChanged>(_searchChanged);
    on<OnCustomerFilterChanged>(_filterChanged);
    on<OnCreateCustomer>(_createCustomer);
    on<OnUpdateCustomer>(_updateCustomer);
    on<OnSetCustomerActive>(_setActive);
    on<OnAcknowledgeCustomerSubmit>(_acknowledgeSubmit);
  }

  Future<void> _initial(
    OnCustomersInitial event,
    Emitter<CustomersState> emit,
  ) async {
    try {
      await _loadFirstPage(emit, silent: event.silent);
    } finally {
      if (event.done?.isCompleted == false) event.done!.complete();
    }
  }

  /// Loads page 1 for the current search and filter. Resolves when the
  /// response is applied or discarded as stale.
  Future<void> _loadFirstPage(
    Emitter<CustomersState> emit, {
    bool silent = false,
  }) async {
    final seq = ++_seq;
    final hasRows = state.customers.isNotEmpty;

    emit(
      state.copyWith(
        status: silent && hasRows
            ? CustomersStatus.success
            : CustomersStatus.loading,
        customers: silent ? null : const [],
        currentPage: silent ? null : 1,
        totalPages: silent ? null : 1,
        responseError: null,
      ),
    );

    try {
      final response = await useCase.getCustomers(
        page: 1,
        pageSize: pageSize,
        search: state.searchQuery,
        isActive: state.filter,
      );
      if (seq != _seq) return;

      final error = response.getLeft().toNullable();
      final result = response.getRight().toNullable();

      if (error != null) {
        emit(
          state.copyWith(
            status: silent && hasRows
                ? CustomersStatus.success
                : CustomersStatus.failure,
            responseError: error,
          ),
        );
        return;
      }

      final rows = result?.results ?? const <CustomerData>[];
      emit(
        state.copyWith(
          status: CustomersStatus.success,
          customers: rows,
          currentPage: result?.currentPage ?? 1,
          totalPages: result?.totalPages ?? 1,
          totalCount: result?.count ?? rows.length,
          responseError: null,
        ),
      );
    } catch (e) {
      if (seq != _seq) return;
      emit(
        state.copyWith(
          status: CustomersStatus.failure,
          responseError: friendlyError(e),
        ),
      );
    }
  }

  Future<void> _loadMore(
    OnLoadMoreCustomers event,
    Emitter<CustomersState> emit,
  ) async {
    if (!state.hasMorePages) return;
    if (state.status == CustomersStatus.loadingMore) return;
    if (state.status == CustomersStatus.loading) return;

    final seq = _seq;
    final nextPage = state.currentPage + 1;

    emit(state.copyWith(status: CustomersStatus.loadingMore));

    try {
      final response = await useCase.getCustomers(
        page: nextPage,
        pageSize: pageSize,
        search: state.searchQuery,
        isActive: state.filter,
      );
      if (seq != _seq) return;

      final error = response.getLeft().toNullable();
      final result = response.getRight().toNullable();

      if (error != null) {
        emit(
          state.copyWith(status: CustomersStatus.success, responseError: error),
        );
        return;
      }

      emit(
        state.copyWith(
          status: CustomersStatus.success,
          customers: [...state.customers, ...(result?.results ?? const [])],
          currentPage: result?.currentPage ?? nextPage,
          totalPages: result?.totalPages ?? state.totalPages,
          totalCount: result?.count ?? state.totalCount,
          responseError: null,
        ),
      );
    } catch (_) {
      if (seq != _seq) return;
      emit(state.copyWith(status: CustomersStatus.success));
    }
  }

  Future<void> _searchChanged(
    OnCustomerSearchChanged event,
    Emitter<CustomersState> emit,
  ) async {
    final query = event.query.trim();
    if (query == state.searchQuery.trim()) return;

    final seq = ++_seq;
    emit(state.copyWith(searchQuery: query));

    if (searchDebounce > Duration.zero) {
      await Future<void>.delayed(searchDebounce);
    }
    // A newer keystroke (or filter change) took over while we waited.
    if (seq != _seq || emit.isDone) return;

    // Keep the current rows on screen until the server answers.
    await _loadFirstPage(emit, silent: true);
  }

  Future<void> _filterChanged(
    OnCustomerFilterChanged event,
    Emitter<CustomersState> emit,
  ) async {
    if (event.filter == state.filter) return;
    emit(state.copyWith(filter: event.filter));
    await _loadFirstPage(emit);
  }

  Future<void> _createCustomer(
    OnCreateCustomer event,
    Emitter<CustomersState> emit,
  ) async {
    emit(
      state.copyWith(
        submitStatus: CustomerSubmitStatus.loading,
        submitError: null,
      ),
    );

    try {
      final response = await useCase.createCustomer(request: event.dto);
      final error = response.getLeft().toNullable();

      if (error != null) {
        emit(
          state.copyWith(
            submitStatus: CustomerSubmitStatus.failure,
            submitError: error,
          ),
        );
        return;
      }

      emit(
        state.copyWith(
          submitStatus: CustomerSubmitStatus.success,
          submitError: null,
        ),
      );

      add(const OnCustomersInitial(silent: true));
    } catch (e) {
      emit(
        state.copyWith(
          submitStatus: CustomerSubmitStatus.failure,
          submitError: friendlyError(e),
        ),
      );
    }
  }

  Future<void> _updateCustomer(
    OnUpdateCustomer event,
    Emitter<CustomersState> emit,
  ) async {
    emit(
      state.copyWith(
        submitStatus: CustomerSubmitStatus.loading,
        submitError: null,
      ),
    );

    try {
      final response = await useCase.updateCustomer(
        customerId: event.customerId,
        request: event.dto,
      );
      final error = response.getLeft().toNullable();

      if (error != null) {
        emit(
          state.copyWith(
            submitStatus: CustomerSubmitStatus.failure,
            submitError: error,
          ),
        );
        return;
      }

      emit(
        state.copyWith(
          customers: _replace(
            event.customerId,
            response.getRight().toNullable()?.data,
          ),
          submitStatus: CustomerSubmitStatus.success,
          submitError: null,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          submitStatus: CustomerSubmitStatus.failure,
          submitError: friendlyError(e),
        ),
      );
    }
  }

  Future<void> _setActive(
    OnSetCustomerActive event,
    Emitter<CustomersState> emit,
  ) async {
    emit(
      state.copyWith(
        submitStatus: CustomerSubmitStatus.loading,
        submitError: null,
      ),
    );

    try {
      final response = await useCase.setCustomerActive(
        customerId: event.customerId,
        isActive: event.isActive,
      );
      final error = response.getLeft().toNullable();

      if (error != null) {
        emit(
          state.copyWith(
            submitStatus: CustomerSubmitStatus.failure,
            submitError: error,
          ),
        );
        return;
      }

      final updated = response.getRight().toNullable()?.data;
      final before = state.customers.where((c) => c.id == event.customerId);
      final wasActive = before.isEmpty ? null : before.first.isActive != false;
      final leavesList =
          wasActive != null &&
          wasActive != event.isActive &&
          state.filter != CustomerActiveFilter.all;

      emit(
        state.copyWith(
          customers: _replace(
            event.customerId,
            updated ??
                (before.isEmpty
                    ? null
                    : before.first.copyWith(isActive: event.isActive)),
          ),
          totalCount: leavesList && state.totalCount > 0
              ? state.totalCount - 1
              : state.totalCount,
          submitStatus: CustomerSubmitStatus.success,
          submitError: null,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          submitStatus: CustomerSubmitStatus.failure,
          submitError: friendlyError(e),
        ),
      );
    }
  }

  List<CustomerData> _replace(String id, CustomerData? updated) {
    if (updated == null) return state.customers;
    return [for (final c in state.customers) c.id == id ? updated : c];
  }

  void _acknowledgeSubmit(
    OnAcknowledgeCustomerSubmit event,
    Emitter<CustomersState> emit,
  ) {
    emit(
      state.copyWith(
        submitStatus: CustomerSubmitStatus.idle,
        submitError: null,
      ),
    );
  }
}
