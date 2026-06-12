# AuthService Usage Guide

## Overview

The `AuthService` class manages authentication flows, token lifecycle, and secure credential storage for the Cinema Booking application. It supports both Google OAuth and email/password authentication.

## Features

- ✅ Google OAuth 2.0 sign-in flow
- ✅ Email/password authentication
- ✅ User registration
- ✅ Automatic JWT token refresh
- ✅ Secure token storage (iOS Keychain, Android Keystore)
- ✅ Proactive token refresh (5 minutes before expiry)
- ✅ Session persistence across app restarts
- ✅ Logout with token revocation
- ✅ Reactive authentication state stream

## Basic Usage

### 1. Google OAuth Sign-In

```dart
import 'package:cine_book/services/auth_service.dart';

// Get AuthService instance
final authService = AuthService();

// Sign in with Google
Future<void> signInWithGoogle() async {
  final result = await authService.signInWithGoogle();
  
  if (result.isSuccess) {
    // Success! User is authenticated
    final user = authService.currentUser;
    print('Welcome, ${user?.fullName}!');
    print('Email: ${user?.email}');
    print('Member Rank: ${user?.memberRank}');
    print('Points: ${user?.points}');
  } else {
    // Handle error
    print('Error: ${result.errorMessage}');
  }
}
```

### 2. Email/Password Sign-In

```dart
// Sign in with email and password
Future<void> signInWithEmail() async {
  final email = 'user@example.com';
  final password = 'SecureP@ss123';
  
  final result = await authService.signInWithEmail(email, password);
  
  if (result.isSuccess) {
    // Success!
    print('Signed in as: ${authService.currentUser?.fullName}');
  } else {
    // Handle error (invalid credentials, network error, etc.)
    print('Error: ${result.errorMessage}');
  }
}
```

### 3. User Registration

```dart
// Register new user
Future<void> registerUser() async {
  final result = await authService.register(
    'newuser@example.com',     // email
    'SecureP@ss123',            // password
    'John Doe',                 // fullName
    '0901234567',               // phone
  );
  
  if (result.isSuccess) {
    // Registration successful, user is automatically signed in
    print('Welcome, ${authService.currentUser?.fullName}!');
  } else {
    // Handle error (email already exists, validation error, etc.)
    print('Error: ${result.errorMessage}');
  }
}
```

### 4. Sign Out

```dart
// Sign out current user
Future<void> signOut() async {
  await authService.signOut();
  print('User signed out');
}
```

## Advanced Usage

### Monitor Authentication State

```dart
import 'package:flutter/material.dart';
import 'package:cine_book/services/auth_service.dart';

class AuthStateMonitor extends StatefulWidget {
  @override
  _AuthStateMonitorState createState() => _AuthStateMonitorState();
}

class _AuthStateMonitorState extends State<AuthStateMonitor> {
  final authService = AuthService();
  StreamSubscription<AuthState>? _authStateSubscription;
  
  @override
  void initState() {
    super.initState();
    
    // Listen to authentication state changes
    _authStateSubscription = authService.authStateStream.listen((state) {
      switch (state) {
        case AuthState.unauthenticated:
          print('User is not authenticated');
          // Navigate to login screen
          break;
        case AuthState.authenticated:
          print('User is authenticated');
          // Navigate to home screen
          break;
        case AuthState.authenticating:
          print('Authentication in progress...');
          // Show loading indicator
          break;
        case AuthState.refreshing:
          print('Refreshing token...');
          // Optionally show a subtle indicator
          break;
        case AuthState.error:
          print('Authentication error');
          // Show error message
          break;
      }
    });
  }
  
  @override
  void dispose() {
    _authStateSubscription?.cancel();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Container(); // Your UI
  }
}
```

### Check Authentication Status

```dart
// Check if user is authenticated
Future<bool> checkAuth() async {
  final isAuth = await authService.isAuthenticated();
  
  if (isAuth) {
    print('User is authenticated');
    return true;
  } else {
    print('User needs to sign in');
    return false;
  }
}
```

### Get Access Token for API Calls

```dart
// Get current access token (automatically refreshes if expired)
Future<String?> getToken() async {
  final token = await authService.getAccessToken();
  
  if (token != null) {
    // Use token for API calls
    print('Access Token: $token');
    return token;
  } else {
    // No valid token, user needs to sign in
    print('No valid token');
    return null;
  }
}
```

### Access Current User Profile

```dart
// Get current authenticated user
void displayUserProfile() {
  final user = authService.currentUser;
  
  if (user != null) {
    print('User ID: ${user.id}');
    print('Full Name: ${user.fullName}');
    print('Email: ${user.email}');
    print('Phone: ${user.phone ?? "Not provided"}');
    print('Member Rank: ${user.memberRank}');
    print('Points: ${user.points}');
    print('Role: ${user.role}');
    print('Is Active: ${user.isActive}');
    
    // Check user role
    if (user.isCustomer) {
      print('User is a customer');
    } else if (user.isStaff) {
      print('User is staff');
    } else if (user.isAdmin) {
      print('User is admin');
    }
    
    // Check age (for T18 movies)
    if (user.isAdult) {
      print('User is 18+');
    }
  } else {
    print('No user is signed in');
  }
}
```

## Error Handling

The `AuthResult` returned by authentication methods contains:
- `isSuccess`: Boolean indicating success/failure
- `user`: UserProfile object (if successful)
- `errorMessage`: String describing the error (if failed)

### Common Error Scenarios

1. **User Cancelled Google Sign-In**
   - Error: "Google sign-in cancelled"
   - User closed the Google sign-in popup

