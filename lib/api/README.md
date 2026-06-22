# API

This directory contains HTTP client implementation and API endpoint interfaces.

## Purpose

Manages all REST API communication with the backend server, including authentication, error handling, request/response serialization, and retry logic.

## Implemented Components

### APIClient (`api_client.dart`) ✅ COMPLETED

The core HTTP client built on top of Dio with the following features:

**Features:**
- **Singleton Pattern**: Ensures a single Dio instance across the app
- **Base URL Configuration**: Loads from environment variable `API_BASE_URL`
- **Timeout Configuration**:
  - Standard requests: 30 seconds
  - Payment operations: 60 seconds (using `createPaymentOptions()`)
- **Request/Response Logging**: Automatic logging in debug mode with formatted output
- **Status Code Handling**: Accepts all status codes < 500 for custom error handling

**Usage:**
```dart
import 'package:cine_book/api/api_client.dart';

// Get the singleton instance
final apiClient = APIClient();

// Standard GET request
final response = await apiClient.get('/api/movies');

// POST request with data
final response = await apiClient.post(
  '/api/bookings',
  data: {'userId': '123', 'showtimeId': '456'},
);

// Payment operation with extended timeout
final response = await apiClient.postPayment(
  '/api/payments',
  data: paymentData,
);
```

**Available Methods:**
- `get<T>()` - GET request with standard timeout
- `post<T>()` - POST request with standard timeout
- `postPayment<T>()` - POST request with 60s timeout (for payments)
- `put<T>()` - PUT request with standard timeout
- `patch<T>()` - PATCH request with standard timeout
- `delete<T>()` - DELETE request with standard timeout

**Helper Methods:**
- `createStandardOptions()` - Creates options with 30s timeout
- `createPaymentOptions()` - Creates options with 60s timeout
- `updateBaseUrl(String baseUrl)` - Updates the base URL at runtime

**Requirements Satisfied:**
- ✅ Requirement 33.1: Dio HTTP client with interceptors
- ✅ Requirement 33.6: Configurable timeouts (30s standard, 60s payment)

## Planned Components

### Core API Client Enhancements
- **Authentication Interceptor** (Task 2.2): Automatic JWT token attachment and refresh
- **Error Handling** (Task 2.3): Custom exception classes and error mapping
- **Retry Logic** (Task 2.4): Exponential backoff for network failures

### API Endpoint Groups
- **Authentication**: Login, register, logout, token refresh
- **Movies**: Search, filter, details, reviews
- **Showtimes**: Schedule queries and seat availability
- **Bookings**: Create, retrieve, cancel bookings
- **Payments**: VNPay integration endpoints
- **Reviews**: Create and retrieve movie reviews
- **User Profile**: Profile management
- **Admin Operations**: Dashboard, reports, CRUD operations
- **Staff Operations**: Ticket validation, booking search, room management

## Configuration

### Environment Variables

Set the base URL using environment variables:

```bash
flutter run --dart-define=API_BASE_URL=https://api.cineluxe.com
```

For a real Android phone on the same Wi-Fi as the backend machine, pass the PC
LAN IP once. The app derives both REST and WebSocket URLs from it:

```bash
flutter run -d <device-id> --dart-define=DEV_SERVER_HOST=192.168.1.15
```

Equivalent explicit configuration:

```bash
flutter run -d <device-id> \
  --dart-define=API_BASE_URL=http://192.168.1.15:8080 \
  --dart-define=WS_BASE_URL=ws://192.168.1.15:8080/ws/showtimes
```

Defaults:
- Web: `http://localhost:8080`
- Android emulator: `http://10.0.2.2:8080`
- Real phone: use `DEV_SERVER_HOST=<your-pc-lan-ip>`

### Timeouts
- Standard requests: 30 seconds
- Payment operations: 60 seconds

### Retry Policy (Planned)
- Max attempts: 3
- Retryable status codes: 408, 429, 500, 502, 503, 504
- Exponential backoff strategy

## Testing

Run API client tests:

```bash
flutter test test/api/api_client_test.dart
```

## Related Modules

- Uses: `lib/models/` for request/response types
- Uses: `lib/utils/` for secure storage
- Used by: `lib/services/`

