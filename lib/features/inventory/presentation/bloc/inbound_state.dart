part of 'inbound_bloc.dart';

enum InboundStatus { initial, loading, loadingMore, success, failure }
enum InboundSubmitStatus { idle, loading, success, queued, failure }

class InboundState extends Equatable {
  final InboundStatus status;
  final List<InboundTransactionData> history;
  final int currentPage;
  final int totalPages;
  final bool isFromCache;
  final String? responseError;
  final InboundSubmitStatus submitStatus;
  final String? submitError;
  final bool queuedOffline;

  const InboundState({
    this.status = InboundStatus.initial,
    this.history = const [],
    this.currentPage = 1,
    this.totalPages = 1,
    this.isFromCache = false,
    this.responseError,
    this.submitStatus = InboundSubmitStatus.idle,
    this.submitError,
    this.queuedOffline = false,
  });

  factory InboundState.initial() => const InboundState();

  bool get hasMorePages => !isFromCache && currentPage < totalPages;

  InboundState copyWith({
    InboundStatus? status,
    List<InboundTransactionData>? history,
    int? currentPage,
    int? totalPages,
    bool? isFromCache,
    String? responseError,
    bool clearResponseError = false,
    InboundSubmitStatus? submitStatus,
    String? submitError,
    bool clearSubmitError = false,
    bool? queuedOffline,
  }) {
    return InboundState(
      status: status ?? this.status,
      history: history ?? this.history,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      isFromCache: isFromCache ?? this.isFromCache,
      responseError: clearResponseError ? null : responseError ?? this.responseError,
      submitStatus: submitStatus ?? this.submitStatus,
      submitError: clearSubmitError ? null : submitError ?? this.submitError,
      queuedOffline: queuedOffline ?? this.queuedOffline,
    );
  }

  @override
  List<Object?> get props => [
    status, history, currentPage, totalPages, isFromCache,
    responseError, submitStatus, submitError, queuedOffline,
  ];
}
