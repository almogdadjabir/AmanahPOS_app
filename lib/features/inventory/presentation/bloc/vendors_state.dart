part of 'vendors_bloc.dart';

enum VendorsStatus { initial, loading, success, failure }
enum VendorsSubmitStatus { idle, loading, success, failure }

class VendorsState extends Equatable {
  final VendorsStatus status;
  final List<VendorData> vendors;
  final String? responseError;
  final VendorsSubmitStatus submitStatus;
  final String? submitError;

  const VendorsState({
    this.status = VendorsStatus.initial,
    this.vendors = const [],
    this.responseError,
    this.submitStatus = VendorsSubmitStatus.idle,
    this.submitError,
  });

  factory VendorsState.initial() => const VendorsState();

  VendorsState copyWith({
    VendorsStatus? status,
    List<VendorData>? vendors,
    String? responseError,
    bool clearResponseError = false,
    VendorsSubmitStatus? submitStatus,
    String? submitError,
    bool clearSubmitError = false,
  }) {
    return VendorsState(
      status: status ?? this.status,
      vendors: vendors ?? this.vendors,
      responseError: clearResponseError ? null : responseError ?? this.responseError,
      submitStatus: submitStatus ?? this.submitStatus,
      submitError: clearSubmitError ? null : submitError ?? this.submitError,
    );
  }

  @override
  List<Object?> get props => [status, vendors, responseError, submitStatus, submitError];
}
