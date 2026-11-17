part of 'vendors_bloc.dart';

abstract class VendorsEvent extends Equatable {
  const VendorsEvent();
}

class OnVendorsStarted extends VendorsEvent {
  const OnVendorsStarted();
  @override
  List<Object?> get props => [];
}

/// A local write or a pull touched [VendorsBloc.watchedTables]: re-read.
class OnVendorsChanged extends VendorsEvent {
  const OnVendorsChanged();
  @override
  List<Object?> get props => [];
}

/// Pull to refresh: ask the server for changes (see `requestCatalogSync`).
class OnVendorsSyncRequested extends VendorsEvent {
  const OnVendorsSyncRequested();
  @override
  List<Object?> get props => [];
}

class OnVendorCreate extends VendorsEvent {
  final CreateVendorRequestDto request;
  const OnVendorCreate(this.request);
  @override
  List<Object?> get props => [request];
}

class OnVendorUpdate extends VendorsEvent {
  final String id;
  final UpdateVendorRequestDto request;
  const OnVendorUpdate(this.id, this.request);
  @override
  List<Object?> get props => [id, request];
}

class OnVendorDelete extends VendorsEvent {
  final String id;
  const OnVendorDelete(this.id);
  @override
  List<Object?> get props => [id];
}

class OnVendorsReset extends VendorsEvent {
  const OnVendorsReset();
  @override
  List<Object?> get props => [];
}
