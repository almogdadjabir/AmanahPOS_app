import 'package:amana_pos/common/services/local/local_storage.dart';
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

class LoginUseCase {
  final LoginRepository repository;
  final CacheStorage cacheStorage;

  LoginUseCase({
    required this.repository,
    required this.cacheStorage,
  });

  Future<Either<String?, LoginResponse>> userLogin(LoginRequest request) => repository.userLogin(request);
  Future<Either<String?, OtpVerifyResponse>> otpVerify(OtpVerifyRequest request) => repository.otpVerify(request);
  Future<Either<String?, OtpResendResponse>> otpResend() => repository.otpResend();

  Future<Either<String?, UserProfileDto>> getProfile() => repository.getProfile();

  Future<Either<String?, UserProfileDto>> updateProfile(UpdateProfileRequestDto request) => repository.updateProfile(request);
  Future<Either<String?, bool>> setPassword(SetPasswordRequestDto request) => repository.setPassword(request);
  Future<Either<String?, User>> logout(dynamic request) => repository.logout(request);

}
