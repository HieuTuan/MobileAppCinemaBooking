import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../api/api_client.dart';
import '../models/auth_models.dart';
import 'secure_storage_service.dart';

/// Authentication service managing authentication flows, token lifecycle, and secure credential storage.
/// 
/// Supports both Google OAuth and email/password authentication.
/// Manages JWT token refresh and session state.
/// 
/// **Requirements Coverage:**
/// - Requirement 1.1: Google OAuth sign-in flow
/// - Requirement 1.2: JWT and Refresh token exchange
/// - Requirement 1.4: Automatic token refresh
/// - Requirement 1.5: Session clearing on refresh failure
/// - Requirement 1.6: Secure token storage
/// - Requirement 1.7: Logout with token revocation
/// - Requirement 2.1: Email/password registration
/// - Requirement 2.3: Email/password sign-in
/// 
/// Usage:
/// ```dart
/// final authService = AuthService();
/// 
/// // Google OAuth sign-in
/// final result = await authService.signInWithGoogle();
/// if (result.isSuccess) {
///   print('Signed in: ${authService.currentUser?.fullName}');
/// }
/// 
/// // Monitor auth state
/// authService.authStateStream.listen((state) {
///   print('Auth state: $state');
/// });
/// ```
class AuthService {
  final APIClient _apiClient;
  final SecureStorageService _secureStorage;
  final GoogleSignIn _googleSignIn;
  
  /// Current authenticated user profile
  UserProfile? _currentUser;
  
  /// Authentication state controller
  final _authStateController = StreamController<AuthState>.broadcast();
  
  /// Timer for proactive token refresh
  Timer? _refreshTimer;
  
  /// Singleton instance
  static AuthService? _instance;
  
  /// Factory constructor returns singleton instance
  factory AuthService({
    APIClient? apiClient,
    SecureStorageService? secureStorage,
    GoogleSignIn? googleSignIn,
  }) {
    _instance ??= AuthService._internal(
      apiClient: apiClient,
      secureStorage: secureStorage,
      googleSignIn: googleSignIn,
    );
    return _instance!;
  }
  
  /// Private constructor for singleton with optional dependency injection
  AuthService._internal({
    APIClient? apiClient,
    SecureStorageService? secureStorage,
    GoogleSignIn? googleSignIn,
  })  : _apiClient = apiClient ?? APIClient(),
        _secureStorage = secureStorage ?? SecureStorageService(),
        _googleSignIn = googleSignIn ??
            GoogleSignIn(
              scopes: [
                'email',
                'profile',
              ],
            ) {
    _initializeAuthState();
  }
  
  /// Reset singleton instance (for testing)
  @visibleForTesting
  static void resetInstance() {
    _instance?.dispose();
    _instance = null;
  }
  
  // ============================================================================
  // Public Getters
  // ============================================================================
  
  /// Stream of authentication state changes
  Stream<AuthState> get authStateStream => _authStateController.stream;
  
  /// Current authenticated user profile (null if not authenticated)
  UserProfile? get currentUser => _currentUser;
  
  // ============================================================================
  // Authentication Methods
  // ============================================================================
  
  /// Sign in with Google OAuth
  /// 
  /// Initiates Google OAuth flow, exchanges authorization code for JWT tokens,
  /// and stores tokens securely.
  /// 
  /// **Requirements: 1.1, 1.2, 1.3, 1.6**
  /// 
  /// Returns:
  /// - [AuthResult] with success status and optional error message
  Future<AuthResult> signInWithGoogle() async {
    try {
      _authStateController.add(AuthState.authenticating);
      
      // Step 1: Initiate Google OAuth sign-in flow
      final GoogleSignInAccount? googleAccount = await _googleSignIn.signIn();
      
      if (googleAccount == null) {
        // User cancelled the sign-in flow
        _authStateController.add(AuthState.unauthenticated);
        return AuthResult(
          isSuccess: false,
          errorMessage: 'Google sign-in cancelled',
        );
      }
      
      // Step 2: Get authentication tokens from Google
      final GoogleSignInAuthentication googleAuth = 
          await googleAccount.authentication;
      
      if (googleAuth.idToken == null) {
        _authStateController.add(AuthState.unauthenticated);
        return AuthResult(
          isSuccess: false,
          errorMessage: 'Failed to get Google ID token',
        );
      }
      
      // Step 3: Exchange Google auth code/token with backend for JWT tokens
      final authResponse = await _loginWithGoogle(googleAuth.idToken!);
      
      // Step 4: Store tokens securely
      await _storeAuthResponse(authResponse);
      
      // Step 5: Update current user and state
      _currentUser = authResponse.user;
      _authStateController.add(AuthState.authenticated);
      
      // Step 6: Schedule proactive token refresh
      _scheduleTokenRefresh(authResponse.expiresAt);
      
      return AuthResult(
        isSuccess: true,
        user: authResponse.user,
      );
    } catch (e) {
      _authStateController.add(AuthState.error);
      return AuthResult(
        isSuccess: false,
        errorMessage: 'Google sign-in failed: ${e.toString()}',
      );
    }
  }
  
