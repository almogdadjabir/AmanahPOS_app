part of 'returns_bloc.dart';

abstract class ReturnsEvent extends Equatable {
  const ReturnsEvent();
  @override
  List<Object?> get props => [];
}

class ReturnsSearchChanged extends ReturnsEvent {
  final String query;
  const ReturnsSearchChanged(this.query);
  @override
  List<Object?> get props => [query];
}

class ReturnsSaleSelected extends ReturnsEvent {
  final SaleHistoryItem sale;
  const ReturnsSaleSelected(this.sale);
  @override
  List<Object?> get props => [sale.id];
}

class ReturnsItemToggled extends ReturnsEvent {
  final String productId;
  const ReturnsItemToggled(this.productId);
  @override
  List<Object?> get props => [productId];
}

class ReturnsQuantityChanged extends ReturnsEvent {
  final String productId;
  final int quantity;
  const ReturnsQuantityChanged(this.productId, this.quantity);
  @override
  List<Object?> get props => [productId, quantity];
}

class ReturnsAllToggled extends ReturnsEvent {
  const ReturnsAllToggled();
}

class ReturnsSubmitted extends ReturnsEvent {
  final String? notes;
  const ReturnsSubmitted({this.notes});
  @override
  List<Object?> get props => [notes];
}

class ReturnsReset extends ReturnsEvent {
  const ReturnsReset();
}

class ReturnsPreloadSale extends ReturnsEvent {
  final SaleHistoryItem sale;
  const ReturnsPreloadSale(this.sale);
  @override
  List<Object?> get props => [sale.id];
}
