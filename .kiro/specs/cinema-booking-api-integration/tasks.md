# Implementation Plan: Cinema Booking API Integration

## Overview

This implementation plan transforms the existing Flutter cinema booking prototype into a production-ready platform by implementing comprehensive backend API connectivity, real-time seat synchronization via WebSocket, VNPay payment integration, Google OAuth authentication, push notifications, QR code ticket generation and validation, offline support, and administrative capabilities. The implementation uses Dart/Flutter for the mobile client with Dio HTTP client, WebSocket client for real-time updates, and integration with external services (VNPay, Google OAuth, FCM).

## Tasks

- [x] 1. Set up project infrastructure and core dependencies
  - [x] 1.1 Add required Flutter packages to pubspec.yaml
    - Add dio, dio_http_cache, web_socket_channel, flutter_secure_storage, sqflite, google_sign_in, firebase_messaging, firebase_core, qr_flutter, mobile_scanner, cached_network_image, json_annotation, json_serializable packages
    - Configure dependency versions compatible with current Flutter SDK
    - _Requirements: 33.1, 34.1, 35.2_
  
  - [x] 1.2 Create project folder structure for feature modules
    - Create directories: lib/services/, lib/models/, lib/api/, lib/websocket/, lib/utils/, lib/cache/
    - Organize existing Cinema_Store state management
    - _Requirements: 33.1_
  
  - [x] 1.3 Configure code generation for JSON serialization
    - Set up build_runner and json_serializable in dev dependencies
    - Create build.yaml configuration file
    - _Requirements: 33.8, 33.9_

- [x] 2. Implement API Client module with authentication interceptors
  - [x] 2.1 Create APIClient class with Dio configuration
    - Implement base APIClient class with Dio instance
    - Configure base URL from environment variables
    - Set up request/response interceptors for logging
    - Add timeout configuration: 30s standard, 60s payment operations
    - _Requirements: 33.1, 33.6_
  
  - [x] 2.2 Implement authentication interceptor with token management
    - Create interceptor to attach JWT token to Authorization header
    - Implement automatic token refresh on 401 responses
    - Implement retry logic for original request after token refresh
    - Handle token refresh failure by clearing session and redirecting to login
    - _Requirements: 33.2, 33.3, 33.4_
  
  - [x] 2.3 Implement error handling and typed exception mapping
    - Create custom exception classes: ApiValidationException, ApiAuthException, ApiNotFoundException, ApiConflictException, ApiServerException, ApiRateLimitException
    - Map HTTP status codes to typed exceptions in interceptor
    - Parse error response body into ApiError model
    - _Requirements: 33.5, 30.1, 30.2, 30.3, 30.4_
  
  - [x] 2.4 Implement retry logic with exponential backoff
    - Create RetryPolicy class with configurable max attempts and delays
    - Implement retry interceptor for network failures
    - Configure retryable status codes: 408, 429, 500, 502, 503, 504
    - _Requirements: 33.7_

- [x] 3. Implement authentication API endpoints
  - [x] 3.1 Create authentication data models
    - Create AuthResponse, UserProfile, RegisterRequest models with JSON serialization
    - Generate JSON serialization code using build_runner
    - _Requirements: 1.3, 2.3_
  
  - [x] 3.2 Implement Google OAuth sign-in flow
    - Integrate google_sign_in package for OAuth flow
    - Implement loginWithGoogle method to exchange auth code
    - Parse and store JWT and Refresh tokens securely
    - _Requirements: 1.1, 1.2_
  
  - [x] 3.3 Implement email/password authentication endpoints
    - Implement loginWithEmail(email, password) endpoint
    - Implement register(email, password, fullName, phone) endpoint
    - Handle validation errors with inline error display
    - _Requirements: 2.1, 2.3, 2.6_
  
  - [x] 3.4 Implement logout and token refresh endpoints
    - Implement logout() method to revoke tokens on backend
    - Implement refreshToken(refreshToken) method
    - _Requirements: 1.7, 1.4_

- [x] 4. Implement secure storage service for tokens
  - [x] 4.1 Create SecureStorageService using Flutter Secure Storage
    - Implement token storage methods: saveAccessToken, saveRefreshToken, getAccessToken, getRefreshToken
    - Implement clearTokens method for logout
    - Use platform-specific keychains (iOS Keychain, Android Keystore)
    - _Requirements: 1.6, 33.2_

