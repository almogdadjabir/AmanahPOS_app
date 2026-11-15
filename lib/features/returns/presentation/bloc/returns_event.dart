part of 'returns_bloc.dart';

abstract class ReturnsEvent extends Equatable {
  const ReturnsEvent();
  @override
  List<Object?> get props => [];
}

/// Opens the return flow for [sale] with nothing selected.
class ReturnsStarted extends ReturnsEvent {
  final SaleHistoryItem sale;
  const ReturnsStarted(this.sale);
  @override
  List<Object?> get props => [sale.id];
}

/// Tap on a line: selects it at the full returnable quantity, or clears it.
class ReturnsLineToggled extends ReturnsEvent {
  final String lineId;
  const ReturnsLineToggled(this.lineId);
  @override
  List<Object?> get props => [lineId];
}

/// Sets the quantity of a selected line. Clamped to what is left to return;
/// 0 or less clears the line.
class ReturnsQuantityChanged extends ReturnsEvent {
  final String lineId;
  final double quantity;
  const ReturnsQuantityChanged(this.lineId, this.quantity);
  @override
  List<Object?> get props => [lineId, quantity];
}

/// Select every line that still has something to return, or clear all.
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
