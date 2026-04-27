import 'package:amana_pos/features/login/data/models/login_request.dart';
import 'package:amana_pos/features/login/data/models/login_response.dart';
import 'package:amana_pos/features/login/data/models/otp_resend_response.dart';
import 'package:amana_pos/features/login/data/models/otp_verify_request.dart';
import 'package:amana_pos/features/login/data/models/otp_verify_response.dart';
import 'package:fpdart/fpdart.dart';

abstract class LoginRepository {
  Future<Either<String?, LoginResponse>> userLogin(LoginRequest request);
  Future<Either<String?, OtpVerifyResponse>> otpVerify(OtpVerifyRequest request);
  Future<Either<String?, OtpResendResponse>> otpResend();
}