- [x] 5. Implement AuthService for session management
  - [x] 5.1 Create AuthService class with authentication state management
    - Implement signInWithGoogle, signInWithEmail, register, signOut methods
    - Implement Stream<AuthState> for reactive state updates
    - Store current user profile in memory
    - _Requirements: 1.1, 2.1, 2.3, 1.7_
  
  - [x] 5.2 Implement proactive token refresh mechanism
    - Monitor JWT expiration time
    - Automatically refresh token before expiry (e.g., when <5 minutes remaining)
    - Handle refresh failures by clearing session
    - _Requirements: 1.4, 1.5_
  
  - [x] 5.3 Implement authentication state persistence
    - Check for stored tokens on app launch
    - Auto-authenticate if valid tokens exist
    - Broadcast authentication state changes
    - _Requirements: 1.6_

- [x] 6. Checkpoint - Authentication flow complete
  - Ensure all authentication tests pass, verify token storage works correctly, ask the user if questions arise.

- [x] 7. Implement movie and showtime API endpoints
  - [x] 7.1 Create Movie and Showtime data models
    - Create Movie, Showtime, Review models with JSON serialization
    - Include all required fields from design document
    - Generate JSON serialization code
    - _Requirements: 3.1, 3.7_
  
  - [x] 7.2 Implement movie search and filtering endpoints
    - Implement getMovies(search, genre, status, page) with query parameters
    - Implement getMovieDetails(movieId) endpoint
    - Implement getMovieReviews(movieId, page) with pagination
    - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5, 3.6, 3.8_
  
  - [x] 7.3 Implement showtime endpoints
    - Implement getShowtimes(movieId, date) endpoint
    - Parse DateTime objects correctly for date filtering
    - _Requirements: 3.1_

- [x] 8. Implement WebSocket client for real-time seat updates
  - [x] 8.1 Create WebSocketClient class with connection management
    - Implement connect(showtimeId, jwtToken) method
    - Build WebSocket URL: wss://api.example.com/ws/showtimes/{showtimeId}/seats?token={jwt}
    - Implement disconnect() and dispose() methods
    - Manage connection state: connecting, connected, disconnected, error
    - _Requirements: 34.2, 34.3, 34.9_
  
  - [x] 8.2 Implement keepalive ping/pong mechanism
    - Send ping frames every 30 seconds
    - Expect pong response within 5 seconds
    - Close connection if pong timeout occurs
    - _Requirements: 4.8, 4.9_
  
  - [x] 8.3 Implement automatic reconnection with exponential backoff
    - Implement reconnection strategy: 1s → 2s → 4s → 8s → max 30s
    - Reset backoff on successful connection
    - Fetch full seat state from REST API after reconnection
    - _Requirements: 4.4, 4.5, 34.6_
  
  - [x] 8.4 Implement seat update stream processing
    - Parse incoming JSON messages into SeatUpdate objects
    - Emit updates via Stream<SeatUpdate>
    - Update Cinema_Store state when seat updates received
    - _Requirements: 4.2, 34.5_
  
  - [x] 8.5 Implement lifecycle management for background/foreground
    - Disconnect WebSocket when app goes to background
    - Reconnect and sync state when app returns to foreground
    - _Requirements: 34.7, 34.8_

- [x] 9. Implement seat booking API endpoints
  - [x] 9.1 Create Seat and SeatHold data models
    - Create Seat, SeatMap, HoldResponse models with JSON serialization
    - Include seat status enum: available, held, booked, selected
    - Generate JSON serialization code
    - _Requirements: 4.3, 5.4_
  
  - [x] 9.2 Implement seat status retrieval endpoint
    - Implement getSeats(showtimeId) endpoint
    - Parse seat layout with row, column, type, and status
    - _Requirements: 4.1_
  
  - [x] 9.3 Implement seat hold endpoint with conflict handling
    - Implement holdSeats(showtimeId, seatCodes) endpoint
    - Handle 409 Conflict responses for unavailable seats
    - Parse unavailable seat list from error response
    - Display seat conflict UI with retry option
    - _Requirements: 5.1, 5.2, 5.3, 5.4, 5.7, 6.3_
  
  - [x] 9.4 Implement hold timer countdown in UI
    - Display 10-minute countdown timer during seat hold
    - Show expiration warning when <2 minutes remaining
    - Handle hold expiration by releasing seats and showing timeout message
    - _Requirements: 5.4, 4.7_

