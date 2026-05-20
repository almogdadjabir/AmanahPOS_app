part of 'returns_bloc.dart';

enum ReturnsSearchStatus { idle, loading, success, failure }
enum ReturnsSubmitStatus { idle, loading, success, failure }

class ReturnsState extends Equatable {
  final String searchQuery;
  final ReturnsSearchStatus searchStatus;
  final List<SaleHistoryItem> searchResults;
  final SaleHistoryItem? selectedSale;
  final Map<String, int> selectedItems;
  final ReturnsSubmitStatus submitStatus;
  final RefundResponseDto? refundResult;
  final String? errorMessage;

  const ReturnsState({
    required this.searchQuery,
    required this.searchStatus,
    required this.searchResults,
    required this.selectedSale,
    required this.selectedItems,
    required this.submitStatus,
    required this.refundResult,
    required this.errorMessage,
  });

  factory ReturnsState.initial() => const ReturnsState(
        searchQuery: '',
        searchStatus: ReturnsSearchStatus.idle,
        searchResults: [],
        selectedSale: null,
        selectedItems: {},
        submitStatus: ReturnsSubmitStatus.idle,
        refundResult: null,
        errorMessage: null,
      );

  double get refundTotal {
    final sale = selectedSale;
    if (sale == null) return 0;
    double total = 0;
    for (final entry in selectedItems.entries) {
      final lineItem = sale.items
          .cast<SaleHistoryLineItem?>()
          .firstWhere((i) => i?.productId == entry.key, orElse: () => null);
      if (lineItem != null) {
        total += lineItem.unitPrice * entry.value;
      }
    }
    return total;
  }

  bool get hasSelection => selectedItems.isNotEmpty;
  bool get allSelected => selectedSale != null &&
      selectedItems.length == selectedSale!.items.length;

  ReturnsState copyWith({
    String? searchQuery,
    ReturnsSearchStatus? searchStatus,
    List<SaleHistoryItem>? searchResults,
    SaleHistoryItem? selectedSale,
    bool clearSelectedSale = false,
    Map<String, int>? selectedItems,
    ReturnsSubmitStatus? submitStatus,
    RefundResponseDto? refundResult,
    String? errorMessage,
  }) {
    return ReturnsState(
      searchQuery: searchQuery ?? this.searchQuery,
      searchStatus: searchStatus ?? this.searchStatus,
      searchResults: searchResults ?? this.searchResults,
      selectedSale:
          clearSelectedSale ? null : (selectedSale ?? this.selectedSale),
      selectedItems: selectedItems ?? this.selectedItems,
      submitStatus: submitStatus ?? this.submitStatus,
      refundResult: refundResult ?? this.refundResult,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        searchQuery, searchStatus, searchResults, selectedSale,
        selectedItems, submitStatus, refundResult, errorMessage,
      ];
}