  /// Sign in with email and password
  /// 
  /// **Requirements: 2.3, 2.6**
  /// 
  /// Returns:
  /// - [AuthResult] with success status and optional error message
  Future<AuthResult> signInWithEmail(String email, String password) async {
    try {
      _authStateController.add(AuthState.authenticating);
      
      // Call backend login endpoint
      final authResponse = await _loginWithEmail(email, password);
      
      // Store tokens securely
      await _storeAuthResponse(authResponse);
      
      // Update current user and state
      _currentUser = authResponse.user;
      _authStateController.add(AuthState.authenticated);
      
      // Schedule proactive token refresh
      _scheduleTokenRefresh(authResponse.expiresAt);
      
      return AuthResult(
        isSuccess: true,
        user: authResponse.user,
      );
    } catch (e) {
      _authStateController.add(AuthState.error);
      return AuthResult(
        isSuccess: false,
        errorMessage: 'Email sign-in failed: ${e.toString()}',
      );
    }
  }
  
  /// Register new user with email and password
  /// 
  /// **Requirements: 2.1, 2.3**
  /// 
  /// Returns:
  /// - [AuthResult] with success status and optional error message
  Future<AuthResult> register(
    String email,
    String password,
    String fullName,
    String phone,
  ) async {
    try {
      _authStateController.add(AuthState.authenticating);
      
      // Create registration request
      final registerRequest = RegisterRequest(
        email: email,
        password: password,
        fullName: fullName,
        phone: phone,
      );
      
      // Call backend register endpoint
      final authResponse = await _registerUser(registerRequest);
      
      // Store tokens securely
      await _storeAuthResponse(authResponse);
      
      // Update current user and state
      _currentUser = authResponse.user;
      _authStateController.add(AuthState.authenticated);
      
      // Schedule proactive token refresh
      _scheduleTokenRefresh(authResponse.expiresAt);
      
      return AuthResult(
        isSuccess: true,
        user: authResponse.user,
      );
    } catch (e) {
      _authStateController.add(AuthState.error);
      return AuthResult(
        isSuccess: false,
        errorMessage: 'Registration failed: ${e.toString()}',
      );
    }
  }
  
  /// Sign out current user
  /// 
  /// Revokes tokens on backend and clears all local storage.
  /// 
  /// **Requirements: 1.7**
  Future<void> signOut() async {
    try {
      // Revoke tokens on backend
      await _revokeTokens();
    } catch (e) {
      // Continue with local cleanup even if backend call fails
      print('Token revocation failed: $e');
    }
    
    // Cancel refresh timer
    _refreshTimer?.cancel();
    _refreshTimer = null;
    
    // Sign out from Google if signed in
    if (await _googleSignIn.isSignedIn()) {
      await _googleSignIn.signOut();
    }
    
    // Clear tokens from secure storage
    await _secureStorage.clearTokens();
    
    // Clear current user
    _currentUser = null;
    
    // Update auth state
    _authStateController.add(AuthState.unauthenticated);
  }
  
  // ============================================================================
  // Token Management
  // ============================================================================
  
  /// Get current access token
  /// 
  /// Automatically refreshes token if expired.
  /// 
  /// **Requirements: 1.4**
  Future<String?> getAccessToken() async {
    final token = await _secureStorage.getAccessToken();
    
    if (token == null) {
      return null;
    }
    
    // Check if token is expired or about to expire
    final isExpired = await _secureStorage.isTokenExpired();
    
    if (isExpired) {
      // Attempt to refresh token
      final refreshed = await refreshAccessToken();
      if (!refreshed) {
        return null;
      }
      // Return the new token
      return await _secureStorage.getAccessToken();
    }
    
    return token;
  }
  
  /// Check if user is currently authenticated
  /// 
  /// **Requirements: 1.6**
  Future<bool> isAuthenticated() async {
    final hasToken = await _secureStorage.hasAccessToken();
    if (!hasToken) {
      return false;
    }
    
    // Check if token is still valid
    final isExpired = await _secureStorage.isTokenExpired();
    return !isExpired;
  }
  
  /// Refresh access token using refresh token
  /// 
  /// **Requirements: 1.4, 1.5**
  /// 
  /// Returns:
  /// - true if refresh succeeded
  /// - false if refresh failed (session cleared)
  Future<bool> refreshAccessToken() async {
    try {
      _authStateController.add(AuthState.refreshing);
      
      final refreshToken = await _secureStorage.getRefreshToken();
      
      if (refreshToken == null) {
        await _handleRefreshFailure();
        return false;
      }
      
      // Call backend refresh endpoint
      final authResponse = await _refreshToken(refreshToken);
      
      // Store new tokens
      await _storeAuthResponse(authResponse);
      
      // Update current user
      _currentUser = authResponse.user;
      
      // Schedule next refresh
      _scheduleTokenRefresh(authResponse.expiresAt);
      
      _authStateController.add(AuthState.authenticated);
      
      return true;
    } catch (e) {
      print('Token refresh failed: $e');
      await _handleRefreshFailure();
      return false;
    }
  }
  