- [x] 10. Implement food combo selection API
  - [x] 10.1 Create FoodCombo data models
    - Create FoodCombo, ComboSelection models with JSON serialization
    - Generate JSON serialization code
    - _Requirements: 8.2_
  
  - [x] 10.2 Implement food combo endpoints
    - Implement getFoodCombos() endpoint
    - Parse combo list with id, name, description, price, imageUrl
    - Store combo selection in local state with quantity
    - _Requirements: 8.1, 8.2, 8.3_

- [x] 11. Implement booking creation and management API
  - [x] 11.1 Create Booking data models
    - Create Booking, BookingResponse, CreateBookingRequest models with JSON serialization
    - Include all fields from design document
    - Generate JSON serialization code
    - _Requirements: 9.1, 9.4_
  
  - [x] 11.2 Implement booking creation endpoint
    - Implement createBooking(holdId, comboIds, userId) endpoint
    - Handle validation errors for invalid holdId or comboIds
    - Parse BookingResponse with paymentUrl
    - _Requirements: 9.1, 9.2, 8.4, 8.5, 8.6_
  
  - [x] 11.3 Implement booking retrieval endpoints
    - Implement getBookingDetails(bookingId) endpoint
    - Implement getUserBookings(status) with filtering
    - Implement getBookingQRCode(bookingId) endpoint
    - _Requirements: 18.1, 18.2, 18.3, 18.4, 10.5_
  
  - [x] 11.4 Implement booking cancellation endpoint
    - Implement cancelBooking(bookingId) endpoint
    - Handle time-based refund calculation (100% vs 50%)
    - Display cancellation confirmation with refund amount
    - _Requirements: 13.1, 13.2, 13.3, 13.4, 13.5, 13.6_

- [x] 12. Checkpoint - Core booking flow complete
  - Ensure movie browsing, seat selection, hold mechanism, and booking creation work end-to-end, ask the user if questions arise.

- [x] 13. Implement VNPay payment integration
  - [x] 13.1 Create PaymentService class
    - Implement processPayment(bookingId, paymentUrl) method
    - Implement pollPaymentStatus(bookingId) method
    - Create PaymentResult and PaymentStatus models
    - _Requirements: 9.3, 9.4, 36.1_
  
  - [x] 13.2 Implement payment webview integration
    - Integrate webview_flutter or flutter_inappwebview package
    - Open payment URL in webview with navigation controls
    - Monitor URL changes to detect VNPay return URL
    - Prevent back navigation during payment flow
    - _Requirements: 9.5, 36.2, 36.3, 36.8_
  
  - [x] 13.3 Implement payment result handling
    - Parse return URL parameters for payment status
    - Display success animation on payment success
    - Display error message and retry option on payment failure
    - Handle payment timeout (15 minutes) with automatic cancellation
    - _Requirements: 9.6, 9.9, 36.4, 36.5, 36.6, 36.7_
  
  - [x] 13.4 Implement payment status polling fallback
    - Poll booking status API if webview is force-closed
    - Poll every 2 seconds for 30 seconds maximum
    - Navigate to appropriate screen based on final status
    - _Requirements: 36.9_

- [x] 14. Implement QR code ticket generation and display
  - [x] 14.1 Implement QR code display in booking details
    - Use qr_flutter package to render QR code
    - Display QR code full-screen with booking metadata
    - Show movie title, showtime, seats, cinema location
    - _Requirements: 10.5, 10.6, 10.7_
  
  - [x] 14.2 Implement QR code format parsing utility
    - Create utility function to parse QR format: "CINELUXE|bookingId|userId|showtimeId|seats"
    - Validate QR code format and throw exceptions for invalid format
    - _Requirements: 10.1, 10.2_

- [x] 15. Implement staff QR code scanning and validation
  - [x] 15.1 Create QRScannerService class
    - Integrate mobile_scanner package for QR scanning
    - Implement startScanning and stopScanning methods
    - Request camera permissions
    - _Requirements: 11.1, 11.2_
  
  - [x] 15.2 Implement ticket validation endpoint
    - Implement validateTicket(bookingId, expectedShowtimeId) endpoint
    - Parse ValidationResult with success/error status
    - Display validation details: customer name, movie, seats
    - _Requirements: 11.3, 11.4, 11.5, 11.6, 11.7, 11.8, 11.9_
  
  - [x] 15.3 Implement validation time window enforcement
    - Check validation allowed 2 hours before to 30 minutes after showtime
    - Display appropriate error if outside time window
    - _Requirements: 11.10, 11.11_
  
  - [x] 15.4 Implement continuous scanning for staff efficiency
    - Continue scanning automatically after validation
    - Display success (green) or error (red) feedback
    - Play audio/vibration feedback for validation result
    - _Requirements: 11.9_

