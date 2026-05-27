import 'package:cine_book/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:cine_book/features/auth/domain/repositories/auth_repository.dart';
import 'package:cine_book/features/auth/presentation/bloc/auth_event.dart';
import 'package:cine_book/features/auth/presentation/bloc/auth_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository authRepository;

  AuthBloc({required this.authRepository}) : super(AuthInitial()) {
    on<AuthCheckRequested>((event, emit) {
      final user = authRepository.currentUser;
      if (user != null) {
        emit(Authenticated(user));
      } else {
        emit(Unauthenticated());
      }
    });

    on<AuthSignInWithPhoneRequested>((event, emit) async {
      emit(AuthLoading());
      try {
        await authRepository.signInWithPhone(
          phoneNumber: event.phoneNumber,
          codeSent: (verificationId, resendToken) {
            add(_AuthInternalCodeSent(verificationId));
          },
          verificationFailed: (e) {
            add(_AuthInternalError(e.message ?? 'Xác thực thất bại'));
          },
          verificationCompleted: (credential) async {
            // Auto-retrieval
          },
          codeAutoRetrievalTimeout: (verificationId) {},
        );
      } catch (e) {
        emit(AuthFailure(e.toString()));
      }
    });

    on<_AuthInternalCodeSent>((event, emit) {
      emit(AuthCodeSent(event.verificationId));
    });

    on<_AuthInternalError>((event, emit) {
      emit(AuthFailure(event.message));
    });

    on<AuthVerifyOTPRequested>((event, emit) async {
      emit(AuthLoading());
      try {
        final credential = await authRepository.verifyOTP(
          verificationId: event.verificationId,
          smsCode: event.smsCode,
        );
        if (credential.user != null) {
          emit(Authenticated(credential.user!));
        } else {
          emit(AuthFailure('Không thể đăng nhập'));
        }
      } catch (e) {
        if (e is MockAuthSuccessException) {
          // Handle mock success by emitting a neutral authenticated state
          // Since we don't have a real User object, we'll use null or a fake handling
          // In a prototype, this is enough to transition the UI
          emit(AuthInitial()); // Reset or transition
          // Re-trigger auth check which will find null but we can force it
          add(_AuthInternalMockSuccess());
        } else {
          emit(AuthFailure(e.toString()));
        }
      }
    });

    on<_AuthInternalMockSuccess>((event, emit) {
      emit(Unauthenticated()); // Transition to home anyway for prototype
    });

    on<AuthSignOutRequested>((event, emit) async {
      await authRepository.signOut();
      emit(Unauthenticated());
    });
  }
}

class _AuthInternalCodeSent extends AuthEvent {
  final String verificationId;
  _AuthInternalCodeSent(this.verificationId);
}

class _AuthInternalError extends AuthEvent {
  final String message;
  _AuthInternalError(this.message);
}

class _AuthInternalMockSuccess extends AuthEvent {}
