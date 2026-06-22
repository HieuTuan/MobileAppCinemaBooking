# State Management

This directory contains the Cinema_Store state management.

## Current Implementation

**cinema_store.dart** - Main state management using ChangeNotifier pattern with:
- User authentication state (currentUser)
- Movie, cinema, room, showtime data
- Booking and payment state
- API-backed movie/showtime/session state
- Business logic methods

## Integration with New Modules

The Cinema_Store integrates with the API, cache, and WebSocket modules:

### API Integration

1. **API-backed data**
   - Use `lib/api/` APIClient for all backend communication
   - Fetch data from REST endpoints

2. **Integrate real-time updates**
   - Connect to `lib/websocket/` WebSocketClient for seat status
   - Update seat state when WebSocket messages arrive
   - Maintain reactive UI updates via notifyListeners()

3. **Add offline support**
   - Use `lib/cache/` CacheManager for offline data
   - Fallback to cached data when offline
   - Display cache indicators in UI

4. **Delegate complex operations to services**
   - Authentication → `lib/services/AuthService`
   - Payment → `lib/services/PaymentService`
   - Booking flow → `lib/services/BookingFlowManager`
   - Keep Cinema_Store focused on state, delegate logic to services

### Integration Pattern

```dart
class CinemaStore extends ChangeNotifier {
  final APIClient _apiClient;
  final WebSocketClient _wsClient;
  final CacheManager _cache;
  final AuthService _auth;
  
  // State properties
  List<Movie> movies = [];
  List<Booking> bookings = [];
  Map<String, SeatStatus> seatStatuses = {};
  
  // Initialize with real-time updates
  Future<void> connectToShowtime(String showtimeId) async {
    await _wsClient.connect(showtimeId, _auth.accessToken);
    _wsClient.seatUpdateStream.listen((update) {
      seatStatuses[update.seatCode] = update.status;
      notifyListeners();
    });
  }
  
  // Fetch data from API with cache fallback
  Future<void> loadMovies() async {
    try {
      movies = await _apiClient.getMovies();
      await _cache.cacheMovies(movies);
    } catch (e) {
      // Offline - load from cache
      movies = await _cache.getCachedMovies();
    }
    notifyListeners();
  }
}
```

## Migration Strategy

1. Keep existing Cinema_Store structure
2. Add new dependencies (APIClient, WebSocketClient, etc.) as constructor parameters
3. Keep UI screens wired to repositories/services instead of local fixtures
4. Add error handling and loading states
5. Test each integration incrementally

## Related Modules

- Will use: `lib/api/` for REST API calls
- Will use: `lib/websocket/` for real-time seat updates
- Will use: `lib/cache/` for offline support
- Will use: `lib/services/` for complex business logic
- Will use: `lib/models/` for data structures