- [ ] 16. Implement staff manual booking lookup
  - [~] 16.1 Implement booking search endpoints
    - Implement searchBookings(bookingId, customerName) endpoint
    - Display search results with booking details
    - Limit results to showtimes within 24 hours
    - _Requirements: 12.1, 12.2, 12.3, 12.4_
  
  - [~] 16.2 Implement manual validation from search results
    - Display manual validation button for selected booking
    - Call validation endpoint with staffId
    - Apply same validation rules as QR code validation
    - _Requirements: 12.6, 12.7, 12.8_

- [ ] 17. Implement offline caching for bookings and movies
  - [~] 17.1 Create CacheManager class with sqflite
    - Set up sqflite database with tables: cached_bookings, cached_movies
    - Implement cacheBooking, getCachedBookings, getCachedBooking methods
    - Implement cacheMovies, getCachedMovies, isCacheStale methods
    - _Requirements: 35.1, 35.2, 35.6_
  
  - [~] 17.2 Implement QR code image caching
    - Implement cacheQRCode(bookingId, imageData) method
    - Implement getCachedQRCode(bookingId) method
    - Store QR code PNG as blob in database
    - _Requirements: 10.7, 35.1_
  
  - [~] 17.3 Implement offline mode UI with cache fallback
    - Display cached bookings with offline indicator when network unavailable
    - Display cached movies with "Showing cached results" banner
    - Load QR code from cache for offline ticket display
    - _Requirements: 35.3, 35.4, 35.8_
  
  - [~] 17.4 Implement cache synchronization on connectivity restoration
    - Detect network connectivity changes
    - Sync cached bookings with backend to detect updates
    - Fetch fresh movie data and update cache
    - Use stale-while-revalidate pattern: show cache immediately, fetch updates in background
    - _Requirements: 35.5, 35.7_

- [~] 18. Checkpoint - Staff features and offline support complete
  - Ensure QR scanning, validation, manual lookup, and offline caching work correctly, ask the user if questions arise.

- [ ] 19. Implement push notification support
  - [~] 19.1 Set up Firebase messaging integration
    - Add firebase_messaging and firebase_core packages
    - Configure Firebase project for Android and iOS
    - Set up GoogleService-Info.plist (iOS) and google-services.json (Android)
    - _Requirements: 15.3, 37.1_
  
  - [~] 19.2 Create PushNotificationHandler class
    - Implement initialize() method to set up Firebase messaging
    - Implement requestPermission() for notification permissions
    - Obtain FCM token (Android) or APNs token (iOS)
    - _Requirements: 15.4, 37.2_
  
  - [~] 19.3 Implement device registration endpoint
    - Implement registerDevice(deviceToken, platform) endpoint
    - Store device token on backend for push targeting
    - Handle token refresh when token changes
    - _Requirements: 37.3, 37.5_
  
  - [~] 19.4 Implement notification handling and routing
    - Handle foreground notifications with in-app banner
    - Handle background/terminated notification taps
    - Route to appropriate screen based on deeplink: booking details, movie details, promotions
    - _Requirements: 15.6, 15.7, 16.6_
  
  - [~] 19.5 Implement device unregistration on logout
    - Call unregisterDevice endpoint when user logs out
    - Clear device token from backend
    - _Requirements: 37.6_

- [ ] 20. Implement notification preferences management
  - [~] 20.1 Create notification preferences UI
    - Display toggle switches for: showtime reminders, promotions, new movies, booking updates
    - Implement getNotificationPreferences endpoint
    - Implement updateNotificationPreferences endpoint
    - _Requirements: 38.1, 38.2, 38.3, 38.6_
  
  - [~] 20.2 Handle critical notifications override
    - Ensure payment confirmations and booking cancellations always send regardless of preferences
    - _Requirements: 38.5_

- [ ] 21. Implement verified movie reviews
  - [~] 21.1 Create Review data models
    - Create Review, CreateReviewRequest models with JSON serialization
    - Generate JSON serialization code
    - _Requirements: 14.3_
  
  - [~] 21.2 Implement review creation endpoint
    - Implement createReview(movieId, rating, comment) endpoint
    - Handle 403 Forbidden error when user hasn't watched movie
    - Display verification badge for verified reviews
    - _Requirements: 14.1, 14.2, 14.3, 14.6_
  
  - [~] 21.3 Implement review validation
    - Validate rating is 1-5
    - Validate comment length is 10-500 characters
    - Display inline validation errors
    - _Requirements: 14.4, 14.5_
  
  - [~] 21.4 Implement review display with pagination
    - Display reviews with user name, rating, comment, timestamp, verification badge
    - Implement pagination for review list
    - _Requirements: 14.8, 14.9_

