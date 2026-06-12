# Authentication Data Models

This directory contains the authentication-related data models for the Cinema Booking API Integration.

## Models Overview

### 1. AuthResponse (`auth_response.dart`)

JWT authentication response model containing access tokens and user profile.

**Fields:**
- `accessToken`: JWT access token (15 minute expiry)
- `refreshToken`: Refresh token (7 day expiry)
- `user`: UserProfile object
- `expiresAt`: Token expiration timestamp

**Helper Methods:**
- `isExpired`: Checks if access token has expired
- `timeUntilExpiry`: Returns duration until expiration

**Requirements Coverage:**
- Requirement 1.3: Google OAuth authentication response
- Requirement 2.3: Email/password authentication response

**Usage:**
```dart
// Deserialize from API response
final authResponse = AuthResponse.fromJson(jsonData);

// Check token status
if (authResponse.isExpired) {
  // Refresh token
}

// Access user profile
print('Welcome, ${authResponse.user.fullName}');
```

### 2. UserProfile (`user_profile.dart`)

User profile model with account information and membership details.

**Fields:**
- `id`: Unique user identifier
- `email`: User email address
- `fullName`: User's full name
- `phone`: Phone number (optional)
- `birthdate`: Date of birth (optional, required for T18 movies)
- `avatarUrl`: Avatar image URL (optional)
- `memberRank`: Membership tier (silver, gold, platinum)
- `points`: Loyalty points (1 point per 10,000 VND)
- `role`: User role (customer, staff, admin)
- `permissions`: Staff permissions array (optional)
- `isActive`: Account active status
- `createdAt`: Account creation timestamp

**Helper Methods:**
- `isCustomer`, `isStaff`, `isAdmin`: Role type checks
- `isAdult`: Checks if user is 18+ (for T18 movie bookings)
- `age`: Calculates user's age from birthdate

**Requirements Coverage:**
- Requirement 1.3: User profile data from OAuth
- Requirement 2.3: User profile data from email/password auth
- Requirement 7: Age verification for T18 movies

**Usage:**
```dart
// Deserialize from API
final profile = UserProfile.fromJson(jsonData);

// Role-based logic
if (profile.isStaff) {
  // Show staff features
}

// Age verification
if (!profile.isAdult) {
  // Block T18 movie bookings
}

// Display membership
print('Member Rank: ${profile.memberRank} (${profile.points} points)');
```

### 3. RegisterRequest (`register_request.dart`)

Registration request payload with comprehensive validation.

**Fields:**
- `email`: User email (validated format)
- `password`: User password (validated complexity)
- `fullName`: User's full name
- `phone`: Phone number (validated format: 0XXXXXXXXX or +84XXXXXXXXX)
- `birthdate`: Date of birth (optional)

**Validation Methods:**
- `validateEmail()`: Validates email format
- `validatePassword()`: Validates password complexity
  - Minimum 8 characters
  - At least one uppercase letter
  - At least one lowercase letter
  - At least one digit
  - At least one special character
- `validatePhone()`: Validates Vietnamese phone format
  - Format: 0 + 9 digits (total 10 digits)
  - OR: +84 + 9 digits
- `validate()`: Validates all fields, returns list of errors
- `isValid`: Boolean indicating if all fields are valid

**Requirements Coverage:**
- Requirement 2.1: Registration with email, password, fullName, phone
- Requirement 2.7: Password complexity requirements

**Usage:**
```dart
// Create registration request
final request = RegisterRequest(
  email: 'user@example.com',
  password: 'SecureP@ss123',
  fullName: 'John Doe',
  phone: '0901234567',
  birthdate: DateTime(1990, 1, 1),
);

// Validate before sending
if (!request.isValid) {
  final errors = request.validate();
  // Display errors to user
  print('Validation errors: ${errors.join(', ')}');
  return;
}

// Send to API
final json = request.toJson();
await apiClient.register(json);
```

## JSON Serialization

All models support JSON serialization using the `json_serializable` package:

```dart
// Deserialize from JSON
final model = ModelName.fromJson(jsonMap);

// Serialize to JSON
final jsonMap = model.toJson();
```

### Generated Files

The JSON serialization code is auto-generated in `.g.dart` files:
- `auth_response.g.dart`
- `user_profile.g.dart`
- `register_request.g.dart`

**To regenerate after model changes:**
```bash
dart run build_runner build
```

## Import Convenience

Use the barrel export file to import all authentication models at once:

```dart
import 'package:cine_book/models/auth_models.dart';

// All models are now available:
// - AuthResponse
// - UserProfile
// - RegisterRequest
```

## Testing

Comprehensive unit tests are located in `test/models/auth_models_test.dart`:

**Test Coverage:**
- ✅ JSON serialization/deserialization
- ✅ Token expiration checks
- ✅ Role type identification
- ✅ Age calculation and adult status
- ✅ Email validation
- ✅ Password validation
- ✅ Phone number validation
- ✅ Multi-field validation

**Run tests:**
```bash
flutter test test/models/auth_models_test.dart
```

## Requirements Mapping

| Requirement | Model | Field/Method |
|------------|-------|--------------|
| 1.3 - OAuth JWT tokens | AuthResponse | accessToken, refreshToken |
| 1.3 - User profile data | UserProfile | id, email, fullName, avatar, memberRank, points |
| 2.1 - Registration fields | RegisterRequest | email, password, fullName, phone |
| 2.3 - Auth response | AuthResponse | All fields |
| 2.7 - Password complexity | RegisterRequest | validatePassword() |
| 7 - T18 age verification | UserProfile | isAdult, age |

## Next Steps

These models are used by:
1. **API Client** (`lib/api/api_client.dart`) - For authentication endpoints
2. **Auth Service** (`lib/services/auth_service.dart`) - For authentication flow management
3. **UI Components** - For displaying user profiles and handling registration forms
