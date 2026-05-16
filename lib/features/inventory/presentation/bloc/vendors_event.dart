part of 'vendors_bloc.dart';

abstract class VendorsEvent extends Equatable {
  const VendorsEvent();
}

class OnVendorsStarted extends VendorsEvent {
  const OnVendorsStarted();
  @override List<Object?> get props => [];
}

class OnVendorCreate extends VendorsEvent {
  final CreateVendorRequestDto request;
  const OnVendorCreate(this.request);
  @override List<Object?> get props => [request];
}

class OnVendorUpdate extends VendorsEvent {
  final String id;
  final UpdateVendorRequestDto request;
  const OnVendorUpdate(this.id, this.request);
  @override List<Object?> get props => [id, request];
}

class OnVendorDelete extends VendorsEvent {
  final String id;
  const OnVendorDelete(this.id);
  @override List<Object?> get props => [id];
}

class OnVendorsReset extends VendorsEvent {
  const OnVendorsReset();
  @override List<Object?> get props => [];
}
