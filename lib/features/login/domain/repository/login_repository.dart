import 'package:amana_pos/features/login/data/models/login_request.dart';
import 'package:amana_pos/features/login/data/models/login_response.dart';
import 'package:amana_pos/features/login/data/models/otp_resend_response.dart';
import 'package:amana_pos/features/login/data/models/otp_verify_request.dart';
import 'package:amana_pos/features/login/data/models/otp_verify_response.dart';
import 'package:amana_pos/features/login/data/models/user_profile_dto.dart';
import 'package:amana_pos/features/settings/data/models/update_profile_request_dto.dart';
import 'package:amana_pos/features/settings/data/models/set_password_request_dto.dart';
import 'package:fpdart/fpdart.dart';

abstract class LoginRepository {
  Future<Either<String?, LoginResponse>> userLogin(LoginRequest request);
  Future<Either<String?, OtpVerifyResponse>> otpVerify(OtpVerifyRequest request);
  Future<Either<String?, OtpResendResponse>> otpResend();
  Future<Either<String?, UserProfileDto>> getProfile();
  Future<Either<String?, User>> logout();
  Future<Either<String?, UserProfileDto>> updateProfile(UpdateProfileRequestDto request);
  Future<Either<String?, bool>> setPassword(SetPasswordRequestDto request);
}