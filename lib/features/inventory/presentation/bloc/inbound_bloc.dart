import 'dart:async';
import 'package:amana_pos/core/offline/data/offline_local_cache.dart';
import 'package:amana_pos/features/inventory/data/models/requests/create_inbound_request_dto.dart';
import 'package:amana_pos/features/inventory/data/models/responses/inbound_response_dto.dart';
import 'package:amana_pos/features/inventory/data/offline/offline_inbound_queue.dart';
import 'package:amana_pos/features/inventory/domain/usecases/inventory_usecase.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

part 'inbound_event.dart';
part 'inbound_state.dart';

class InboundBloc extends Bloc<InboundEvent, InboundState> {
  final InventoryUseCase useCase;
  final OfflineLocalCache offlineLocalCache;
  final OfflineInboundQueue offlineInboundQueue;
  final Future<bool> Function() isOnline;

  InboundBloc({
    required this.useCase,
    required this.offlineLocalCache,
    required this.offlineInboundQueue,
    required this.isOnline,
  }) : super(InboundState.initial()) {
    on<OnInboundStarted>(_onStarted);
    on<OnInboundLoadMore>(_onLoadMore);
    on<OnInboundFormSubmit>(_onFormSubmit);
    on<OnInboundAcknowledge>(_onAcknowledge);
    on<OnInboundReset>(_onReset);
  }

  Future<void> _onStarted(OnInboundStarted event, Emitter<InboundState> emit) async {
    emit(state.copyWith(status: InboundStatus.loading));

    // Load cache first
    final cached = await offlineLocalCache.getInboundTransactions(limit: 20);
    if (cached.isNotEmpty) {
      emit(state.copyWith(
        status: InboundStatus.success,
        history: cached,
        isFromCache: true,
      ));
    }

    final online = await isOnline();
    if (!online) {
      if (cached.isEmpty) emit(state.copyWith(status: InboundStatus.failure));
      return;
    }

    try {
      final result = await useCase.getInboundList(page: 1, pageSize: 20);
      result.fold(
        (error) {
          if (cached.isEmpty) {
            emit(state.copyWith(status: InboundStatus.failure, responseError: error));
          }
        },
        (dto) {
          emit(state.copyWith(
            status: InboundStatus.success,
            history: dto.results,
            currentPage: 1,
            totalPages: dto.totalPages,
            isFromCache: false,
            clearResponseError: true,
          ));
          offlineLocalCache.saveInboundTransactions(dto.results);
        },
      );
    } catch (e) {
      if (cached.isEmpty) {
        emit(state.copyWith(status: InboundStatus.failure, responseError: e.toString()));
      }
    }
  }

  Future<void> _onLoadMore(OnInboundLoadMore event, Emitter<InboundState> emit) async {
    if (!state.hasMorePages) return;
    if (state.status == InboundStatus.loadingMore) return;
    emit(state.copyWith(status: InboundStatus.loadingMore));
    try {
      final nextPage = state.currentPage + 1;
      final result = await useCase.getInboundList(page: nextPage, pageSize: 20);
      result.fold(
        (_) => emit(state.copyWith(status: InboundStatus.success)),
        (dto) => emit(state.copyWith(
          status: InboundStatus.success,
          history: [...state.history, ...dto.results],
          currentPage: nextPage,
          totalPages: dto.totalPages,
        )),
      );
    } catch (_) {
      emit(state.copyWith(status: InboundStatus.success));
    }
  }

  Future<void> _onFormSubmit(OnInboundFormSubmit event, Emitter<InboundState> emit) async {
    if (state.submitStatus == InboundSubmitStatus.loading) return;
    emit(state.copyWith(
      submitStatus: InboundSubmitStatus.loading,
      clearSubmitError: true,
      queuedOffline: false,
    ));

    final online = await isOnline();
    if (!online) {
      final clientId = const Uuid().v4();
      await offlineInboundQueue.enqueue(
        clientInboundId: clientId,
        request: event.request,
      );
      emit(state.copyWith(
        submitStatus: InboundSubmitStatus.queued,
        queuedOffline: true,
      ));
      return;
    }

    try {
      final result = await useCase.createInboundTransaction(event.request);
      result.fold(
        (error) => emit(state.copyWith(
          submitStatus: InboundSubmitStatus.failure,
          submitError: error,
        )),
        (_) {
          emit(state.copyWith(submitStatus: InboundSubmitStatus.success));
          add(const OnInboundStarted());
        },
      );
    } catch (e) {
      emit(state.copyWith(
        submitStatus: InboundSubmitStatus.failure,
        submitError: e.toString(),
      ));
    }
  }

  void _onAcknowledge(OnInboundAcknowledge event, Emitter<InboundState> emit) {
    emit(state.copyWith(
      submitStatus: InboundSubmitStatus.idle,
      clearSubmitError: true,
      queuedOffline: false,
    ));
  }

  void _onReset(OnInboundReset event, Emitter<InboundState> emit) {
    emit(InboundState.initial());
  }
}
