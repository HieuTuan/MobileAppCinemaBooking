import 'package:firebase_auth/firebase_auth.dart';

abstract class AuthRepository {
  Stream<User?> get authStateChanges;
  Future<UserCredential> signInWithGoogle();
  Future<void> signInWithPhone({
    required String phoneNumber,
    required Function(String verificationId, int? resendToken) codeSent,
    required Function(FirebaseAuthException e) verificationFailed,
    required Function(PhoneAuthCredential credential) verificationCompleted,
    required Function(String verificationId) codeAutoRetrievalTimeout,
  });
  Future<UserCredential> verifyOTP({
    required String verificationId,
    required String smsCode,
  });
  Future<void> signOut();
  User? get currentUser;
}
