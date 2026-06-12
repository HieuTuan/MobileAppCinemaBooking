# Authentication Interceptor

## Overview

The `AuthInterceptor` provides automatic JWT token management for all API requests in the Cinema Booking application.

## Features

- **Automatic Token Attachment**: Attaches JWT token to `Authorization` header as `Bearer {token}` for all non-auth endpoints
- **Automatic Token Refresh**: Detects 401 Unauthorized responses and attempts to refresh the access token using the refresh token
- **Request Retry**: Automatically retries the original request after successful token refresh
- **Session Cleanup**: Clears stored tokens and redirects to login when token refresh fails
- **Request Queueing**: Queues concurrent requests during token refresh to avoid multiple refresh attempts

## Integration

The interceptor is automatically integrated into the `APIClient` singleton and requires no additional configuration for basic usage.

### Setting the Unauthorized Callback

To handle navigation when authentication fails, set the `onUnauthorized` callback:

```dart
void main() {
  runApp(MyApp());
  
  // Set up unauthorized callback for navigation
  APIClient().onUnauthorized = () {
    // Navigate to login screen
    // This should be called from your navigation/routing logic
    navigatorKey.currentState?.pushNamedAndRemoveUntil('/login', (route) => false);
  };
}
```

## How It Works

### Token Attachment Flow

1. **Request Initiated**: User makes an API request (e.g., `GET /api/movies`)
2. **Interceptor Check**: `AuthInterceptor.onRequest()` is invoked
3. **Endpoint Check**: If endpoint is an auth endpoint (`/api/auth/*`), skip token attachment
4. **Token Retrieval**: Retrieve access token from secure storage
5. **Header Injection**: Add `Authorization: Bearer {token}` header
6. **Request Proceeds**: Forward request with token attached

### Token Refresh Flow

1. **401 Response**: API returns 401 Unauthorized
2. **Interceptor Catch**: `AuthInterceptor.onError()` catches the 401 error
3. **Endpoint Check**: If endpoint is an auth endpoint, pass through error (no refresh)
4. **Refresh Check**: Check if already refreshing tokens
   - If yes: Queue the request and wait for refresh to complete
   - If no: Start refresh process
5. **Get Refresh Token**: Retrieve refresh token from secure storage
6. **Refresh API Call**: Call `POST /api/auth/refresh` with refresh token
7. **Save New Tokens**: Store new access token and refresh token
8. **Retry Original Request**: Retry the original request with new access token
9. **Process Queue**: Retry all queued requests with new token
10. **Return Response**: Return successful response to caller

### Session Cleanup Flow

1. **Refresh Failure**: Token refresh fails (no refresh token or API error)
2. **Clear Tokens**: Remove all tokens from secure storage
3. **Clear Queue**: Fail all queued requests
4. **Invoke Callback**: Call `onUnauthorized` callback
5. **Navigate to Login**: App navigates user to login screen

## Requirements Covered

- **Requirement 33.2**: Automatic JWT token attachment to Authorization header
- **Requirement 33.3**: Automatic token refresh on 401 responses and retry logic
- **Requirement 33.4**: Handle token refresh failure by clearing session and redirecting to login

## Endpoints Excluded from Token Management

The following endpoints are excluded from token attachment and refresh logic:

- `/api/auth/login` - Login endpoint
- `/api/auth/register` - Registration endpoint
- `/api/auth/refresh` - Token refresh endpoint (to avoid infinite loops)
- `/api/auth/google` - Google OAuth endpoint

## Configuration

### Token Storage

Tokens are stored using `SecureStorageService` which uses platform-specific secure storage:
- **iOS**: Keychain
- **Android**: Android Keystore
- **Windows/Linux/Mac**: Encrypted shared preferences

### Timeout Handling

Token refresh operations use the same timeout as configured in `APIClient`:
- Standard operations: 30 seconds
- Payment operations: 60 seconds

## Testing

The interceptor is tested through:
1. Unit tests in `test/api/api_client_test.dart` - Verifies interceptor is added to Dio
2. Manual integration testing - Test with real API calls and token expiration

## Debugging

The interceptor includes debug logging (enabled in debug mode):

- 🔐 Token attachment logs
- 🔒 401 error detection logs
- 🔄 Token refresh attempt logs
- ✅ Token refresh success logs
- ❌ Token refresh failure logs
- ⏳ Request queueing logs

## Error Handling

| Scenario | Behavior |
|----------|----------|
| No access token | Request proceeds without Authorization header |
| Empty access token | Request proceeds without Authorization header |
| Token retrieval error | Request proceeds without Authorization header (logged) |
| 401 on non-auth endpoint | Attempt token refresh → Retry request |
| 401 on auth endpoint | Pass through error (no refresh attempt) |
| No refresh token | Clear session → Invoke onUnauthorized callback |
| Refresh API failure | Clear session → Invoke onUnauthorized callback |
| Multiple concurrent 401s | First request triggers refresh, others queue and wait |

## Best Practices

1. **Set onUnauthorized callback early**: Set it in your app's `main()` function or app initialization
2. **Navigation handling**: Use a global navigation key for seamless navigation to login
3. **Token expiry monitoring**: The interceptor handles expiry reactively (on 401), but consider proactive refresh
4. **Don't modify interceptor directly**: Use the provided `APIClient` interface for configuration

## Example Usage

```dart
// The interceptor works automatically for all API calls

// Example 1: Regular API call with automatic token attachment
final response = await APIClient().get('/api/movies');
// Token is automatically attached if user is authenticated

// Example 2: API call that returns 401
final response = await APIClient().get('/api/bookings');
// If token is expired:
// 1. Interceptor catches 401
// 2. Attempts to refresh token
// 3. Retries request with new token
// 4. Returns successful response
// If refresh fails:
// 1. Clears session
// 2. Calls onUnauthorized callback
// 3. App navigates to login

// Example 3: Login (no token attached)
final response = await APIClient().post('/api/auth/login', data: {...});
// No Authorization header is added for auth endpoints
```

## Future Enhancements

Potential improvements for the interceptor:

1. **Proactive Token Refresh**: Refresh token before it expires based on expiry timestamp
2. **Refresh Token Rotation**: Implement refresh token rotation for enhanced security
3. **Concurrent Refresh Optimization**: Optimize handling of multiple concurrent 401 responses
4. **Retry Configuration**: Make retry attempts and delays configurable
5. **Token Caching**: Cache decoded token claims to avoid repeated parsing

## Related Files

- `lib/api/api_client.dart` - API client that integrates the interceptor
- `lib/services/secure_storage_service.dart` - Token storage service
- `test/api/api_client_test.dart` - Unit tests for API client integration
