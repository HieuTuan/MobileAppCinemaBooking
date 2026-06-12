# Retry Interceptor Documentation

## Overview

The Retry Interceptor implements automatic retry logic with exponential backoff for transient network failures and server errors. This improves application resilience by automatically recovering from temporary issues without requiring user intervention.

## Features

- **Exponential Backoff**: Gradually increases delay between retry attempts to avoid overwhelming servers
- **Configurable Retry Policy**: Customizable max attempts, delays, and status codes
- **Smart Retry Logic**: Only retries idempotent HTTP methods (GET, PUT, DELETE, PATCH, HEAD, OPTIONS)
- **Status Code Filtering**: Retries specific transient error codes (408, 429, 500, 502, 503, 504)
- **Network Error Handling**: Automatically retries on connection timeouts and network failures

## Requirements

Implements **Requirement 33.7**: Retry logic with exponential backoff for network failures up to 3 attempts

## Configuration

### Default Retry Policy

```dart
const RetryPolicy(
  maxAttempts: 3,
  initialDelay: Duration(seconds: 1),
  maxDelay: Duration(seconds: 30),
  backoffMultiplier: 2.0,
  retryableStatusCodes: {408, 429, 500, 502, 503, 504},
)
```

### Exponential Backoff Formula

```
delay = min(initialDelay * (backoffMultiplier ^ attempt), maxDelay)
```

**Example with defaults:**
- Attempt 0: 1s * (2^0) = **1 second**
- Attempt 1: 1s * (2^1) = **2 seconds**
- Attempt 2: 1s * (2^2) = **4 seconds**
- Attempt 3: 1s * (2^3) = **8 seconds**

## Retryable Status Codes

| Code | Description | Reason |
|------|-------------|--------|
| 408 | Request Timeout | Client-side timeout, likely transient |
| 429 | Too Many Requests | Rate limiting, retry after backoff |
| 500 | Internal Server Error | Temporary server issue |
| 502 | Bad Gateway | Proxy/gateway error, often transient |
| 503 | Service Unavailable | Server overload or maintenance |
| 504 | Gateway Timeout | Upstream timeout, often temporary |

## HTTP Method Handling

### Retryable (Idempotent) Methods
- **GET**: Safe to retry (read-only)
- **HEAD**: Safe to retry (read-only)
- **PUT**: Idempotent (same result on multiple calls)
- **DELETE**: Idempotent (deleting multiple times = same result)
- **PATCH**: Generally idempotent
- **OPTIONS**: Safe to retry (metadata request)

### Non-Retryable Methods
- **POST**: Not idempotent (may create duplicates if retried)

## Error Types Handled

The interceptor automatically retries on these Dio error types:

- `connectionTimeout`: Connection establishment timeout
- `sendTimeout`: Data send timeout
- `receiveTimeout`: Response receive timeout
- `connectionError`: Network connection error

## Usage Example

### Basic Setup (Already Configured in APIClient)

```dart
final dio = Dio();

// Add retry interceptor
dio.interceptors.add(RetryInterceptor(
  dio: dio,
  policy: const RetryPolicy(), // Uses defaults
));
```

### Custom Configuration

```dart
// More aggressive retry policy
final customPolicy = RetryPolicy(
  maxAttempts: 5,
  initialDelay: Duration(milliseconds: 500),
  maxDelay: Duration(seconds: 60),
  backoffMultiplier: 3.0,
  retryableStatusCodes: {408, 429, 500, 502, 503, 504},
);

dio.interceptors.add(RetryInterceptor(
  dio: dio,
  policy: customPolicy,
));
```

## Logging Output

The interceptor logs retry attempts in debug mode:

```
🔄 RetryInterceptor: Retrying request (attempt 2/3) after 2000ms - GET /api/movies
   Status: 503
   
✅ RetryInterceptor: Retry successful - /api/movies
```

Or on failure:

```
❌ RetryInterceptor: Max attempts reached (3/3) - /api/movies
```

## Testing

### Unit Tests

Located in `test/api/models/retry_policy_test.dart` and `test/api/interceptors/retry_interceptor_test.dart`

Run tests:
```bash
flutter test test/api/models/retry_policy_test.dart
flutter test test/api/interceptors/retry_interceptor_test.dart
```

### Key Test Coverage

- ✅ Exponential backoff calculation
- ✅ Retryable status code validation
- ✅ HTTP method idempotency checks
- ✅ Retry count management
- ✅ Error type handling
- ✅ Max attempt enforcement

## Architecture

```
APIClient
  └─> Dio Instance
       ├─> LoggingInterceptor
       ├─> RetryInterceptor ← Handles transient failures
       ├─> AuthInterceptor
       └─> ErrorInterceptor
```

**Order matters**: RetryInterceptor is placed before AuthInterceptor so that retries happen at the network level before authentication processing.

## Interaction with Other Interceptors

1. **LoggingInterceptor**: Logs all requests including retries
2. **AuthInterceptor**: Runs after retry logic, handles token refresh
3. **ErrorInterceptor**: Converts errors to typed exceptions after retry exhaustion

## Best Practices

1. **Don't Retry Non-Idempotent Operations**: POST requests are not retried to avoid duplicates
2. **Use Appropriate Delays**: Default 1-2-4-8 second backoff prevents server overload
3. **Limit Max Attempts**: Default 3 attempts balances resilience vs. user wait time
4. **Monitor Retry Logs**: High retry rates may indicate systemic issues

## Limitations

- **POST Requests**: Not retried by design (non-idempotent)
- **Non-Network Errors**: Logic errors (400, 404, etc.) are not retried
- **Authentication Failures**: 401/403 errors handled by AuthInterceptor, not retried
- **Client Errors**: 4xx errors (except 408, 429) are not retried

## Performance Considerations

- **Total Wait Time**: With 3 attempts and exponential backoff, maximum retry delay is ~7 seconds (1s + 2s + 4s)
- **User Experience**: Retries are transparent to the user, no manual intervention needed
- **Battery Impact**: Minimal, only active during transient failures
- **Network Usage**: Retry attempts use additional bandwidth, but only for failed requests

## Future Enhancements

Potential improvements for future iterations:

- Jitter in backoff delays to prevent thundering herd
- Retry-After header parsing for 429 responses
- Circuit breaker pattern for persistent failures
- Per-endpoint retry configuration
- Metrics/telemetry for retry rates
