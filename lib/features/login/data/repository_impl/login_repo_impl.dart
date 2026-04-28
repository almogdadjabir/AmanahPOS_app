import 'package:amana_pos/api/request_handler.dart';
import 'package:amana_pos/features/login/data/models/login_request.dart';
import 'package:amana_pos/features/login/data/models/login_response.dart';
import 'package:amana_pos/features/login/data/models/otp_resend_response.dart';
import 'package:amana_pos/features/login/data/models/otp_verify_request.dart';
import 'package:amana_pos/features/login/data/models/otp_verify_response.dart';
import 'package:amana_pos/features/login/data/models/user_profile_dto.dart';
import 'package:amana_pos/features/login/domain/repository/login_repository.dart';
import 'package:fpdart/fpdart.dart';

class LoginRepoImpl extends LoginRepository {
  LoginRepoImpl(this.requestHandler);
  final RequestHandler requestHandler;

  @override
  Future<Either<String?, LoginResponse>> userLogin(LoginRequest request) {
    return requestHandler.handlePostRequest(
      'auth/login/otp/',
          (data) => LoginResponse.fromJson(data as Map<String, dynamic>),
      data: request.toJson(),
    );
  }

  @override
  Future<Either<String?, OtpVerifyResponse>> otpVerify(OtpVerifyRequest request) {
    return requestHandler.handlePostRequest(
      'auth/login/otp/verify/',
          (data) => OtpVerifyResponse.fromJson(data as Map<String, dynamic>),
      data: request.toJson(),
    );
  }

  @override
  Future<Either<String?, OtpResendResponse>> otpResend() {
    return requestHandler.handlePostRequest(
      'api/v1/otp/resend',
          (data) => OtpResendResponse.fromJson(data as Map<String, dynamic>),
    );
  }

  @override
  Future<Either<String?, User>> logout() {
    return requestHandler.handlePostRequest(
      'auth/logout/',
          (data) => User.fromJson(data as Map<String, dynamic>),
    );
  }

  @override
  Future<Either<String?, UserProfileDto>> getProfile() {
    return requestHandler.handleGetRequest(
      'auth/profile/',
          (data) => UserProfileDto.fromJson(data as Map<String, dynamic>),
    );
  }


}