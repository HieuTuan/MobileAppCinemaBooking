# WebSocket

This directory contains WebSocket client implementation for real-time features.

## Purpose

Manages real-time bidirectional communication with the backend server, primarily for live seat status synchronization during the booking process.

## Planned Components

### WebSocketClient
Main WebSocket client with the following features:

#### Connection Management
- Connects to: `wss://api.example.com/ws/showtimes/{showtimeId}/seats?token={jwt}`
- JWT authentication via query parameter
- Connection state tracking: connecting, connected, disconnected, error
- Automatic reconnection with exponential backoff: 1s → 2s → 4s → 8s → max 30s

#### Keepalive Mechanism
- Sends ping frames every 30 seconds
- Expects pong response within 5 seconds
- Closes stale connections

#### State Synchronization
- Receives real-time seat status updates
- Broadcasts updates via `Stream<SeatUpdate>`
- Full state resync after reconnection
- Integration with Cinema_Store for UI updates

#### Lifecycle Management
- Disconnects when app goes to background
- Reconnects when app returns to foreground

## Message Format

```json
{
  "type": "seat_update",
  "data": {
    "seatCode": "A1",
    "status": "held",
    "userId": "user-id-here",
    "expiresAt": "2024-01-01T12:00:00Z"
  }
}
```

## Seat Status Values
- `available`: Seat can be selected
- `held`: Temporarily reserved (10-minute hold)
- `booked`: Confirmed booking
- `selected`: Current user's selection (local state only)

## Related Modules

- Uses: `lib/api/` for state resync after reconnection
- Uses: `lib/models/` for SeatUpdate data structure
- Integrates with: `lib/src/state/cinema_store.dart`
- Used by: `lib/services/` and booking UI screens
