import 'dart:async';
import 'package:amana_pos/core/offline/data/offline_local_cache.dart';
import 'package:amana_pos/features/inventory/data/models/requests/create_vendor_request_dto.dart';
import 'package:amana_pos/features/inventory/data/models/requests/update_vendor_request_dto.dart';
import 'package:amana_pos/features/inventory/data/models/responses/vendor_response_dto.dart';
import 'package:amana_pos/features/inventory/domain/usecases/inventory_usecase.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'vendors_event.dart';
part 'vendors_state.dart';

class VendorsBloc extends Bloc<VendorsEvent, VendorsState> {
  final InventoryUseCase useCase;
  final OfflineLocalCache offlineLocalCache;
  final Future<bool> Function() isOnline;

  VendorsBloc({
    required this.useCase,
    required this.offlineLocalCache,
    required this.isOnline,
  }) : super(VendorsState.initial()) {
    on<OnVendorsStarted>(_onStarted);
    on<OnVendorCreate>(_onCreate);
    on<OnVendorUpdate>(_onUpdate);
    on<OnVendorDelete>(_onDelete);
    on<OnVendorsReset>(_onReset);
  }

  Future<void> _onStarted(OnVendorsStarted event, Emitter<VendorsState> emit) async {
    emit(state.copyWith(status: VendorsStatus.loading));

    // Load from cache first
    final cached = await offlineLocalCache.getVendors();
    if (cached.isNotEmpty) {
      emit(state.copyWith(status: VendorsStatus.success, vendors: cached));
    }

    final online = await isOnline();
    if (!online) {
      if (cached.isEmpty) emit(state.copyWith(status: VendorsStatus.failure));
      return;
    }

    try {
      final result = await useCase.getVendors();
      result.fold(
        (error) {
          if (cached.isEmpty) {
            emit(state.copyWith(status: VendorsStatus.failure, responseError: error));
          }
        },
        (dto) {
          emit(state.copyWith(
            status: VendorsStatus.success,
            vendors: dto.results,
            clearResponseError: true,
          ));
          offlineLocalCache.saveVendors(dto.results);
        },
      );
    } catch (e) {
      if (cached.isEmpty) {
        emit(state.copyWith(status: VendorsStatus.failure, responseError: e.toString()));
      }
    }
  }

  Future<void> _onCreate(OnVendorCreate event, Emitter<VendorsState> emit) async {
    if (state.submitStatus == VendorsSubmitStatus.loading) return;
    emit(state.copyWith(submitStatus: VendorsSubmitStatus.loading, clearSubmitError: true));
    try {
      final result = await useCase.createVendor(event.request);
      result.fold(
        (error) => emit(state.copyWith(
          submitStatus: VendorsSubmitStatus.failure,
          submitError: error,
        )),
        (vendor) {
          final updated = [vendor, ...state.vendors];
          emit(state.copyWith(
            submitStatus: VendorsSubmitStatus.success,
            vendors: updated,
          ));
          offlineLocalCache.saveVendors(updated);
        },
      );
    } catch (e) {
      emit(state.copyWith(
        submitStatus: VendorsSubmitStatus.failure,
        submitError: e.toString(),
      ));
    }
  }

  Future<void> _onUpdate(OnVendorUpdate event, Emitter<VendorsState> emit) async {
    if (state.submitStatus == VendorsSubmitStatus.loading) return;
    emit(state.copyWith(submitStatus: VendorsSubmitStatus.loading, clearSubmitError: true));
    try {
      final result = await useCase.updateVendor(event.id, event.request);
      result.fold(
        (error) => emit(state.copyWith(
          submitStatus: VendorsSubmitStatus.failure,
          submitError: error,
        )),
        (vendor) {
          final updated = state.vendors
              .map((v) => v.id == vendor.id ? vendor : v)
              .toList();
          emit(state.copyWith(
            submitStatus: VendorsSubmitStatus.success,
            vendors: updated,
          ));
          offlineLocalCache.saveVendors(updated);
        },
      );
    } catch (e) {
      emit(state.copyWith(
        submitStatus: VendorsSubmitStatus.failure,
        submitError: e.toString(),
      ));
    }
  }

  Future<void> _onDelete(OnVendorDelete event, Emitter<VendorsState> emit) async {
    if (state.submitStatus == VendorsSubmitStatus.loading) return;
    emit(state.copyWith(submitStatus: VendorsSubmitStatus.loading, clearSubmitError: true));
    try {
      final result = await useCase.deleteVendor(event.id);
      result.fold(
        (error) => emit(state.copyWith(
          submitStatus: VendorsSubmitStatus.failure,
          submitError: error,
        )),
        (_) {
          final updated = state.vendors.where((v) => v.id != event.id).toList();
          emit(state.copyWith(
            submitStatus: VendorsSubmitStatus.success,
            vendors: updated,
          ));
          offlineLocalCache.saveVendors(updated);
        },
      );
    } catch (e) {
      emit(state.copyWith(
        submitStatus: VendorsSubmitStatus.failure,
        submitError: e.toString(),
      ));
    }
  }

  void _onReset(OnVendorsReset event, Emitter<VendorsState> emit) {
    emit(VendorsState.initial());
  }
}
