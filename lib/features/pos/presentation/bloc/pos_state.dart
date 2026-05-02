part of 'pos_bloc.dart';

enum PosSubmitStatus { idle, loading, success, failure }

class PosState extends Equatable {
  final String searchQuery;
  final String? selectedCategoryId;
  final String paymentMethod;
  final List<PosCartItem> items;
  final PosSubmitStatus submitStatus;
  final String? submitError;

  const PosState({
    required this.searchQuery,
    required this.selectedCategoryId,
    required this.paymentMethod,
    required this.items,
    required this.submitStatus,
    this.submitError,
  });

  factory PosState.initial() {
    return const PosState(
      searchQuery: '',
      selectedCategoryId: null,
      paymentMethod: 'cash',
      items: [],
      submitStatus: PosSubmitStatus.idle,
    );
  }

  bool get isEmpty => items.isEmpty;

  int get itemCount => items.fold<int>(
    0,
        (sum, item) => sum + item.quantity,
  );

  double get subtotal => items.fold<double>(
    0,
        (sum, item) => sum + item.lineTotal,
  );

  double get total => subtotal;

  int quantityOf(String? productId) {
    if (productId == null) return 0;

    final index = items.indexWhere((item) => item.product.id == productId);
    if (index == -1) return 0;

    return items[index].quantity;
  }

  PosState copyWith({
    String? searchQuery,
    String? selectedCategoryId,
    bool clearSelectedCategory = false,
    String? paymentMethod,
    List<PosCartItem>? items,
    PosSubmitStatus? submitStatus,
    String? submitError,
  }) {
    return PosState(
      searchQuery: searchQuery ?? this.searchQuery,
      selectedCategoryId: clearSelectedCategory
          ? null
          : selectedCategoryId ?? this.selectedCategoryId,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      items: items ?? this.items,
      submitStatus: submitStatus ?? this.submitStatus,
      submitError: submitError,
    );
  }

  @override
  List<Object?> get props => [
    searchQuery,
    selectedCategoryId,
    paymentMethod,
    items,
    submitStatus,
    submitError,
  ];
}