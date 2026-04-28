part of 'users_bloc.dart';

enum UserStatus { initial, loading, success, failure }
enum UserSubmitStatus { idle, loading, success, failure }

class UserState extends Equatable {
  final UserStatus userStatus;
  final UserSubmitStatus submitStatus;
  final List<UserData> userList;
  final String? responseError;
  final String? submitError;

  const UserState({
    this.userStatus = UserStatus.initial,
    this.submitStatus = UserSubmitStatus.idle,
    this.userList = const [],
    this.responseError,
    this.submitError,
  });

  factory UserState.initial() => const UserState(
    userStatus: UserStatus.initial,
    submitStatus: UserSubmitStatus.idle,
    userList: [],
  );

  UserState copyWith({
    UserStatus? userStatus,
    UserSubmitStatus? submitStatus,
    List<UserData>? userList,
    String? responseError,
    String? submitError,
  }) {
    return UserState(
      userStatus: userStatus ?? this.userStatus,
      submitStatus: submitStatus ?? this.submitStatus,
      userList: userList ?? this.userList,
      responseError: responseError,
      submitError: submitError,
    );
  }

  @override
  List<Object?> get props => [
    userStatus, submitStatus,
    userList, responseError, submitError,
  ];
}