part of 'business_bloc.dart';

enum BusinessSubmitStatus { idle, loading, success, failure }
enum BusinessStatus { initial, loading, success, failure}

class BusinessState extends Equatable {
  final bool isLoading;
  final String? responseError;
  final BusinessStatus businessStatus;
  final List<BusinessData>? businessList;
  final BusinessSubmitStatus submitStatus;
  final String? submitError;

  const BusinessState({
    this.isLoading = false,
    this.responseError,
    this.businessStatus = BusinessStatus.initial,
    this.businessList,
    this.submitStatus = BusinessSubmitStatus.idle,
    this.submitError,
  });

  factory BusinessState.initial() => const BusinessState(
    isLoading: false,
    businessStatus: BusinessStatus.initial,
    businessList: [],
    submitStatus: BusinessSubmitStatus.idle,
  );

  BusinessState copyWith({
    bool? isLoading,
    String? responseError,
    bool clearResponseError = false,
    BusinessStatus? businessStatus,
    List<BusinessData>? businessList,
    BusinessSubmitStatus? submitStatus,
    String? submitError,
    bool clearSubmitError = false,
  }) {
    return BusinessState(
      isLoading: isLoading ?? this.isLoading,
      responseError: clearResponseError
          ? null
          : responseError ?? this.responseError,
      businessStatus: businessStatus ?? this.businessStatus,
      businessList: businessList ?? this.businessList,
      submitStatus: submitStatus ?? this.submitStatus,
      submitError: clearSubmitError
          ? null
          : submitError ?? this.submitError,
    );
  }

  @override
  List<Object?> get props => [
    isLoading, responseError, businessStatus,
    businessList, submitStatus, submitError,
  ];
}