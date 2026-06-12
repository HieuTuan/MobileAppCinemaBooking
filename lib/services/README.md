# Services

This directory contains business logic services for the Cinema Booking application.

## Purpose

Services implement core business logic and coordinate interactions between different parts of the application. They handle authentication, state management, and complex operations.

## Planned Services

- **AuthService**: Manages authentication flows, token lifecycle, and user session
- **PaymentService**: Handles VNPay payment integration and webview management
- **PushNotificationHandler**: Manages push notification registration and routing
- **QRScannerService**: Handles QR code scanning for staff ticket validation
- **BookingFlowManager**: Orchestrates multi-step booking flow with state persistence

## Related Modules

- Uses: `lib/api/` for API communication
- Uses: `lib/models/` for data structures
- Uses: `lib/cache/` for offline support
- Uses: `lib/websocket/` for real-time updates
