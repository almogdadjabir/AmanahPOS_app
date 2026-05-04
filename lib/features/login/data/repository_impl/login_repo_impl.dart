import 'package:amana_pos/core/api/request_handler.dart';
import 'package:amana_pos/features/login/data/models/login_request.dart';
import 'package:amana_pos/features/login/data/models/login_response.dart';
import 'package:amana_pos/features/login/data/models/otp_resend_response.dart';
import 'package:amana_pos/features/login/data/models/otp_verify_request.dart';
import 'package:amana_pos/features/login/data/models/otp_verify_response.dart';
import 'package:amana_pos/features/login/data/models/user_profile_dto.dart';
import 'package:amana_pos/features/login/domain/repository/login_repository.dart';
import 'package:amana_pos/features/settings/data/models/set_password_request_dto.dart';
import 'package:amana_pos/features/settings/data/models/update_profile_request_dto.dart';
import 'package:fpdart/fpdart.dart';

class LoginRepoImpl extends LoginRepository {
  LoginRepoImpl(this.requestHandler);
  final RequestHandler requestHandler;

  @override
  Future<Either<String?, LoginResponse>> userLogin(LoginRequest request) {
    return requestHandler.handlePostRequest(
      'api-public/v1/auth/login/otp/',
          (data) => LoginResponse.fromJson(data as Map<String, dynamic>),
      data: request.toJson(),
    );
  }

  @override
  Future<Either<String?, OtpVerifyResponse>> otpVerify(OtpVerifyRequest request) {
    return requestHandler.handlePostRequest(
      'api-public/v1/auth/login/otp/verify/',
          (data) => OtpVerifyResponse.fromJson(data as Map<String, dynamic>),
      data: request.toJson(),
    );
  }

  @override
  Future<Either<String?, OtpResendResponse>> otpResend() {
    return requestHandler.handlePostRequest(
      'api-public/v1/auth/resend-otp/',
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
      '/api/v1/auth/profile/',
          (data) => UserProfileDto.fromJson(data as Map<String, dynamic>),
    );
  }

  @override
  Future<Either<String?, UserProfileDto>> updateProfile(UpdateProfileRequestDto request) {
    return requestHandler.handlePatchRequest(
      '/api/v1/auth/profile/',
          (data) => UserProfileDto.fromJson(data as Map<String, dynamic>),
      data: request.toJson()
    );
  }

  @override
  Future<Either<String?, bool>> setPassword(SetPasswordRequestDto request) {
    return requestHandler.handlePostRequest(
      '/api/v1/auth/set-password/',
          (data) => true,
      data: request.toJson()
    );
  }


}