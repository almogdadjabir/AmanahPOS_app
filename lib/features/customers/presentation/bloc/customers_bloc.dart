import 'package:amana_pos/features/customers/data/models/requests/customer_request_dto.dart';
import 'package:amana_pos/features/customers/data/models/responses/customer_response_dto.dart';
import 'package:amana_pos/features/customers/domain/usecases/customer_usecase.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'customers_event.dart';
part 'customers_state.dart';

class CustomersBloc extends Bloc<CustomersEvent, CustomersState> {
  final CustomerUseCase useCase;

  CustomersBloc({
    required this.useCase,
  }) : super(CustomersState.initial()) {
    on<OnCustomersInitial>(_initial);
    on<OnLoadMoreCustomers>(_loadMore);
    on<OnCustomerSearchChanged>(_searchChanged);
    on<OnCreateCustomer>(_createCustomer);
    on<OnUpdateCustomer>(_updateCustomer);
    on<OnDeleteCustomer>(_deleteCustomer);
    on<OnAcknowledgeCustomerSubmit>(_acknowledgeSubmit);
  }

  Future<void> _initial(
      OnCustomersInitial event,
      Emitter<CustomersState> emit,
      ) async {
    if (state.status == CustomersStatus.loading) return;

    emit(
      state.copyWith(
        status: CustomersStatus.loading,
        customers: [],
        currentPage: 1,
        totalPages: 1,
        responseError: null,
      ),
    );

    try {
      final response = await useCase.getCustomers(page: 1, pageSize: 20);
      final error = response.getLeft().toNullable();
      final result = response.getRight().toNullable();

      if (error != null) {
        emit(
          state.copyWith(
            status: CustomersStatus.failure,
            responseError: error,
          ),
        );
        return;
      }

      emit(
        state.copyWith(
          status: CustomersStatus.success,
          customers: result?.results ?? [],
          currentPage: result?.currentPage ?? 1,
          totalPages: result?.totalPages ?? 1,
          responseError: null,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: CustomersStatus.failure,
          responseError: e.toString(),
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

    final nextPage = state.currentPage + 1;

    emit(state.copyWith(status: CustomersStatus.loadingMore));

    try {
      final response = await useCase.getCustomers(page: nextPage, pageSize: 20);
      final error = response.getLeft().toNullable();
      final result = response.getRight().toNullable();

      if (error != null) {
        emit(
          state.copyWith(
            status: CustomersStatus.success,
            responseError: error,
          ),
        );
        return;
      }

      emit(
        state.copyWith(
          status: CustomersStatus.success,
          customers: [
            ...state.customers,
            ...(result?.results ?? []),
          ],
          currentPage: result?.currentPage ?? nextPage,
          totalPages: result?.totalPages ?? state.totalPages,
          responseError: null,
        ),
      );
    } catch (_) {
      emit(state.copyWith(status: CustomersStatus.success));
    }
  }

  void _searchChanged(
      OnCustomerSearchChanged event,
      Emitter<CustomersState> emit,
      ) {
    emit(state.copyWith(searchQuery: event.query));
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

      add(const OnCustomersInitial());
    } catch (e) {
      emit(
        state.copyWith(
          submitStatus: CustomerSubmitStatus.failure,
          submitError: e.toString(),
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

    // try {
    //   final response = await useCase.updateCustomer(
    //     customerId: event.customerId,
    //     dto: event.dto,
    //   );
    //
    //   final error = response.getLeft().toNullable();
    //
    //   if (error != null) {
    //     emit(
    //       state.copyWith(
    //         submitStatus: CustomerSubmitStatus.failure,
    //         submitError: error,
    //       ),
    //     );
    //     return;
    //   }
    //
    //   emit(
    //     state.copyWith(
    //       submitStatus: CustomerSubmitStatus.success,
    //       submitError: null,
    //     ),
    //   );
    //
    //   add(const OnCustomersInitial());
    // } catch (e) {
    //   emit(
    //     state.copyWith(
    //       submitStatus: CustomerSubmitStatus.failure,
    //       submitError: e.toString(),
    //     ),
    //   );
    // }
  }

  Future<void> _deleteCustomer(
      OnDeleteCustomer event,
      Emitter<CustomersState> emit,
      ) async {
    emit(
      state.copyWith(
        submitStatus: CustomerSubmitStatus.loading,
        submitError: null,
      ),
    );

    // try {
    //   final response = await useCase.deleteCustomer(
    //     customerId: event.customerId,
    //   );
    //
    //   final error = response.getLeft().toNullable();
    //
    //   if (error != null) {
    //     emit(
    //       state.copyWith(
    //         submitStatus: CustomerSubmitStatus.failure,
    //         submitError: error,
    //       ),
    //     );
    //     return;
    //   }
    //
    //   final updated = state.customers
    //       .where((customer) => customer.id != event.customerId)
    //       .toList(growable: false);
    //
    //   emit(
    //     state.copyWith(
    //       customers: updated,
    //       submitStatus: CustomerSubmitStatus.success,
    //       submitError: null,
    //     ),
    //   );
    // } catch (e) {
    //   emit(
    //     state.copyWith(
    //       submitStatus: CustomerSubmitStatus.failure,
    //       submitError: e.toString(),
    //     ),
    //   );
    // }
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