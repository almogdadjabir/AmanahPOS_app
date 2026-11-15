part of 'returns_bloc.dart';

enum ReturnsSubmitStatus { idle, loading, success, failure }

class ReturnsState extends Equatable {
  final SaleHistoryItem? sale;

  /// Selected sale lines: server line id -> quantity to return.
  final Map<String, double> selected;
  final ReturnsSubmitStatus submitStatus;
  final RefundResponseDto? refundResult;
  final String? errorMessage;

  const ReturnsState({
    required this.sale,
    required this.selected,
    required this.submitStatus,
    required this.refundResult,
    required this.errorMessage,
  });

  factory ReturnsState.initial() => const ReturnsState(
        sale: null,
        selected: {},
        submitStatus: ReturnsSubmitStatus.idle,
        refundResult: null,
        errorMessage: null,
      );

  SaleHistoryLineItem? lineById(String lineId) {
    for (final l in sale?.items ?? const <SaleHistoryLineItem>[]) {
      if (l.lineId == lineId) return l;
    }
    return null;
  }

  double get refundTotal {
    double total = 0;
    for (final e in selected.entries) {
      final line = lineById(e.key);
      if (line != null) total += line.unitPrice * e.value;
    }
    return total;
  }

  bool get hasSelection => selected.isNotEmpty;

  int get selectedLineCount => selected.length;

  /// Lines that still have something to return.
  List<SaleHistoryLineItem> get returnableLines => [
        for (final l in sale?.items ?? const <SaleHistoryLineItem>[])
          if (l.returnableQuantity > 0) l,
      ];

  bool get allSelected =>
      returnableLines.isNotEmpty &&
      returnableLines.every((l) => selected.containsKey(l.lineId));

  ReturnsState copyWith({
    SaleHistoryItem? sale,
    Map<String, double>? selected,
    ReturnsSubmitStatus? submitStatus,
    RefundResponseDto? refundResult,
    String? errorMessage,
  }) {
    return ReturnsState(
      sale: sale ?? this.sale,
      selected: selected ?? this.selected,
      submitStatus: submitStatus ?? this.submitStatus,
      refundResult: refundResult ?? this.refundResult,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props =>
      [sale, selected, submitStatus, refundResult, errorMessage];
}