- [ ] 22. Implement user profile management
  - [~] 22.1 Create profile data models
    - Create UpdateProfileRequest, NotificationPreferences models with JSON serialization
    - Generate JSON serialization code
    - _Requirements: 17.1_
  
  - [~] 22.2 Implement profile endpoints
    - Implement getProfile() endpoint
    - Implement updateProfile(fullName, phone, birthdate) endpoint
    - Display member rank and points
    - _Requirements: 17.7, 17.1, 17.6_
  
  - [~] 22.3 Implement profile validation
    - Validate phone number format: +84 or 0 followed by 9-10 digits
    - Validate birthdate is not in future
    - Display inline validation errors
    - _Requirements: 17.2, 17.3_
  
  - [~] 22.4 Implement email verification flow
    - Handle email update with verification email requirement
    - Display pending email status until verified
    - _Requirements: 17.4_

- [ ] 23. Implement age verification for T18 movies
  - [~] 23.1 Create Age Gate modal component
    - Display modal when user selects T18-rated movie showtime
    - Require birthdate confirmation (18+ years old)
    - Store age confirmation in session
    - _Requirements: 7.1, 7.2, 7.3_
  
  - [~] 23.2 Implement backend age verification
    - Verify user birthdate on booking submission for T18 movies
    - Handle 403 Forbidden error with age requirement message
    - _Requirements: 7.5, 7.6, 7.7_

- [ ] 24. Implement admin dashboard APIs
  - [~] 24.1 Implement dashboard metrics endpoint
    - Implement getDashboardMetrics() endpoint for admin
    - Display today's revenue, bookings, active users, concurrent users
    - Display upcoming showtimes with occupancy rates
    - Display top 5 movies by sales
    - Display recent booking activity
    - _Requirements: 25.1, 25.2, 25.3, 25.4, 25.5_
  
  - [~] 24.2 Implement dashboard auto-refresh
    - Implement polling to refresh metrics every 60 seconds
    - Use 30-second cache TTL on backend
    - _Requirements: 25.6, 25.7_

- [ ] 25. Implement admin revenue and booking reports
  - [~] 25.1 Implement revenue report endpoint
    - Implement getRevenueReport(startDate, endDate) endpoint
    - Display total revenue, total bookings, average booking value
    - Display revenue breakdown by payment method
    - Display daily revenue series for charts
    - _Requirements: 24.1, 24.2, 24.3, 24.4_
  
  - [~] 25.2 Implement booking report endpoint
    - Implement getBookingReport(startDate, endDate) endpoint
    - Display booking statistics: total, confirmed, cancelled, refunded
    - Display movie rankings by ticket sales
    - Display occupancy rates per theater
    - _Requirements: 24.5, 24.6, 24.7, 24.8, 24.9_

- [ ] 26. Implement admin CRUD operations
  - [~] 26.1 Implement movie management endpoints
    - Implement POST /api/admin/movies for create
    - Implement PUT /api/admin/movies/{id} for update
    - Implement DELETE /api/admin/movies/{id} for delete
    - Handle conflict error when deleting movie with active showtimes
    - _Requirements: 19.1, 19.2, 19.3, 19.4, 19.5, 19.6, 19.7, 19.8_
  
  - [~] 26.2 Implement food combo management endpoints
    - Implement POST /api/admin/food-combos for create
    - Implement PUT /api/admin/food-combos/{id} for update
    - Implement PATCH /api/admin/food-combos/{id} for activate/deactivate
    - _Requirements: 20.1, 20.2, 20.3, 20.4, 20.5, 20.6, 20.7_
  
  - [~] 26.3 Implement theater and room management endpoints
    - Implement POST /api/admin/theaters for create
    - Implement POST /api/admin/rooms for create
    - Implement PATCH /api/admin/rooms/{id}/status for maintenance status
    - _Requirements: 21.1, 21.2, 21.3, 21.4, 21.5, 21.6, 21.7, 21.8_
  
  - [~] 26.4 Implement showtime scheduling endpoints
    - Implement POST /api/admin/showtimes for create
    - Implement PUT /api/admin/showtimes/{id} for update
    - Implement DELETE /api/admin/showtimes/{id} for delete
    - Handle scheduling conflict detection and prevention
    - _Requirements: 22.1, 22.2, 22.3, 22.4, 22.5, 22.6, 22.7, 22.8, 22.9, 22.10_
  
  - [~] 26.5 Implement user account management endpoints
    - Implement GET /api/admin/users for list with filtering
    - Implement POST /api/admin/users for staff account creation
    - Implement PATCH /api/admin/users/{id}/status for activate/deactivate
    - Implement PATCH /api/admin/users/{id}/permissions for permission updates
    - Implement DELETE /api/admin/users/{id} for delete
    - _Requirements: 23.1, 23.2, 23.3, 23.4, 23.5, 23.6, 23.7, 23.8, 23.9, 23.10_

