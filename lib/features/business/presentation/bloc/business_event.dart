part of 'business_bloc.dart';

abstract class BusinessEvent extends Equatable {
  const BusinessEvent();
}

class OnBusinessInitial extends BusinessEvent {
  const OnBusinessInitial();
  @override
  List<Object?> get props => [];
}

class OnEditBusiness extends BusinessEvent {
  final String businessId;
  final String name;
  final String? address;
  final String? phone;
  final String? email;
  final bool? taxEnabled;
  final String? taxName;
  final double? taxRate;
  final bool? taxInclusive;

  const OnEditBusiness({
    required this.businessId,
    required this.name,
    this.address,
    this.phone,
    this.email,
    this.taxEnabled,
    this.taxName,
    this.taxRate,
    this.taxInclusive,
  });

  @override
  List<Object?> get props => [
    businessId,
    name,
    address,
    phone,
    email,
    taxEnabled,
    taxName,
    taxRate,
    taxInclusive,
  ];
}

class OnAddBusiness extends BusinessEvent {
  final String name;
  final String? address;
  final String? phone;
  final String? email;

  const OnAddBusiness({
    required this.name,
    this.address,
    this.phone,
    this.email,
  });

  @override
  List<Object?> get props => [name, address, phone, email];
}

class OnDeactivateBusiness extends BusinessEvent {
  final String businessId;
  const OnDeactivateBusiness({required this.businessId});

  @override
  List<Object?> get props => [businessId];
}

class OnAddShop extends BusinessEvent {
  final String businessId;
  final String name;
  final String? address;
  final String? phone;

  const OnAddShop({
    required this.businessId,
    required this.name,
    this.address,
    this.phone,
  });

  @override
  List<Object?> get props => [businessId, name, address, phone];
}

class OnEditShop extends BusinessEvent {
  final String businessId;
  final String shopId;
  final String name;
  final String? address;
  final String? phone;
  final bool? isActive;

  const OnEditShop({
    required this.businessId,
    required this.shopId,
    required this.name,
    this.address,
    this.phone,
    this.isActive,
  });

  @override
  List<Object?> get props => [
    businessId,
    shopId,
    name,
    address,
    phone,
    isActive,
  ];
}

class OnBusinessReset extends BusinessEvent {
  const OnBusinessReset();

  @override
  List<Object?> get props => throw UnimplementedError();
}
