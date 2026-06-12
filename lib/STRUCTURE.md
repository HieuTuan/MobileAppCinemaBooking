# Cinema Booking Project Structure

This document describes the organization of the Flutter Cinema Booking application.

## Directory Structure

```
lib/
├── api/                    # REST API client and endpoints
│   └── README.md          # API module documentation
│
├── cache/                 # Offline caching with SQLite
│   └── README.md         # Cache module documentation
│
├── models/                # Data models and JSON serialization
│   └── README.md         # Models documentation
│
├── services/              # Business logic services
│   └── README.md         # Services documentation
│
├── utils/                 # Utility functions and helpers
│   └── README.md         # Utils documentation
│
├── websocket/             # WebSocket client for real-time updates
│   └── README.md         # WebSocket documentation
│
├── src/                   # Existing application code
│   ├── core/             # Core utilities and formatters
│   ├── data/             # Seed data for development
│   ├── features/         # Feature-based UI screens
│   ├── models/           # Existing app models
│   ├── shared/           # Shared widgets and components
│   └── state/            # Cinema_Store state management
│       ├── cinema_store.dart
│       └── README.md     # State integration documentation
│
└── main.dart             # Application entry point
```

## Module Purposes

### API Module (`lib/api/`)
Handles all REST API communication with the backend server:
- HTTP client configuration with Dio
- Authentication interceptors
- Request/response serialization
- Error handling and retry logic
- Endpoint implementations for all backend operations

### Cache Module (`lib/cache/`)
Manages local data persistence for offline support:
- SQLite-based caching
- Booking and movie data storage
- QR code image caching
- Stale-while-revalidate pattern
- Automatic sync on connectivity restoration

### Models Module (`lib/models/`)
Defines data structures used throughout the app:
- Domain models (User, Movie, Booking, etc.)
- API request/response models
- Error models
- JSON serialization with build_runner

### Services Module (`lib/services/`)
Implements business logic and complex operations:
- AuthService: Authentication and session management
- PaymentService: VNPay payment integration
- PushNotificationHandler: Firebase messaging
- QRScannerService: Ticket validation
- BookingFlowManager: Multi-step booking orchestration

### Utils Module (`lib/utils/`)
Provides reusable utilities:
- SecureStorageService: Token storage
- Validators: Input validation
- Formatters: Data formatting
- QRCodeParser: QR code utilities
- NetworkConnectivityMonitor: Connectivity detection
- Constants and extensions

### WebSocket Module (`lib/websocket/`)
Handles real-time communication:
- WebSocket client implementation
- Seat status synchronization
- Automatic reconnection
- Keepalive ping/pong
- Connection state management

### Existing Src Module (`lib/src/`)
Contains the current application code:
- **core/**: Formatters and utilities
- **data/**: Seed data for development (will be replaced with API calls)
- **features/**: Feature-based UI screens
- **models/**: Existing app models
- **shared/**: Shared widgets and components
- **state/**: Cinema_Store (ChangeNotifier-based state management)

## Integration Flow

```
UI Screens (lib/src/features/)
    ↓
Cinema_Store (lib/src/state/)
    ↓
Services (lib/services/)
    ↓
API Client (lib/api/) ←→ WebSocket (lib/websocket/)
    ↓
Models (lib/models/)
    ↓
Cache (lib/cache/) + Utils (lib/utils/)
```

## Development Phases

### Phase 1: Infrastructure (Current)
- ✅ Create folder structure
- ✅ Document module purposes
- ⏳ Add dependencies to pubspec.yaml
- ⏳ Configure code generation

### Phase 2: Core Implementation
- Implement API client with authentication
- Create data models with JSON serialization
- Build WebSocket client for real-time updates
- Set up secure storage for tokens

### Phase 3: Service Layer
- Implement AuthService
- Build PaymentService
- Create BookingFlowManager
- Add push notification support

### Phase 4: Integration
- Connect Cinema_Store with API client
- Replace seed data with API calls
- Add WebSocket integration for seats
- Implement offline caching

### Phase 5: Testing & Polish
- Add error handling
- Implement loading states
- Test offline functionality
- Add analytics tracking

## Key Design Decisions

1. **Separation of Concerns**: Clear boundaries between API, business logic, state, and UI
2. **Existing State Preserved**: Cinema_Store remains the central state manager
3. **Progressive Enhancement**: New modules integrate gradually without breaking existing features
4. **Offline First**: Cache module ensures core functionality works offline
5. **Real-time Ready**: WebSocket module provides live updates for seat selection

## Next Steps

1. Add required Flutter packages to pubspec.yaml (Task 1.1)
2. Configure build_runner for JSON serialization (Task 1.3)
3. Implement APIClient class with Dio (Task 2.1)
4. Create authentication interceptors (Task 2.2)
5. Begin model creation with JSON serialization (Task 3.1)

## Related Documentation

- [API Module README](api/README.md)
- [Cache Module README](cache/README.md)
- [Models Module README](models/README.md)
- [Services Module README](services/README.md)
- [Utils Module README](utils/README.md)
- [WebSocket Module README](websocket/README.md)
- [State Integration README](src/state/README.md)