- [ ] 27. Implement staff room status management
  - [~] 27.1 Implement room maintenance endpoints
    - Implement POST /api/staff/rooms/{id}/maintenance for reporting issues
    - Implement POST /api/staff/rooms/{id}/ready for resolving issues
    - Verify staff permissions before allowing operations
    - _Requirements: 27.1, 27.2, 27.3, 27.4, 27.5, 27.6, 27.7_

- [ ] 28. Implement staff customer support modifications
  - [~] 28.1 Implement booking modification endpoints
    - Implement POST /api/staff/bookings/{id}/modify-seats for seat changes
    - Implement POST /api/staff/bookings/{id}/modify-combos for combo changes
    - Calculate price differences and handle refunds/charges
    - Log all modifications with staff ID
    - _Requirements: 28.1, 28.2, 28.3, 28.4, 28.5, 28.6, 28.7, 28.8, 28.9_

- [ ] 29. Implement admin VNPay configuration
  - [~] 29.1 Implement payment settings endpoints
    - Implement GET /api/admin/settings/payment for viewing settings
    - Implement PUT /api/admin/settings/payment for updating settings
    - Validate VNPay terminal ID and secret key format
    - Mask secret key in responses (show only last 4 characters)
    - _Requirements: 26.1, 26.2, 26.3, 26.4, 26.5, 26.6, 26.7_

- [ ] 30. Implement image upload for admin
  - [~] 30.1 Implement image upload endpoint
    - Implement POST /api/admin/upload with multipart form data
    - Validate file type (JPEG, PNG, WebP) and size (<5MB)
    - Generate unique filename with UUID
    - Upload to cloud storage (AWS S3 or Cloudinary)
    - Return CDN URL
    - _Requirements: 40.1, 40.2, 40.3, 40.4, 40.5, 40.6, 40.7_
  
  - [~] 30.2 Implement image caching in customer app
    - Use cached_network_image package for efficient image loading
    - Display placeholder while loading, error icon on failure
    - _Requirements: 40.8, 40.9_

- [~] 31. Checkpoint - Admin and staff features complete
  - Ensure admin dashboard, reports, CRUD operations, staff modifications, and image upload work correctly, ask the user if questions arise.

- [ ] 32. Implement localization support
  - [~] 32.1 Set up flutter_localizations and ARB files
    - Add flutter_localizations package
    - Create ARB files for Vietnamese and English translations
    - Set up localization delegates
    - _Requirements: 39.3_
  
  - [~] 32.2 Implement language detection and switching
    - Detect device language on first launch
    - Implement language switcher in settings
    - Update UI immediately on language change without restart
    - Persist language preference in local storage
    - _Requirements: 39.1, 39.2, 39.7_
  
  - [~] 32.3 Implement locale-specific formatting
    - Format currency as Vietnamese Dong (₫) or USD ($)
    - Format dates and times using locale-appropriate formatting
    - Send Accept-Language header in API requests
    - _Requirements: 39.4, 39.5, 39.6_

- [ ] 33. Implement analytics tracking
  - [~] 33.1 Set up Firebase Analytics or Mixpanel
    - Add analytics package to pubspec.yaml
    - Configure analytics project
    - _Requirements: 41.2_
  
  - [~] 33.2 Implement event tracking
    - Track events: app_open, login, movie_view, seat_selection_start, booking_complete, payment_success, payment_fail
    - Include event properties: userId, movieId, showtimeId, totalAmount, seatCount
    - Track screen views with name and duration
    - _Requirements: 41.1, 41.3, 41.4_
  
  - [~] 33.3 Implement privacy-compliant tracking
    - Anonymize IP addresses
    - Comply with GDPR requirements
    - _Requirements: 41.7_
