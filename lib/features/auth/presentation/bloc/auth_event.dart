abstract class AuthEvent {}

class AuthCheckRequested extends AuthEvent {}

class AuthSignInWithGoogleRequested extends AuthEvent {}

class AuthSignInWithPhoneRequested extends AuthEvent {
  final String phoneNumber;
  AuthSignInWithPhoneRequested(this.phoneNumber);
}

class AuthVerifyOTPRequested extends AuthEvent {
  final String verificationId;
  final String smsCode;
  AuthVerifyOTPRequested(this.verificationId, this.smsCode);
}

class AuthSignOutRequested extends AuthEvent {}