  // ============================================================================
  // Private Helper Methods
  // ============================================================================
  
  /// Initialize authentication state on app launch
  /// 
  /// **Requirements: 1.6**
  Future<void> _initializeAuthState() async {
    final isAuth = await isAuthenticated();
    
    if (isAuth) {
      // Try to refresh token to get user profile
      final refreshed = await refreshAccessToken();
      if (refreshed) {
        _authStateController.add(AuthState.authenticated);
      } else {
        _authStateController.add(AuthState.unauthenticated);
      }
    } else {
      _authStateController.add(AuthState.unauthenticated);
    }
  }
  
  /// Store authentication response tokens securely
  Future<void> _storeAuthResponse(AuthResponse authResponse) async {
    await _secureStorage.saveAccessToken(authResponse.accessToken);
    await _secureStorage.saveRefreshToken(authResponse.refreshToken);
    await _secureStorage.saveTokenExpiry(authResponse.expiresAt);
  }
  
  /// Schedule proactive token refresh before expiration
  /// 
  /// **Requirements: 1.4**
  void _scheduleTokenRefresh(DateTime expiresAt) {
    _refreshTimer?.cancel();
    
    // Calculate time until 5 minutes before expiry
    final now = DateTime.now();
    final refreshTime = expiresAt.subtract(const Duration(minutes: 5));
    final delay = refreshTime.difference(now);
    
    if (delay.isNegative) {
      // Token already expired or will expire soon, refresh immediately
      refreshAccessToken();
    } else {
      // Schedule refresh
      _refreshTimer = Timer(delay, () {
        refreshAccessToken();
      });
    }
  }
  
  /// Handle token refresh failure
  /// 
  /// **Requirements: 1.5**
  Future<void> _handleRefreshFailure() async {
    // Clear tokens
    await _secureStorage.clearTokens();
    
    // Clear current user
    _currentUser = null;
    
    // Update state
    _authStateController.add(AuthState.unauthenticated);
    
    // Cancel refresh timer
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }
  
  // ============================================================================
  // API Call Methods
  // ============================================================================
  
  /// Call backend API to exchange Google ID token for JWT tokens
  /// 
  /// **Requirements: 1.2**
  Future<AuthResponse> _loginWithGoogle(String idToken) async {
    final response = await _apiClient.post(
      '/api/auth/google',
      data: {
        'idToken': idToken,
      },
    );
    
    return AuthResponse.fromJson(response.data as Map<String, dynamic>);
  }
  
  /// Call backend API to sign in with email and password
  Future<AuthResponse> _loginWithEmail(String email, String password) async {
    final response = await _apiClient.post(
      '/api/auth/login',
      data: {
        'email': email,
        'password': password,
      },
    );
    
    return AuthResponse.fromJson(response.data as Map<String, dynamic>);
  }
  
  /// Call backend API to register new user
  Future<AuthResponse> _registerUser(RegisterRequest request) async {
    final response = await _apiClient.post(
      '/api/auth/register',
      data: request.toJson(),
    );
    
    return AuthResponse.fromJson(response.data as Map<String, dynamic>);
  }
  
  /// Call backend API to refresh access token
  Future<AuthResponse> _refreshToken(String refreshToken) async {
    final response = await _apiClient.post(
      '/api/auth/refresh',
      data: {
        'refreshToken': refreshToken,
      },
    );
    
    return AuthResponse.fromJson(response.data as Map<String, dynamic>);
  }
  
  /// Call backend API to revoke tokens
  Future<void> _revokeTokens() async {
    final refreshToken = await _secureStorage.getRefreshToken();
    
    if (refreshToken != null) {
      await _apiClient.post(
        '/api/auth/logout',
        data: {
          'refreshToken': refreshToken,
        },
      );
    }
  }
  
  /// Dispose resources
  void dispose() {
    _refreshTimer?.cancel();
    _authStateController.close();
  }
}

/// Authentication state enum
enum AuthState {
  /// User is not authenticated
  unauthenticated,
  
  /// User is authenticated
  authenticated,
  
  /// Authentication in progress
  authenticating,
  
  /// Token refresh in progress
  refreshing,
  
  /// Authentication error occurred
  error,
}

/// Authentication result model
class AuthResult {
  /// Whether the authentication was successful
  final bool isSuccess;
  
  /// User profile if authentication succeeded
  final UserProfile? user;
  
  /// Error message if authentication failed
  final String? errorMessage;
  
  AuthResult({
    required this.isSuccess,
    this.user,
    this.errorMessage,
  });
}