2. **Invalid Google ID Token**
   - Error: "Failed to get Google ID token"
   - Google authentication didn't return a valid token

3. **Invalid Email/Password**
   - Error: "Email sign-in failed: ..."
   - Backend returned 401 with invalid credentials

4. **Email Already Exists**
   - Error: "Registration failed: ..."
   - Backend returned 409 with email conflict

5. **Network Error**
   - Error: "...failed: DioException..."
   - Network connectivity issue or backend unavailable

### Example Error Handling

```dart
Future<void> handleAuthWithErrors() async {
  try {
    final result = await authService.signInWithGoogle();
    
    if (result.isSuccess) {
      // Success
      navigateToHome();
    } else {
      // Handle specific errors
      final error = result.errorMessage ?? 'Unknown error';
      
      if (error.contains('cancelled')) {
        // User cancelled, do nothing or show subtle message
        showSnackBar('Sign-in cancelled');
      } else if (error.contains('network')) {
        // Network error
        showDialog('Network Error', 'Please check your connection');
      } else {
        // Generic error
        showDialog('Sign-In Error', error);
      }
    }
  } catch (e) {
    // Unexpected error
    showDialog('Error', 'An unexpected error occurred: $e');
  }
}
```

## Token Management

### Automatic Token Refresh

The AuthService automatically handles token refresh:

1. **On API Call**: When `getAccessToken()` is called and token is expired, it automatically refreshes
2. **Proactive Refresh**: Schedules refresh 5 minutes before token expiry
3. **On App Launch**: If stored token is expired, attempts refresh with refresh token

### Token Refresh Failure

If token refresh fails (invalid refresh token), the AuthService:
1. Clears all stored tokens
2. Clears current user
3. Updates auth state to `unauthenticated`
4. Triggers auth state listeners

You should listen to auth state changes and redirect to login when state becomes `unauthenticated`.

## Session Persistence

### On App Launch

The AuthService automatically checks for stored tokens:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // AuthService will automatically restore session if valid tokens exist
  final authService = AuthService();
  
  // Wait a moment for auth state initialization
  await Future.delayed(Duration(milliseconds: 100));
  
  final isAuth = await authService.isAuthenticated();
  
  runApp(MyApp(
    initialRoute: isAuth ? '/home' : '/login',
  ));
}
```

### Session Lifecycle

1. **User Signs In**: Tokens stored in secure storage
2. **App Restart**: Tokens loaded from secure storage
3. **Token Valid**: User automatically authenticated
4. **Token Expired**: Automatic refresh attempted
5. **Refresh Succeeds**: User authenticated with new tokens
6. **Refresh Fails**: User redirected to login

## Integration with APIClient

The APIClient automatically uses AuthService tokens through the AuthInterceptor:

```dart
// No need to manually attach tokens
final response = await apiClient.get('/api/movies');

// The AuthInterceptor automatically:
// 1. Gets token from SecureStorageService
// 2. Attaches it to Authorization header
// 3. Handles 401 responses with token refresh
// 4. Retries original request with new token
```

## Best Practices

1. **Single Instance**: Use the singleton pattern - always call `AuthService()`
2. **Listen to Auth State**: Monitor `authStateStream` for state changes
3. **Handle Errors**: Always check `isSuccess` in AuthResult
4. **Don't Cache Tokens**: Always get fresh token via `getAccessToken()`
5. **Logout Properly**: Always call `signOut()` instead of just clearing UI state
6. **Check User Role**: Use `user.isCustomer`, `user.isStaff`, `user.isAdmin` helpers
7. **Age Verification**: Use `user.isAdult` for T18 movie restrictions

## Testing

For testing, you can inject mock dependencies:

```dart
// In your test
final mockApiClient = MockAPIClient();
final mockSecureStorage = MockSecureStorageService();
final mockGoogleSignIn = MockGoogleSignIn();

// Reset singleton
AuthService.resetInstance();

// Create service with mocks
final authService = AuthService(
  apiClient: mockApiClient,
  secureStorage: mockSecureStorage,
  googleSignIn: mockGoogleSignIn,
);

// Run your tests
```

## Requirements Coverage

This implementation satisfies the following requirements:

- ✅ **Requirement 1.1**: Google OAuth sign-in flow initiated
- ✅ **Requirement 1.2**: Authorization code exchanged for JWT tokens
- ✅ **Requirement 1.3**: User profile data returned
- ✅ **Requirement 1.4**: Automatic token refresh without user intervention
- ✅ **Requirement 1.5**: Session cleared on refresh failure
- ✅ **Requirement 1.6**: Tokens stored securely via Flutter Secure Storage
- ✅ **Requirement 1.7**: Token revocation on logout
- ✅ **Requirement 2.1**: Email/password registration support
- ✅ **Requirement 2.3**: Email/password sign-in support

## API Endpoints Used

The AuthService calls the following backend endpoints:

- `POST /api/auth/google` - Exchange Google ID token for JWT tokens
- `POST /api/auth/login` - Email/password sign-in
- `POST /api/auth/register` - User registration
- `POST /api/auth/refresh` - Refresh access token
- `POST /api/auth/logout` - Revoke refresh token

## Security Considerations

1. **Secure Storage**: Tokens stored in iOS Keychain / Android Keystore
2. **No Token Exposure**: Tokens never logged or exposed in UI
3. **Automatic Cleanup**: Tokens cleared on logout or refresh failure
4. **HTTPS Only**: All API calls over HTTPS (configured in APIClient)
5. **Token Rotation**: New access token issued on every refresh
6. **Expiry Enforcement**: Expired tokens automatically refreshed or invalidated
