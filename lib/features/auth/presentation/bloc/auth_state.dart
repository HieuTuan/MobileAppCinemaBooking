import 'package:firebase_auth/firebase_auth.dart';

abstract class AuthState {}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class Authenticated extends AuthState {
  final User user;
  Authenticated(this.user);
}

class Unauthenticated extends AuthState {}

class AuthCodeSent extends AuthState {
  final String verificationId;
  AuthCodeSent(this.verificationId);
}

class AuthFailure extends AuthState {
  final String message;
  AuthFailure(this.message);
}
