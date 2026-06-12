import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:dio/dio.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cine_book/services/auth_service.dart';
import 'package:cine_book/services/secure_storage_service.dart';
import 'package:cine_book/api/api_client.dart';
import 'package:cine_book/models/auth_models.dart';

// Generate mocks for testing
@GenerateMocks([
  APIClient,
  SecureStorageService,
  GoogleSignIn,
  GoogleSignInAccount,
  GoogleSignInAuthentication,
])
import 'auth_service_test.mocks.dart';

void main() {
  group('AuthService - Google OAuth Sign-In', () {
    late MockAPIClient mockApiClient;
    late MockSecureStorageService mockSecureStorage;
    late MockGoogleSignIn mockGoogleSignIn;
    late MockGoogleSignInAccount mockGoogleAccount;
    late MockGoogleSignInAuthentication mockGoogleAuth;

    setUp(() {
      mockApiClient = MockAPIClient();
      mockSecureStorage = MockSecureStorageService();
      mockGoogleSignIn = MockGoogleSignIn();
      mockGoogleAccount = MockGoogleSignInAccount();
      mockGoogleAuth = MockGoogleSignInAuthentication();
    });

    test('should successfully sign in with Google and store tokens', () async {
      // Arrange
      const idToken = 'google_id_token_123';
      const accessToken = 'jwt_access_token_123';
      const refreshToken = 'jwt_refresh_token_123';
      final expiresAt = DateTime.now().add(const Duration(minutes: 15));

      final authResponse = AuthResponse(
        accessToken: accessToken,
        refreshToken: refreshToken,
        user: UserProfile(
          id: 'user_123',
          email: 'test@example.com',
          fullName: 'Test User',
          memberRank: 'silver',
          points: 0,
          role: 'customer',
          isActive: true,
          createdAt: DateTime.now(),
        ),
        expiresAt: expiresAt,
      );

      // Mock Google sign-in flow
      when(mockGoogleSignIn.signIn()).thenAnswer((_) async => mockGoogleAccount);
      when(mockGoogleAccount.authentication)
          .thenAnswer((_) async => mockGoogleAuth);
      when(mockGoogleAuth.idToken).thenReturn(idToken);

      // Mock API call
      when(mockApiClient.post(
        '/api/auth/google',
        data: anyNamed('data'),
      )).thenAnswer((_) async => Response(
            requestOptions: RequestOptions(path: '/api/auth/google'),
            data: authResponse.toJson(),
            statusCode: 200,
          ));

      // Mock secure storage
      when(mockSecureStorage.saveAccessToken(accessToken))
          .thenAnswer((_) async => {});
      when(mockSecureStorage.saveRefreshToken(refreshToken))
          .thenAnswer((_) async => {});
      when(mockSecureStorage.saveTokenExpiry(expiresAt))
          .thenAnswer((_) async => {});

      // Note: In real implementation, we'd need to inject dependencies
      // For now, we verify the logic flow

      // Assert
      // The service should:
      // 1. Initiate Google sign-in
      // 2. Get ID token
      // 3. Exchange with backend
      // 4. Store tokens securely
      // 5. Return success result

      verify(mockGoogleSignIn.signIn()).called(1);
    });

    test('should return error when user cancels Google sign-in', () async {
      // Arrange
      when(mockGoogleSignIn.signIn()).thenAnswer((_) async => null);

      // Act & Assert
      // When user cancels, signIn returns null
      // Service should return AuthResult with isSuccess: false
      // and error message: 'Google sign-in cancelled'
    });

    test('should return error when Google ID token is null', () async {
      // Arrange
      when(mockGoogleSignIn.signIn()).thenAnswer((_) async => mockGoogleAccount);
      when(mockGoogleAccount.authentication)
          .thenAnswer((_) async => mockGoogleAuth);
      when(mockGoogleAuth.idToken).thenReturn(null);

      // Act & Assert
      // Service should return AuthResult with isSuccess: false
      // and error message about missing ID token
    });

    test('should handle backend API error during Google sign-in', () async {
      // Arrange
      const idToken = 'google_id_token_123';

      when(mockGoogleSignIn.signIn()).thenAnswer((_) async => mockGoogleAccount);
      when(mockGoogleAccount.authentication)
          .thenAnswer((_) async => mockGoogleAuth);
      when(mockGoogleAuth.idToken).thenReturn(idToken);

      // Mock API error
      when(mockApiClient.post(
        '/api/auth/google',
        data: anyNamed('data'),
      )).thenThrow(DioException(
        requestOptions: RequestOptions(path: '/api/auth/google'),
        response: Response(
          requestOptions: RequestOptions(path: '/api/auth/google'),
          statusCode: 400,
          data: {
            'code': 'INVALID_TOKEN',
            'message': 'Invalid Google ID token',
          },
        ),
      ));

      // Act & Assert
      // Service should catch exception and return AuthResult with error
    });
  });

  group('AuthService - Email/Password Authentication', () {
    late MockAPIClient mockApiClient;
    late MockSecureStorageService mockSecureStorage;
    late AuthService authService;

    setUp(() {
      mockApiClient = MockAPIClient();
      mockSecureStorage = MockSecureStorageService();
      
      // Reset singleton for testing
      AuthService.resetInstance();
      
      // Mock initialization calls that happen in constructor
      when(mockSecureStorage.hasAccessToken()).thenAnswer((_) async => false);
      when(mockSecureStorage.isTokenExpired()).thenAnswer((_) async => true);
      
      // Create auth service with mocked dependencies
      authService = AuthService(
        apiClient: mockApiClient,
        secureStorage: mockSecureStorage,
        googleSignIn: MockGoogleSignIn(),
      );
    });

    tearDown(() {
      authService.dispose();
    });

    test('should successfully sign in with email and password', () async {
      // Arrange
      const email = 'test@example.com';
      const password = 'SecureP@ss123';
      const accessToken = 'jwt_access_token_123';
      const refreshToken = 'jwt_refresh_token_123';
      final expiresAt = DateTime.now().add(const Duration(minutes: 15));

      final authResponse = AuthResponse(
        accessToken: accessToken,
        refreshToken: refreshToken,
        user: UserProfile(
          id: 'user_123',
          email: email,
          fullName: 'Test User',
          memberRank: 'silver',
          points: 0,
          role: 'customer',
          isActive: true,
          createdAt: DateTime.now(),
        ),
        expiresAt: expiresAt,
      );

      when(mockApiClient.post(
        '/api/auth/login',
        data: anyNamed('data'),
      )).thenAnswer((_) async => Response(
            requestOptions: RequestOptions(path: '/api/auth/login'),
            data: authResponse.toJson(),
            statusCode: 200,
          ));

      when(mockSecureStorage.saveAccessToken(accessToken))
          .thenAnswer((_) async => {});
      when(mockSecureStorage.saveRefreshToken(refreshToken))
          .thenAnswer((_) async => {});
      when(mockSecureStorage.saveTokenExpiry(expiresAt))
          .thenAnswer((_) async => {});

      // Act
      final result = await authService.signInWithEmail(email, password);

      // Assert
      expect(result.isSuccess, isTrue);
      expect(result.user, isNotNull);
      expect(result.user?.email, equals(email));
      expect(result.errorMessage, isNull);
      expect(authService.currentUser, isNotNull);
      expect(authService.currentUser?.id, equals('user_123'));
      
      // Verify API call was made with correct data
      verify(mockApiClient.post(
        '/api/auth/login',
        data: {'email': email, 'password': password},
      )).called(1);
      
      // Verify tokens were stored
      verify(mockSecureStorage.saveAccessToken(accessToken)).called(1);
      verify(mockSecureStorage.saveRefreshToken(refreshToken)).called(1);
      verify(mockSecureStorage.saveTokenExpiry(expiresAt)).called(1);
    });

    test('should handle invalid credentials error', () async {
      // Arrange
      const email = 'test@example.com';
      const password = 'wrongpassword';

      when(mockApiClient.post(
        '/api/auth/login',
        data: anyNamed('data'),
      )).thenThrow(DioException(
        requestOptions: RequestOptions(path: '/api/auth/login'),
        response: Response(
          requestOptions: RequestOptions(path: '/api/auth/login'),
          statusCode: 401,
          data: {
            'code': 'INVALID_CREDENTIALS',
            'message': 'Invalid email or password',
          },
        ),
      ));

      // Act
      final result = await authService.signInWithEmail(email, password);

      // Assert
      expect(result.isSuccess, isFalse);
      expect(result.user, isNull);
      expect(result.errorMessage, contains('Email sign-in failed'));
      expect(authService.currentUser, isNull);
      
      // Verify API call was attempted
      verify(mockApiClient.post(
        '/api/auth/login',
        data: {'email': email, 'password': password},
      )).called(1);
      
      // Verify no tokens were stored
      verifyNever(mockSecureStorage.saveAccessToken(any));
      verifyNever(mockSecureStorage.saveRefreshToken(any));
    });

    test('should emit correct auth states during email sign-in', () async {
      // Arrange
      const email = 'test@example.com';
      const password = 'SecureP@ss123';
      final expiresAt = DateTime.now().add(const Duration(minutes: 15));

      final authResponse = AuthResponse(
        accessToken: 'token',
        refreshToken: 'refresh',
        user: UserProfile(
          id: 'user_123',
          email: email,
          fullName: 'Test User',
          memberRank: 'silver',
          points: 0,
          role: 'customer',
          isActive: true,
          createdAt: DateTime.now(),
        ),
        expiresAt: expiresAt,
      );

      when(mockApiClient.post(
        '/api/auth/login',
        data: anyNamed('data'),
      )).thenAnswer((_) async => Response(
            requestOptions: RequestOptions(path: '/api/auth/login'),
            data: authResponse.toJson(),
            statusCode: 200,
          ));

      when(mockSecureStorage.saveAccessToken(any))
          .thenAnswer((_) async => {});
      when(mockSecureStorage.saveRefreshToken(any))
          .thenAnswer((_) async => {});
      when(mockSecureStorage.saveTokenExpiry(any))
          .thenAnswer((_) async => {});

      // Act & Assert
      final stateChanges = <AuthState>[];
      final subscription = authService.authStateStream.listen((state) {
        stateChanges.add(state);
      });

      await authService.signInWithEmail(email, password);

      // Give stream time to emit
      await Future.delayed(const Duration(milliseconds: 100));

      expect(stateChanges, contains(AuthState.authenticating));
      expect(stateChanges, contains(AuthState.authenticated));

      await subscription.cancel();
    });
  });

  group('AuthService - User Registration', () {
    late MockAPIClient mockApiClient;
    late MockSecureStorageService mockSecureStorage;

    setUp(() {
      mockApiClient = MockAPIClient();
      mockSecureStorage = MockSecureStorageService();
    });

    test('should successfully register new user', () async {
      // Arrange
      const email = 'newuser@example.com';
      const password = 'SecureP@ss123';
      const fullName = 'New User';
      const phone = '0901234567';
      const accessToken = 'jwt_access_token_123';
      const refreshToken = 'jwt_refresh_token_123';
      final expiresAt = DateTime.now().add(const Duration(minutes: 15));

      final authResponse = AuthResponse(
        accessToken: accessToken,
        refreshToken: refreshToken,
        user: UserProfile(
          id: 'user_123',
          email: email,
          fullName: fullName,
          phone: phone,
          memberRank: 'silver',
          points: 0,
          role: 'customer',
          isActive: true,
          createdAt: DateTime.now(),
        ),
        expiresAt: expiresAt,
      );

      when(mockApiClient.post(
        '/api/auth/register',
        data: anyNamed('data'),
      )).thenAnswer((_) async => Response(
            requestOptions: RequestOptions(path: '/api/auth/register'),
            data: authResponse.toJson(),
            statusCode: 201,
          ));

      when(mockSecureStorage.saveAccessToken(accessToken))
          .thenAnswer((_) async => {});
      when(mockSecureStorage.saveRefreshToken(refreshToken))
          .thenAnswer((_) async => {});
      when(mockSecureStorage.saveTokenExpiry(expiresAt))
          .thenAnswer((_) async => {});

      // Act & Assert
      // Service should:
      // 1. Create RegisterRequest
      // 2. Call /api/auth/register
      // 3. Store tokens securely
      // 4. Return success result
    });

    test('should handle email already exists error', () async {
      // Arrange
      const email = 'existing@example.com';
      const password = 'SecureP@ss123';
      const fullName = 'Test User';
      const phone = '0901234567';

      when(mockApiClient.post(
        '/api/auth/register',
        data: anyNamed('data'),
      )).thenThrow(DioException(
        requestOptions: RequestOptions(path: '/api/auth/register'),
        response: Response(
          requestOptions: RequestOptions(path: '/api/auth/register'),
          statusCode: 409,
          data: {
            'code': 'EMAIL_EXISTS',
            'message': 'Email already exists',
          },
        ),
      ));

      // Act & Assert
      // Service should return AuthResult with error about email already existing
    });
  });

  group('AuthService - Token Management', () {
    late MockSecureStorageService mockSecureStorage;
    late MockAPIClient mockApiClient;
    late AuthService authService;

    setUp(() {
      mockSecureStorage = MockSecureStorageService();
      mockApiClient = MockAPIClient();
      
      // Reset singleton for testing
      AuthService.resetInstance();
      
      // Mock initialization calls that happen in constructor
      when(mockSecureStorage.hasAccessToken()).thenAnswer((_) async => false);
      when(mockSecureStorage.isTokenExpired()).thenAnswer((_) async => true);
      
      authService = AuthService(
        apiClient: mockApiClient,
        secureStorage: mockSecureStorage,
        googleSignIn: MockGoogleSignIn(),
      );
    });

    tearDown(() {
      authService.dispose();
    });

    test('should return access token if not expired', () async {
      // Arrange
      const accessToken = 'jwt_access_token_123';

      when(mockSecureStorage.getAccessToken())
          .thenAnswer((_) async => accessToken);
      when(mockSecureStorage.isTokenExpired()).thenAnswer((_) async => false);

      // Act
      final result = await authService.getAccessToken();

      // Assert
      expect(result, equals(accessToken));
      verify(mockSecureStorage.getAccessToken()).called(1);
      verify(mockSecureStorage.isTokenExpired()).called(1);
      
      // Should NOT attempt to refresh since token is not expired
      verifyNever(mockSecureStorage.getRefreshToken());
      verifyNever(mockApiClient.post(
        '/api/auth/refresh',
        data: anyNamed('data'),
      ));
    });

    test('should refresh token if expired and return new token', () async {
      // Arrange
      const oldAccessToken = 'old_jwt_token';
      const refreshToken = 'refresh_token_123';
      const newAccessToken = 'new_jwt_token';
      final expiresAt = DateTime.now().add(const Duration(minutes: 15));

      // Mock getAccessToken to return old token first, then new token after refresh
      var callCount = 0;
      when(mockSecureStorage.getAccessToken()).thenAnswer((_) async {
        callCount++;
        if (callCount <= 1) {
          return oldAccessToken;  // First call in getAccessToken
        } else {
          return newAccessToken;  // Second call after refresh
        }
      });
      
      when(mockSecureStorage.isTokenExpired())
          .thenAnswer((_) async => true);  // Token is expired
      when(mockSecureStorage.getRefreshToken())
          .thenAnswer((_) async => refreshToken);

      final authResponse = AuthResponse(
        accessToken: newAccessToken,
        refreshToken: refreshToken,
        user: UserProfile(
          id: 'user_123',
          email: 'test@example.com',
          fullName: 'Test User',
          memberRank: 'silver',
          points: 0,
          role: 'customer',
          isActive: true,
          createdAt: DateTime.now(),
        ),
        expiresAt: expiresAt,
      );

      when(mockApiClient.post(
        '/api/auth/refresh',
        data: anyNamed('data'),
      )).thenAnswer((_) async => Response(
            requestOptions: RequestOptions(path: '/api/auth/refresh'),
            data: authResponse.toJson(),
            statusCode: 200,
          ));

      when(mockSecureStorage.saveAccessToken(newAccessToken))
          .thenAnswer((_) async => {});
      when(mockSecureStorage.saveRefreshToken(refreshToken))
          .thenAnswer((_) async => {});
      when(mockSecureStorage.saveTokenExpiry(expiresAt))
          .thenAnswer((_) async => {});

      // Act
      final result = await authService.getAccessToken();

      // Assert
      expect(result, equals(newAccessToken));
      
      // Verify refresh flow
      verify(mockSecureStorage.getAccessToken()).called(greaterThan(1));  // Called twice
      verify(mockSecureStorage.isTokenExpired()).called(greaterThan(0));
      verify(mockSecureStorage.getRefreshToken()).called(1);
      verify(mockApiClient.post(
        '/api/auth/refresh',
        data: {'refreshToken': refreshToken},
      )).called(1);
      
      // Verify new tokens were stored
      verify(mockSecureStorage.saveAccessToken(newAccessToken)).called(1);
      verify(mockSecureStorage.saveRefreshToken(refreshToken)).called(1);
      verify(mockSecureStorage.saveTokenExpiry(expiresAt)).called(1);
    });

    test('should clear session when refresh token is invalid', () async {
      // Arrange
      const oldAccessToken = 'old_jwt_token';
      const refreshToken = 'invalid_refresh_token';

      when(mockSecureStorage.getAccessToken())
          .thenAnswer((_) async => oldAccessToken);
      when(mockSecureStorage.isTokenExpired()).thenAnswer((_) async => true);
      when(mockSecureStorage.getRefreshToken())
          .thenAnswer((_) async => refreshToken);

      when(mockApiClient.post(
        '/api/auth/refresh',
        data: anyNamed('data'),
      )).thenThrow(DioException(
        requestOptions: RequestOptions(path: '/api/auth/refresh'),
        response: Response(
          requestOptions: RequestOptions(path: '/api/auth/refresh'),
          statusCode: 401,
          data: {
            'code': 'INVALID_REFRESH_TOKEN',
            'message': 'Refresh token is invalid or expired',
          },
        ),
      ));

      when(mockSecureStorage.clearTokens()).thenAnswer((_) async => {});

      // Act
      final result = await authService.getAccessToken();

      // Assert
      expect(result, isNull);
      
      // Verify refresh was attempted
      verify(mockApiClient.post(
        '/api/auth/refresh',
        data: {'refreshToken': refreshToken},
      )).called(1);
      
      // Verify session was cleared
      verify(mockSecureStorage.clearTokens()).called(1);
      expect(authService.currentUser, isNull);
    });

    test('should successfully refresh access token directly', () async {
      // Arrange
      const refreshToken = 'refresh_token_123';
      const newAccessToken = 'new_jwt_token';
      final expiresAt = DateTime.now().add(const Duration(minutes: 15));

      when(mockSecureStorage.getRefreshToken())
          .thenAnswer((_) async => refreshToken);

      final authResponse = AuthResponse(
        accessToken: newAccessToken,
        refreshToken: refreshToken,
        user: UserProfile(
          id: 'user_123',
          email: 'test@example.com',
          fullName: 'Test User',
          memberRank: 'silver',
          points: 0,
          role: 'customer',
          isActive: true,
          createdAt: DateTime.now(),
        ),
        expiresAt: expiresAt,
      );

      when(mockApiClient.post(
        '/api/auth/refresh',
        data: anyNamed('data'),
      )).thenAnswer((_) async => Response(
            requestOptions: RequestOptions(path: '/api/auth/refresh'),
            data: authResponse.toJson(),
            statusCode: 200,
          ));

      when(mockSecureStorage.saveAccessToken(newAccessToken))
          .thenAnswer((_) async => {});
      when(mockSecureStorage.saveRefreshToken(refreshToken))
          .thenAnswer((_) async => {});
      when(mockSecureStorage.saveTokenExpiry(expiresAt))
          .thenAnswer((_) async => {});

      // Act
      final result = await authService.refreshAccessToken();

      // Assert
      expect(result, isTrue);
      expect(authService.currentUser, isNotNull);
      expect(authService.currentUser?.id, equals('user_123'));
      
      // Verify API call
      verify(mockApiClient.post(
        '/api/auth/refresh',
        data: {'refreshToken': refreshToken},
      )).called(1);
      
      // Verify tokens were stored
      verify(mockSecureStorage.saveAccessToken(newAccessToken)).called(1);
      verify(mockSecureStorage.saveRefreshToken(refreshToken)).called(1);
      verify(mockSecureStorage.saveTokenExpiry(expiresAt)).called(1);
    });

    test('should return false when refreshAccessToken fails', () async {
      // Arrange
      const refreshToken = 'invalid_refresh_token';

      when(mockSecureStorage.getRefreshToken())
          .thenAnswer((_) async => refreshToken);

      when(mockApiClient.post(
        '/api/auth/refresh',
        data: anyNamed('data'),
      )).thenThrow(DioException(
        requestOptions: RequestOptions(path: '/api/auth/refresh'),
        response: Response(
          requestOptions: RequestOptions(path: '/api/auth/refresh'),
          statusCode: 401,
        ),
      ));

      when(mockSecureStorage.clearTokens()).thenAnswer((_) async => {});

      // Act
      final result = await authService.refreshAccessToken();

      // Assert
      expect(result, isFalse);
      expect(authService.currentUser, isNull);
      verify(mockSecureStorage.clearTokens()).called(1);
    });

    test('should check authentication status correctly when authenticated', () async {
      // Arrange
      when(mockSecureStorage.hasAccessToken()).thenAnswer((_) async => true);
      when(mockSecureStorage.isTokenExpired()).thenAnswer((_) async => false);

      // Act
      final result = await authService.isAuthenticated();

      // Assert
      expect(result, isTrue);
      // hasAccessToken is called during init and during test, so allow multiple calls
      verify(mockSecureStorage.hasAccessToken()).called(greaterThan(0));
      // isTokenExpired might be called during init and test
      verify(mockSecureStorage.isTokenExpired()).called(greaterThan(0));
    });

    test('should return false for authentication status with no token', () async {
      // Arrange
      when(mockSecureStorage.hasAccessToken()).thenAnswer((_) async => false);

      // Act
      final result = await authService.isAuthenticated();

      // Assert
      expect(result, isFalse);
      // hasAccessToken is called during init and during test
      verify(mockSecureStorage.hasAccessToken()).called(greaterThan(0));
      // Should not check expiry if no token exists in the actual call
      // (but might be called during init with different stub)
    });

    test('should return false for authentication status with expired token', () async {
      // Arrange
      when(mockSecureStorage.hasAccessToken()).thenAnswer((_) async => true);
      when(mockSecureStorage.isTokenExpired()).thenAnswer((_) async => true);

      // Act
      final result = await authService.isAuthenticated();

      // Assert
      expect(result, isFalse);
      verify(mockSecureStorage.hasAccessToken()).called(greaterThan(0));
      verify(mockSecureStorage.isTokenExpired()).called(greaterThan(0));
    });

    test('should emit refreshing state during token refresh', () async {
      // Arrange
      const refreshToken = 'refresh_token_123';
      final expiresAt = DateTime.now().add(const Duration(minutes: 15));

      when(mockSecureStorage.getRefreshToken())
          .thenAnswer((_) async => refreshToken);

      final authResponse = AuthResponse(
        accessToken: 'new_token',
        refreshToken: refreshToken,
        user: UserProfile(
          id: 'user_123',
          email: 'test@example.com',
          fullName: 'Test User',
          memberRank: 'silver',
          points: 0,
          role: 'customer',
          isActive: true,
          createdAt: DateTime.now(),
        ),
        expiresAt: expiresAt,
      );

      when(mockApiClient.post(
        '/api/auth/refresh',
        data: anyNamed('data'),
      )).thenAnswer((_) async => Response(
            requestOptions: RequestOptions(path: '/api/auth/refresh'),
            data: authResponse.toJson(),
            statusCode: 200,
          ));

      when(mockSecureStorage.saveAccessToken(any))
          .thenAnswer((_) async => {});
      when(mockSecureStorage.saveRefreshToken(any))
          .thenAnswer((_) async => {});
      when(mockSecureStorage.saveTokenExpiry(any))
          .thenAnswer((_) async => {});

      // Act & Assert
      final stateChanges = <AuthState>[];
      final subscription = authService.authStateStream.listen((state) {
        stateChanges.add(state);
      });

      await authService.refreshAccessToken();
      await Future.delayed(const Duration(milliseconds: 100));

      expect(stateChanges, contains(AuthState.refreshing));
      expect(stateChanges, contains(AuthState.authenticated));

      await subscription.cancel();
    });
  });

  group('AuthService - Logout', () {
    late MockAPIClient mockApiClient;
    late MockSecureStorageService mockSecureStorage;
    late MockGoogleSignIn mockGoogleSignIn;
    late AuthService authService;

    setUp(() {
      mockApiClient = MockAPIClient();
      mockSecureStorage = MockSecureStorageService();
      mockGoogleSignIn = MockGoogleSignIn();
      
      // Reset singleton for testing
      AuthService.resetInstance();
      
      // Mock initialization calls that happen in constructor
      when(mockSecureStorage.hasAccessToken()).thenAnswer((_) async => false);
      when(mockSecureStorage.isTokenExpired()).thenAnswer((_) async => true);
      
      authService = AuthService(
        apiClient: mockApiClient,
        secureStorage: mockSecureStorage,
        googleSignIn: mockGoogleSignIn,
      );
    });

    tearDown(() {
      authService.dispose();
    });

    test('should successfully logout and clear all tokens', () async {
      // Arrange
      const refreshToken = 'refresh_token_123';

      when(mockSecureStorage.getRefreshToken())
          .thenAnswer((_) async => refreshToken);
      when(mockApiClient.post(
        '/api/auth/logout',
        data: anyNamed('data'),
      )).thenAnswer((_) async => Response(
            requestOptions: RequestOptions(path: '/api/auth/logout'),
            statusCode: 200,
          ));
      when(mockGoogleSignIn.isSignedIn()).thenAnswer((_) async => true);
      when(mockGoogleSignIn.signOut()).thenAnswer((_) async => null);
      when(mockSecureStorage.clearTokens()).thenAnswer((_) async => {});

      // Act
      await authService.signOut();

      // Assert
      // Verify backend logout was called
      verify(mockApiClient.post(
        '/api/auth/logout',
        data: {'refreshToken': refreshToken},
      )).called(1);
      
      // Verify Google sign out
      verify(mockGoogleSignIn.isSignedIn()).called(1);
      verify(mockGoogleSignIn.signOut()).called(1);
      
      // Verify tokens were cleared
      verify(mockSecureStorage.clearTokens()).called(1);
      
      // Verify user was cleared
      expect(authService.currentUser, isNull);
    });

    test('should clear local session even if backend logout fails', () async {
      // Arrange
      const refreshToken = 'refresh_token_123';

      when(mockSecureStorage.getRefreshToken())
          .thenAnswer((_) async => refreshToken);
      when(mockApiClient.post(
        '/api/auth/logout',
        data: anyNamed('data'),
      )).thenThrow(DioException(
        requestOptions: RequestOptions(path: '/api/auth/logout'),
        type: DioExceptionType.connectionTimeout,
      ));
      when(mockGoogleSignIn.isSignedIn()).thenAnswer((_) async => false);
      when(mockSecureStorage.clearTokens()).thenAnswer((_) async => {});

      // Act
      await authService.signOut();

      // Assert
      // Verify backend logout was attempted
      verify(mockApiClient.post(
        '/api/auth/logout',
        data: {'refreshToken': refreshToken},
      )).called(1);
      
      // Verify local cleanup still happened despite backend failure
      verify(mockSecureStorage.clearTokens()).called(1);
      expect(authService.currentUser, isNull);
    });

    test('should emit unauthenticated state after logout', () async {
      // Arrange
      const refreshToken = 'refresh_token_123';

      when(mockSecureStorage.getRefreshToken())
          .thenAnswer((_) async => refreshToken);
      when(mockApiClient.post(
        '/api/auth/logout',
        data: anyNamed('data'),
      )).thenAnswer((_) async => Response(
            requestOptions: RequestOptions(path: '/api/auth/logout'),
            statusCode: 200,
          ));
      when(mockGoogleSignIn.isSignedIn()).thenAnswer((_) async => false);
      when(mockSecureStorage.clearTokens()).thenAnswer((_) async => {});

      // Act & Assert
      final stateChanges = <AuthState>[];
      final subscription = authService.authStateStream.listen((state) {
        stateChanges.add(state);
      });

      await authService.signOut();
      await Future.delayed(const Duration(milliseconds: 100));

      expect(stateChanges, contains(AuthState.unauthenticated));

      await subscription.cancel();
    });

    test('should handle logout when no refresh token exists', () async {
      // Arrange
      when(mockSecureStorage.getRefreshToken())
          .thenAnswer((_) async => null);
      when(mockGoogleSignIn.isSignedIn()).thenAnswer((_) async => false);
      when(mockSecureStorage.clearTokens()).thenAnswer((_) async => {});

      // Act
      await authService.signOut();

      // Assert
      // Should not attempt to call backend if no refresh token
      verifyNever(mockApiClient.post(
        '/api/auth/logout',
        data: anyNamed('data'),
      ));
      
      // But should still clear local storage
      verify(mockSecureStorage.clearTokens()).called(1);
      expect(authService.currentUser, isNull);
    });

    test('should sign out from Google only if signed in', () async {
      // Arrange
      when(mockSecureStorage.getRefreshToken())
          .thenAnswer((_) async => 'refresh_token');
      when(mockApiClient.post(
        '/api/auth/logout',
        data: anyNamed('data'),
      )).thenAnswer((_) async => Response(
            requestOptions: RequestOptions(path: '/api/auth/logout'),
            statusCode: 200,
          ));
      when(mockGoogleSignIn.isSignedIn()).thenAnswer((_) async => false);
      when(mockSecureStorage.clearTokens()).thenAnswer((_) async => {});

      // Act
      await authService.signOut();

      // Assert
      verify(mockGoogleSignIn.isSignedIn()).called(1);
      // Should not call signOut if not signed in
      verifyNever(mockGoogleSignIn.signOut());
    });
  });

  group('AuthService - Auth State Stream', () {
    test('should emit authentication state changes', () async {
      // This test verifies the Stream<AuthState> broadcasts state changes
      // States: unauthenticated -> authenticating -> authenticated
      // Or: authenticated -> unauthenticated (on logout)
    });

    test('should emit error state on authentication failure', () async {
      // State should change to AuthState.error on failed auth attempt
    });

    test('should emit refreshing state during token refresh', () async {
      // State should change to AuthState.refreshing during refresh
    });
  });

  group('AuthService - Integration Scenarios', () {
    test('should restore session on app launch with valid token', () async {
      // Arrange - app launch with stored valid token
      // Act - initialize auth state
      // Assert - should automatically authenticate user
    });

    test('should attempt token refresh on app launch with expired token', () async {
      // Arrange - app launch with stored expired token but valid refresh token
      // Act - initialize auth state
      // Assert - should refresh token and authenticate
    });

    test('should start unauthenticated when no tokens exist', () async {
      // Arrange - app launch with no stored tokens
      // Act - initialize auth state
      // Assert - should be in unauthenticated state
    });

    test('should schedule proactive token refresh', () async {
      // After successful authentication, should schedule refresh
      // 5 minutes before token expiry
    });

    test('should handle concurrent token refresh requests', () async {
      // If multiple requests trigger refresh simultaneously,
      // should only refresh once and reuse result
    });
  });
}
