# Cache

This directory contains offline caching implementation for local data persistence.

## Purpose

Manages local caching of bookings, movies, and QR codes for offline access. Implements stale-while-revalidate pattern for optimal user experience.

## Planned Components

### CacheManager
Main cache management class with the following features:

#### Booking Cache
- Store bookings locally for offline viewing
- Methods:
  - `cacheBooking(Booking)`: Store single booking
  - `getCachedBookings()`: Retrieve all cached bookings
  - `getCachedBooking(bookingId)`: Retrieve specific booking
  - `syncBookings()`: Fetch updates from API and refresh cache

#### Movie Cache
- Cache movie list for faster loading and offline browsing
- TTL (Time To Live): 1 hour
- Methods:
  - `cacheMovies(List<Movie>)`: Store movie list
  - `getCachedMovies()`: Retrieve cached movies
  - `isCacheStale()`: Check if cache needs refresh

#### QR Code Cache
- Store QR code images for offline ticket display
- Critical for entering cinema with unstable connectivity
- Methods:
  - `cacheQRCode(bookingId, imageData)`: Store QR code PNG as blob
  - `getCachedQRCode(bookingId)`: Retrieve cached QR code

#### Storage Backend
- Uses **sqflite** for structured caching
- Database tables:
  - `cached_bookings`: Booking records with timestamp
  - `cached_movies`: Movie records with timestamp
  - `cached_qr_codes`: QR code images as blobs

#### Sync Strategy
- **Stale-While-Revalidate**: Display cached data immediately while fetching fresh data in background
- Automatic sync on connectivity restoration
- Visual indicators for cached vs. live data

#### Cache Lifecycle
- Mark entries with timestamp on write
- Check staleness on read
- Automatic cleanup of expired entries
- Manual cache clear option in settings

## Offline Mode Features

### Supported Offline Operations
- View booking history
- Display QR code tickets
- Browse cached movie list

### Offline Indicators
- Visual badge showing "Cached" or "Offline Mode"
- Banner message: "Showing cached results"
- Timestamp of last sync

### Not Supported Offline
- Seat selection and booking creation
- Payment processing
- Review submission
- Profile updates

## Related Modules

- Uses: `lib/models/` for data structures
- Uses: `lib/utils/` for network connectivity monitoring
- Uses: `lib/api/` for sync operations
- Used by: `lib/services/` and UI screens
