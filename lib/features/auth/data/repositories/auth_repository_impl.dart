import 'package:cine_book/features/auth/domain/repositories/auth_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class AuthRepositoryImpl implements AuthRepository {
  // Safe getter for FirebaseAuth instance
  FirebaseAuth? get _auth {
    try {
      if (Firebase.apps.isNotEmpty) {
        return FirebaseAuth.instance;
      }
    } catch (e) {
      debugPrint('AuthRepository: Firebase not ready yet: $e');
    }
    return null;
  }

  @override
  Stream<User?> get authStateChanges => _auth?.authStateChanges() ?? Stream.value(null);

  @override
  User? get currentUser => _auth?.currentUser;

  @override
  Future<UserCredential> signInWithGoogle() async {
    throw UnimplementedError('Google Sign-In requires valid configuration.');
  }

  @override
  Future<void> signInWithPhone({
    required String phoneNumber,
    required Function(String verificationId, int? resendToken) codeSent,
    required Function(FirebaseAuthException e) verificationFailed,
    required Function(PhoneAuthCredential credential) verificationCompleted,
    required Function(String verificationId) codeAutoRetrievalTimeout,
  }) async {
    final instance = _auth;
    if (instance == null) {
      // PROTOTYPE MODE: Success by default for development
      debugPrint('AuthRepository: Entering Mock Phone Auth Mode');
      await Future.delayed(const Duration(seconds: 1));
      codeSent('mock_verification_id', null);
      return;
    }

    await instance.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: verificationCompleted,
      verificationFailed: verificationFailed,
      codeSent: codeSent,
      codeAutoRetrievalTimeout: codeAutoRetrievalTimeout,
    );
  }

  @override
  Future<UserCredential> verifyOTP({
    required String verificationId,
    required String smsCode,
  }) async {
    final instance = _auth;
    if (instance == null || verificationId == 'mock_verification_id') {
      // PROTOTYPE MODE: Validate mock OTP
      if (smsCode == '123456') {
        throw MockAuthSuccessException();
      } else {
        throw Exception('Mã OTP không hợp lệ (Thử: 123456)');
      }
    }

    PhoneAuthCredential credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );
    return await instance.signInWithCredential(credential);
  }

  @override
  Future<void> signOut() async {
    await _auth?.signOut();
  }
}

class MockAuthSuccessException implements Exception {
  final String message = "Mock Login Successful";
}
