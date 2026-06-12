# Utils

This directory contains utility classes and helper functions used throughout the application.

## Purpose

Provides reusable utility functions, constants, extensions, and helper classes that don't belong to a specific feature or service.

## Planned Components

### Security & Storage
- **SecureStorageService**: Token storage using Flutter Secure Storage
  - Stores JWT access tokens and refresh tokens
  - Uses platform-specific keychains (iOS Keychain, Android Keystore)
  - Methods: saveAccessToken, saveRefreshToken, getAccessToken, getRefreshToken, clearTokens

### Formatting & Validation
- **Validators**: Input validation utilities
  - Email format validation
  - Phone number format validation (+84 or 0 followed by 9-10 digits)
  - Password strength validation (8+ chars, uppercase, lowercase, digit, special char)
  - Birthdate validation (not in future, 18+ check for T18 movies)

- **Formatters**: Data formatting utilities
  - Currency formatting (VND/USD based on locale)
  - Date/time formatting (locale-aware)
  - Duration formatting (e.g., "2h 30m")

### QR Code Utilities
- **QRCodeParser**: Parse QR code format
  - Format: `CINELUXE|{bookingId}|{userId}|{showtimeId}|{seat1}-{seat2}-...`
  - Validation and extraction of booking information

### Network & Connectivity
- **NetworkConnectivityMonitor**: Detects online/offline state
  - Stream-based connectivity changes
  - Used for offline mode and cache sync

### Constants
- **AppConstants**: Application-wide constants
  - API base URL
  - Timeout durations
  - Hold timer duration (10 minutes)
  - Validation time windows
  - Rate limits

### Extensions
- **DateTimeExtensions**: DateTime utility methods
- **StringExtensions**: String manipulation helpers
- **ContextExtensions**: BuildContext helpers for navigation, dialogs, etc.

## Related Modules

- Used by: All other modules (`lib/api/`, `lib/services/`, `lib/models/`, etc.)
