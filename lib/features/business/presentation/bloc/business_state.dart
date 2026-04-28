part of 'business_bloc.dart';

enum BusinessStatus {
  initial,
  loading,
  success,
  failure,
}

class BusinessState extends Equatable {
  final bool isLoading;
  final String? responseError;
  final BusinessStatus businessStatus;

  const BusinessState({
    this.isLoading = false,
    this.responseError,
    this.businessStatus = BusinessStatus.initial,
  });

  factory BusinessState.initial() {
    return const BusinessState(
      isLoading: false,
      responseError: null,
      businessStatus: BusinessStatus.initial,
    );
  }

  BusinessState copyWith({
    bool? isLoading,
    String? responseError,
    BusinessStatus? businessStatus,
  }) {
    return BusinessState(
      isLoading: isLoading ?? this.isLoading,
      responseError: responseError,
      businessStatus: businessStatus ?? this.businessStatus,
    );
  }

  @override
  List<Object?> get props => [
    isLoading,
    responseError,
    businessStatus,
  ];
}
