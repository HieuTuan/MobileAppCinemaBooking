# Models

This directory contains data models and entities for the Cinema Booking application.

## Purpose

Models define the data structures used throughout the application, including JSON serialization/deserialization for API communication.

## Code Generation Configuration

The project is configured with `build_runner` and `json_serializable` for automatic JSON serialization code generation.

### Configuration Files

- **pubspec.yaml**: Contains required dependencies
  - `json_annotation` (dependency): Provides annotations for model classes
  - `json_serializable` (dev_dependency): Code generator
  - `build_runner` (dev_dependency): Build system

- **build.yaml**: Configures json_serializable options
  - `create_factory: true` - Generates `fromJson()` factory constructors
  - `create_to_json: true` - Generates `toJson()` methods
  - `include_if_null: true` - Includes null values in JSON output
  - `field_rename: none` - Uses exact field names (no snake_case conversion)
  - See file for complete configuration

### Creating a New Model

1. **Create the model file** (e.g., `user_profile.dart`):

```dart
import 'package:json_annotation/json_annotation.dart';

part 'user_profile.g.dart';

@JsonSerializable()
class UserProfile {
  final String id;
  final String email;
  final String fullName;
  final String? phone;  // Nullable field
  
  UserProfile({
    required this.id,
    required this.email,
    required this.fullName,
    this.phone,
  });
  
  factory UserProfile.fromJson(Map<String, dynamic> json) =>
      _$UserProfileFromJson(json);
  
  Map<String, dynamic> toJson() => _$UserProfileToJson(this);
}
```

2. **Run code generation**:

```bash
# Generate code for all models
dart run build_runner build

# Watch for changes and auto-generate
dart run build_runner watch
```

3. **Use the model**:

```dart
// From JSON (API response)
final user = UserProfile.fromJson(jsonMap);

// To JSON (API request)
final jsonMap = user.toJson();
```

### Example Model

See `example_model.dart` for a working reference implementation.

## Planned Models

### Core Domain Models
- **UserProfile**: User account and profile information
- **Movie**: Movie details with ratings and metadata
- **Showtime**: Screening schedule information
- **Seat**: Seat layout and status information
- **Booking**: Booking details with status tracking
- **Payment**: Payment transaction information
- **FoodCombo**: Concession menu items
- **Review**: User movie reviews

### API Request/Response Models
- **AuthResponse**: Authentication token response
- **HoldResponse**: Seat hold confirmation
- **BookingResponse**: Booking creation response with payment URL
- **ValidationResult**: Ticket validation result

### Error Models
- **ApiError**: Structured API error response
- Custom exception classes for different error types

## Requirements Met

This configuration fulfills:
- **Requirement 33.8**: Serialize Dart model classes to JSON using code generation
- **Requirement 33.9**: Deserialize JSON responses into typed Dart model classes

## Related Modules

- Used by: `lib/api/`, `lib/services/`, `lib/cache/`
