part of 'premium_inventory_bloc.dart';

abstract class PremiumInventoryEvent extends Equatable {
  const PremiumInventoryEvent();
}

class OnPremiumInventoryStarted extends PremiumInventoryEvent {
  const OnPremiumInventoryStarted();
  @override List<Object?> get props => [];
}

class OnPremiumInventoryRefreshed extends PremiumInventoryEvent {
  const OnPremiumInventoryRefreshed();
  @override List<Object?> get props => [];
}

class OnPremiumInventoryReset extends PremiumInventoryEvent {
  const OnPremiumInventoryReset();
  @override List<Object?> get props => [];
}
