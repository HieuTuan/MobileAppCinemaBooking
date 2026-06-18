# Requirements Document

## Introduction

This document specifies the requirements for implementing comprehensive backend API integration and missing features for a Flutter cinema booking mobile application (CineLuxe). The system currently has basic UI screens with mock data but requires full REST API connectivity, real-time seat synchronization, payment gateway integration, authentication services, and administrative capabilities to function as a production-ready cinema booking platform.

The implementation will transform the existing client-side prototype into a complete client-server application supporting customer booking flows, staff ticket validation, and administrative management operations.

**Technical Architecture:**
- **Mobile Platforms**: Android and iOS only (Flutter mobile app)
- **Backend**: Spring Boot 3.4.6 + Java 17 (located in /backend folder)
- **Database**: PostgreSQL with Spring Data JPA (Code First approach - entities define schema)
- **Architecture**: Spring MVC with controller/service/repository/entity/dto layers
- **Package Structure**: com.cineluxe.* with standard Spring Boot organization
- **Existing Modules**: Booking, ShowtimeSeat, FoodCombo, WebSocket seat updates

## Glossary

- **API_Client**: HTTP client library (Dio) for making REST API requests from Flutter application
- **Auth_Service**: Authentication service handling OAuth, JWT tokens, and session management
- **Booking_Service**: Spring Boot service managing seat reservations, holds, and booking lifecycle
- **Payment_Gateway**: VNPay payment service integration for processing transactions
- **QR_Generator**: Service generating QR codes for validated tickets
- **QR_Scanner**: Mobile scanner service for validating QR code tickets
- **Seat_Manager**: Real-time seat status synchronization service using WebSocket
- **Push_Notifier**: Push notification service using FCM (Android) and APNs (iOS)
- **Cinema_Store**: Flutter state management store (existing)
- **Spring_Boot_API**: RESTful API server (Spring Boot 3.4.6 + Java 17) providing all backend operations
- **JPA_Entity**: Java Persistence API entity classes defining database schema (Code First)
- **JWT_Token**: JSON Web Token for authenticated API requests
- **Refresh_Token**: Long-lived token for obtaining new access tokens
- **Hold_Timer**: 10-minute countdown timer for seat reservations
- **Verified_Review**: Movie review from users with confirmed paid bookings
- **Age_Gate**: Age verification mechanism for T18-rated movies
- **Refund_Calculator**: Service calculating refund amounts based on timing rules
- **WebSocket_Client**: Flutter client for real-time seat status updates (connects to Spring WebSocket endpoint)
- **HMAC_Validator**: VNPay payment signature validator using HMAC-SHA512

- **Admin_Dashboard**: Real-time administrative dashboard with metrics
- **Staff_Terminal**: Staff device for ticket validation operations
- **Customer_App**: Customer-facing Flutter mobile application (Android and iOS only)
- **T18_Rating**: Age rating requiring 18+ verification before booking
- **ShowtimeSeat_Entity**: JPA entity representing individual seat linked to specific showtime
- **Concurrent_Booking**: Multiple users attempting to book same seats simultaneously
- **Optimistic_Locking**: JPA @Version field preventing race conditions on ShowtimeSeat updates
- **Transaction_Log**: Audit trail of all booking and payment operations
- **Revenue_Report**: Financial reporting with date range filtering
- **Occupancy_Rate**: Percentage of seats sold for showtimes
- **Member_Points**: Loyalty points earned from bookings (1 point per 10,000 VND)
- **Food_Combo**: Pre-packaged food and beverage offering
- **Booking_Timeout**: Automatic cancellation of unpaid bookings after timeout
- **Response_Time**: API request-to-response duration metric
- **Uptime_SLA**: Service level agreement for system availability
- **PostgreSQL**: Relational database management system used for data persistence
- **Hibernate**: JPA implementation used by Spring Data JPA for ORM

## Requirements

### Requirement 1: User Authentication with Google OAuth

**User Story:** As a customer, I want to sign in with my Google account, so that I can quickly access the app without creating new credentials

#### Acceptance Criteria

1. WHEN a user taps "Sign in with Google", THE Auth_Service SHALL initiate Google OAuth 2.0 flow
2. WHEN Google OAuth completes successfully, THE Auth_Service SHALL exchange authorization code for JWT_Token and Refresh_Token via Spring Boot API
3. WHEN authentication succeeds, THE Spring_Boot_API SHALL return user profile data including id, email, fullName, avatar, memberRank, and points
4. WHEN JWT_Token expires, THE Auth_Service SHALL automatically refresh using Refresh_Token without user intervention
5. IF Refresh_Token is invalid or expired, THEN THE Auth_Service SHALL clear local session and redirect to login screen
6. THE Auth_Service SHALL store JWT_Token and Refresh_Token securely using Flutter Secure Storage
7. WHEN user logs out, THE Auth_Service SHALL revoke tokens on Spring_Boot_API and clear local storage
8. THE Spring_Boot_API SHALL validate JWT_Token signature and expiration on every authenticated request using Spring Security filters

### Requirement 2: Traditional Email/Password Authentication

**User Story:** As a customer, I want to register and sign in with email and password, so that I can use the app without a Google account

#### Acceptance Criteria

1. WHEN a user submits registration form with email, password, fullName, and phone, THE Spring_Boot_API SHALL validate email format and uniqueness using JPA repository
2. WHEN email is already registered, THE Spring_Boot_API SHALL return error with message "Email already exists"
3. WHEN registration is valid, THE Spring_Boot_API SHALL hash password using BCrypt and persist User entity with role customer via Spring Data JPA
4. WHEN user submits login credentials, THE Spring_Boot_API SHALL verify email and password hash match using Spring Security
5. WHEN credentials are invalid, THE Spring_Boot_API SHALL return error with message "Invalid email or password" after 200ms delay to prevent timing attacks
6. WHEN login succeeds, THE Spring_Boot_API SHALL return JWT_Token, Refresh_Token, and user profile
7. THE Spring_Boot_API SHALL enforce password minimum length of 8 characters using Bean Validation (@Size annotation)
8. THE Spring_Boot_API SHALL require password to contain at least one uppercase, one lowercase, one digit, and one special character using custom validator

### Requirement 3: Movie Search and Filtering API

**User Story:** As a customer, I want to search and filter movies by title, genre, and status, so that I can quickly find movies I want to watch

#### Acceptance Criteria

1. WHEN customer requests GET /api/movies with query parameters, THE Spring_Boot_API SHALL return matching movies within 300ms using JPA queries
2. WHEN query parameter contains search text, THE Spring_Boot_API SHALL match against title, director, cast members, and genres using JPQL (case-insensitive)
3. WHEN genre filter is specified, THE Spring_Boot_API SHALL return only movies containing that genre using @Query annotation
4. WHEN status filter is "nowShowing", THE Spring_Boot_API SHALL return only movies with status nowShowing
5. WHEN status filter is "comingSoon", THE Spring_Boot_API SHALL return only movies with status comingSoon
6. WHEN no filters are provided, THE Spring_Boot_API SHALL return all active movies sorted by releaseDate descending
7. THE Spring_Boot_API SHALL include movie fields: id, title, description, genres, durationMinutes, director, cast, posterUrl, trailerUrl, rating, ageRating, releaseDate, status
8. THE Spring_Boot_API SHALL support pagination with page and pageSize query parameters using Spring Data Pageable (defaulting to page 1 and pageSize 20)

### Requirement 4: Real-time Seat Status Synchronization

**User Story:** As a customer, I want to see live seat availability updates, so that I don't select seats that others are currently booking

#### Acceptance Criteria

1. WHEN customer opens seat selection screen, THE Seat_Manager SHALL establish WebSocket connection to ws://[backend]/ws/showtimes/{showtimeId}/seats using Spring WebSocket endpoint
2. WHEN any user selects or releases a seat, THE Seat_Manager SHALL broadcast seat status update to all connected clients within 2 seconds using Spring STOMP messaging
3. WHEN seat status message is received, THE Customer_App SHALL update seat visual state to available, held, booked, or selected
4. WHEN WebSocket connection drops, THE Seat_Manager SHALL attempt reconnection with exponential backoff starting at 1 second
5. WHEN reconnection succeeds, THE Seat_Manager SHALL sync complete current seat state from Spring_Boot_API REST endpoint
6. THE Spring_Boot_API SHALL maintain held seat status for exactly 10 minutes from hold initiation using ShowtimeSeat entity holdExpiresAt field
7. WHEN Hold_Timer expires, THE Spring_Boot_API SHALL automatically release held seats via scheduled task and broadcast availability update through WebSocket
8. THE WebSocket_Client SHALL send ping frames every 30 seconds to maintain connection
9. THE Spring_Boot_API SHALL respond with pong frames within 5 seconds or close stale connections

### Requirement 5: Seat Reservation with Hold Mechanism

**User Story:** As a customer, I want to reserve seats for 10 minutes while completing my booking, so that other users cannot take my selected seats

#### Acceptance Criteria

1. WHEN customer selects seats, THE API_Client SHALL POST /api/showtimes/{showtimeId}/seats/hold with seatCodes array and userId
2. WHEN requested seats are available, THE Booking_Service SHALL update ShowtimeSeat entities to held status using JPA @Transactional method
3. WHEN any requested seat is already held or booked, THE Spring_Boot_API SHALL return 409 Conflict with list of unavailable seats
4. WHEN hold succeeds, THE Spring_Boot_API SHALL return holdId, expiresAt timestamp, and confirmation of held seats
5. WHEN hold is created, THE Spring_Boot_API SHALL broadcast seat status change to all WebSocket clients via Spring STOMP
6. THE Booking_Service SHALL enforce maximum 8 seats per hold request using Bean Validation
7. WHEN hold request exceeds 8 seats, THE Spring_Boot_API SHALL return 400 Bad Request with message "Maximum 8 seats per booking"
8. WHEN user already has active hold for same showtime, THE Spring_Boot_API SHALL extend existing hold rather than create duplicate by querying SeatHold repository
9. THE Spring_Boot_API SHALL schedule automatic seat release job at expiresAt timestamp using @Scheduled task or Spring Task Scheduler

### Requirement 6: Concurrent Booking Race Condition Handling

**User Story:** As a system administrator, I want the system to handle concurrent seat bookings correctly, so that no two customers can book the same seat


#### Acceptance Criteria

1. WHEN multiple users attempt to hold same seat simultaneously, THE Booking_Service SHALL use JPA optimistic locking with @Version field on ShowtimeSeat entity
2. WHEN version conflict is detected by Hibernate, THE Spring_Boot_API SHALL retry the transaction up to 3 times with exponential backoff
3. WHEN first transaction commits seat hold successfully, THE Spring_Boot_API SHALL return success to first user and 409 Conflict to subsequent users
4. THE Booking_Service SHALL complete optimistic lock check and update within 500ms to prevent timeout
5. WHEN OptimisticLockException is caught after retry attempts, THE Spring_Boot_API SHALL return 409 Conflict with current seat state
6. IF all retry attempts fail, THEN THE Spring_Boot_API SHALL return 503 Service Unavailable with message "Unable to process request, please try again"
7. THE Booking_Service SHALL use @Transactional(isolation = READ_COMMITTED) to prevent dirty reads during concurrent updates
8. WHEN version mismatch is detected, THE Spring_Boot_API SHALL refresh entity from database and return current state to client

### Requirement 7: Age Verification for T18 Movies

**User Story:** As a cinema operator, I want to verify customer age before allowing T18 movie bookings, so that we comply with content rating regulations

#### Acceptance Criteria

1. WHEN customer selects showtime for movie with ageRating "T18", THE Customer_App SHALL display Age_Gate modal before seat selection
2. WHEN Age_Gate is displayed, THE Customer_App SHALL require user to confirm birthdate is before 18 years ago from current date
3. WHEN user confirms age eligibility, THE Customer_App SHALL store confirmation in session and proceed to seat selection
4. WHEN user declines or dismisses Age_Gate, THE Customer_App SHALL return to showtime list without opening seat selection
5. WHEN booking is submitted for T18 movie, THE Backend_API SHALL verify user profile birthdate indicates age 18 or older
6. IF user profile lacks birthdate or indicates age under 18, THEN THE Backend_API SHALL reject booking with 403 Forbidden and message "Age verification required for this movie"
7. THE Backend_API SHALL log all T18 booking attempts with userId, movieId, and verification result for audit compliance

### Requirement 8: Food Combo Selection API

**User Story:** As a customer, I want to add food combos to my booking, so that I can pre-order concessions for pickup

#### Acceptance Criteria

1. WHEN customer opens food selection screen, THE API_Client SHALL GET /api/food-combos to retrieve available offerings
2. THE Backend_API SHALL return Food_Combo list with id, name, description, price, and imageUrl within 200ms
3. WHEN customer selects combos, THE Customer_App SHALL store selection in local state with comboId and quantity
4. WHEN booking is submitted, THE API_Client SHALL include combos array with comboId and quantity in POST /api/bookings request
5. THE Backend_API SHALL validate all comboIds exist and are currently active
6. WHEN invalid comboId is provided, THE Backend_API SHALL return 400 Bad Request with message "Invalid food combo selection"
7. THE Backend_API SHALL calculate total combo cost as sum of (price × quantity) for all selected combos
8. THE Backend_API SHALL include combo cost in booking totalAmount calculation

### Requirement 9: VNPay Payment Gateway Integration

**User Story:** As a customer, I want to pay for my booking through VNPay, so that I can complete my purchase securely

#### Acceptance Criteria

1. WHEN customer confirms booking, THE API_Client SHALL POST /api/bookings with holdId, comboIds, and userId
2. WHEN booking is created, THE Backend_API SHALL generate payment request with bookingId, amount, and return URL
3. THE Backend_API SHALL create HMAC-SHA512 signature using VNPay secretKey and payment parameters
4. THE Backend_API SHALL return VNPay payment URL with signed parameters to Customer_App
5. WHEN Customer_App receives payment URL, THE Customer_App SHALL open in-app browser or webview with payment page
6. WHEN payment completes, VNPay SHALL redirect to return URL with transaction result parameters and signature
7. WHEN Backend_API receives payment callback, THE HMAC_Validator SHALL verify signature matches expected value using secretKey
8. IF signature verification fails, THEN THE Backend_API SHALL reject payment and log security incident
9. WHEN signature is valid and responseCode is "00", THE Backend_API SHALL mark payment as success and booking as active
10. WHEN responseCode indicates failure, THE Backend_API SHALL mark payment as failed and release held seats
11. THE Backend_API SHALL store VNPay transactionId, responseCode, and payment timestamp in Transaction_Log
12. THE Payment_Gateway SHALL complete payment flow within 15 minutes or automatically cancel

### Requirement 10: QR Code Ticket Generation

**User Story:** As a customer, I want to receive a QR code ticket after payment, so that I can present it for entry at the cinema

#### Acceptance Criteria

1. WHEN payment status changes to success, THE QR_Generator SHALL create QR code containing bookingId, userId, showtimeId, and seat codes
2. THE QR_Generator SHALL encode data in format: "CINELUXE|{bookingId}|{userId}|{showtimeId}|{seat1}-{seat2}-..."
3. THE QR_Generator SHALL generate QR code image as PNG with minimum 300x300 pixels resolution
4. THE Backend_API SHALL store QR code image URL or base64 data in booking record
5. WHEN customer views booking details, THE API_Client SHALL GET /api/bookings/{bookingId}/qr to retrieve QR code
6. THE Customer_App SHALL display QR code full-screen with booking details including movie title, showtime, seats, and cinema location
7. THE Customer_App SHALL enable offline QR code display by caching image locally after first retrieval
8. THE Backend_API SHALL include booking metadata in QR endpoint response: movieTitle, showtimeDateTime, roomName, cinemaName, seatCodes

### Requirement 11: Staff QR Code Ticket Validation

**User Story:** As a staff member, I want to scan and validate customer QR tickets, so that I can verify entry permissions at showtime

#### Acceptance Criteria

1. WHEN staff opens validation screen, THE Staff_Terminal SHALL activate camera for QR code scanning
2. WHEN QR code is detected, THE QR_Scanner SHALL decode content and extract bookingId
3. THE Staff_Terminal SHALL POST /api/bookings/{bookingId}/validate with expectedShowtimeId from current screening
4. THE Backend_API SHALL verify booking exists and status is active
5. WHEN booking status is used, THE Backend_API SHALL return 409 Conflict with message "Ticket already validated"
6. WHEN booking status is cancelled or refunded, THE Backend_API SHALL return 403 Forbidden with message "Ticket cancelled, entry denied"
7. WHEN booking showtimeId does not match expectedShowtimeId, THE Backend_API SHALL return 400 Bad Request with message "Wrong showtime" and include correct showtime details
8. WHEN validation succeeds, THE Backend_API SHALL update booking status to used and record validation timestamp and staffId
9. WHEN validation succeeds, THE Staff_Terminal SHALL display success message with customer name, movie title, and seat numbers
10. THE Backend_API SHALL accept validation requests from 2 hours before showtime until 30 minutes after showtime start
11. WHEN validation is attempted outside time window, THE Backend_API SHALL return 400 Bad Request with message "Validation window closed"

### Requirement 12: Manual Ticket Lookup for Staff

**User Story:** As a staff member, I want to look up bookings by ID or customer name, so that I can assist customers who cannot display their QR code

#### Acceptance Criteria

1. WHEN staff enters booking ID, THE Staff_Terminal SHALL GET /api/bookings/search?bookingId={id}
2. WHEN staff enters customer name, THE Staff_Terminal SHALL GET /api/bookings/search?customerName={name}
3. THE Backend_API SHALL return matching bookings with status, movieTitle, showtimeDateTime, seats, and qrCode
4. WHEN no bookings match search criteria, THE Backend_API SHALL return empty array with 200 OK
5. THE Backend_API SHALL limit search results to bookings for showtimes within 24 hours before and after current time
6. WHEN staff selects booking from results, THE Staff_Terminal SHALL display full booking details and enable manual validation button
7. WHEN staff triggers manual validation, THE Staff_Terminal SHALL POST /api/bookings/{bookingId}/validate with staffId
8. THE Backend_API SHALL apply same validation rules as QR code validation including time window and status checks

### Requirement 13: Booking Cancellation and Refund Calculation

**User Story:** As a customer, I want to cancel my booking and receive appropriate refund, so that I can recover costs if I cannot attend

#### Acceptance Criteria

1. WHEN customer requests cancellation, THE API_Client SHALL POST /api/bookings/{bookingId}/cancel with userId
2. THE Backend_API SHALL verify booking belongs to requesting user and status is active
3. WHEN cancellation is after showtime start, THE Backend_API SHALL return 400 Bad Request with message "Cannot cancel after showtime"
4. WHEN cancellation is more than 2 hours before showtime, THE Refund_Calculator SHALL calculate refund as 100% of totalAmount
5. WHEN cancellation is within 2 hours before showtime, THE Refund_Calculator SHALL calculate refund as 50% of totalAmount
6. WHEN cancellation succeeds, THE Backend_API SHALL update booking status to cancelled and create refund transaction
7. THE Backend_API SHALL initiate VNPay refund request with calculated refund amount
8. WHEN VNPay refund completes, THE Backend_API SHALL update payment status to refunded and record refund timestamp
9. THE Backend_API SHALL release cancelled booking seats and broadcast availability update to WebSocket clients
10. THE Backend_API SHALL deduct Member_Points equal to (totalAmount / 10000) from user account

### Requirement 14: Verified Movie Reviews

**User Story:** As a customer, I want to post reviews only for movies I've watched, so that reviews are trustworthy and verified

#### Acceptance Criteria

1. WHEN customer attempts to review movie, THE Backend_API SHALL verify user has at least one booking with status used for that movieId
2. WHEN user has no completed bookings for movie, THE Backend_API SHALL return 403 Forbidden with message "You must watch the movie before reviewing"
3. WHEN user is eligible, THE API_Client SHALL POST /api/reviews with userId, movieId, rating (1-5), and comment
4. THE Backend_API SHALL validate rating is integer between 1 and 5 inclusive
5. THE Backend_API SHALL validate comment length is between 10 and 500 characters
6. WHEN review is created, THE Backend_API SHALL mark review as verified and include verification badge in response
7. THE Backend_API SHALL recalculate movie average rating from all reviews and update movie record
8. WHEN customer views reviews, THE API_Client SHALL GET /api/movies/{movieId}/reviews with pagination support
9. THE Backend_API SHALL return reviews with userId, userName, rating, comment, createdAt, and isVerified flag

### Requirement 15: Push Notifications for Showtime Reminders

**User Story:** As a customer, I want to receive push notifications before my showtime, so that I don't miss my booked movie

#### Acceptance Criteria

1. WHEN booking payment succeeds, THE Backend_API SHALL schedule push notification for 2 hours before showtime
2. WHEN scheduled time arrives, THE Push_Notifier SHALL send notification to user device with title "Showtime Reminder" and body containing movie title and showtime
3. THE Push_Notifier SHALL use FCM for Android devices and APNs for iOS devices
4. WHEN customer has disabled showtime notifications in settings, THE Push_Notifier SHALL skip notification delivery
5. WHEN notification delivery fails, THE Backend_API SHALL retry up to 2 times with 5-minute intervals
6. THE Customer_App SHALL handle notification tap by navigating to booking details screen with bookingId
7. THE Backend_API SHALL log all notification delivery attempts with status, timestamp, and deviceId

### Requirement 16: Push Notifications for Promotions

**User Story:** As a marketing manager, I want to send promotional notifications to customers, so that I can inform them about special offers

#### Acceptance Criteria

1. WHEN admin creates banner with active status, THE Admin_Dashboard SHALL POST /api/notifications/broadcast with title, message, and target audience filter
2. THE Backend_API SHALL query users matching audience criteria (all, memberRank, or specific city)
3. THE Push_Notifier SHALL send notification to all matched user devices within 5 minutes
4. WHEN customer has disabled promotional notifications in settings, THE Push_Notifier SHALL exclude that user from broadcast
5. THE Backend_API SHALL track notification campaign with totalSent, totalDelivered, and totalOpened metrics
6. WHEN customer taps promotional notification, THE Customer_App SHALL navigate to promotions or movie list screen based on deeplink

### Requirement 17: User Profile Management API

**User Story:** As a customer, I want to update my profile information, so that I can keep my account details current

#### Acceptance Criteria

1. WHEN customer updates profile, THE API_Client SHALL PUT /api/users/{userId}/profile with fullName, phone, and birthdate
2. THE Backend_API SHALL validate phone number matches format +84 or 0 followed by 9-10 digits
3. THE Backend_API SHALL validate birthdate is valid date and not in future
4. WHEN email update is requested, THE Backend_API SHALL send verification email to new address before applying change
5. WHEN profile update succeeds, THE Backend_API SHALL return updated user profile with memberRank and points
6. THE Backend_API SHALL calculate memberRank based on total Member_Points: Silver (0-999), Gold (1000-4999), Platinum (5000+)
7. WHEN customer views profile, THE API_Client SHALL GET /api/users/{userId}/profile to retrieve current data

### Requirement 18: Booking History API

**User Story:** As a customer, I want to view my booking history, so that I can track past and upcoming movies


#### Acceptance Criteria

1. WHEN customer opens booking history, THE API_Client SHALL GET /api/users/{userId}/bookings with status filter and date range
2. THE Backend_API SHALL return bookings sorted by createdAt descending with pagination support
3. THE Backend_API SHALL include booking details: id, movieTitle, posterUrl, showtimeDateTime, cinemaName, roomName, seats, totalAmount, status, qrCodeUrl
4. WHEN customer filters by status, THE Backend_API SHALL return only bookings matching active, used, cancelled, or refunded status
5. WHEN customer taps booking, THE Customer_App SHALL navigate to booking detail screen showing full information and QR code
6. THE Backend_API SHALL return bookings within 200ms for 95% of requests

### Requirement 19: Admin Movie Management CRUD API

**User Story:** As an admin, I want to create, update, and delete movies, so that I can maintain the cinema's movie catalog

#### Acceptance Criteria

1. WHEN admin creates movie, THE API_Client SHALL POST /api/admin/movies with title, description, genres, durationMinutes, director, cast, posterUrl, trailerUrl, ageRating, and releaseDate
2. THE Backend_API SHALL validate ageRating is one of: P (All ages), C13 (13+), C16 (16+), C18 (18+), T18 (18+ with restrictions)
3. THE Backend_API SHALL validate durationMinutes is positive integer between 30 and 300
4. THE Backend_API SHALL generate unique movieId and set status based on releaseDate (comingSoon if future, nowShowing if today or past)
5. WHEN admin updates movie, THE API_Client SHALL PUT /api/admin/movies/{movieId} with modified fields
6. WHEN admin deletes movie, THE API_Client SHALL DELETE /api/admin/movies/{movieId}
7. WHEN movie has active showtimes, THE Backend_API SHALL prevent deletion and return 409 Conflict with message "Cannot delete movie with scheduled showtimes"
8. THE Backend_API SHALL return complete movie object after create and update operations

### Requirement 20: Admin Food Combo Management API

**User Story:** As an admin, I want to manage food combo offerings, so that I can update concession menu items

#### Acceptance Criteria

1. WHEN admin creates food combo, THE API_Client SHALL POST /api/admin/food-combos with name, description, price, imageUrl, and isActive
2. THE Backend_API SHALL validate price is positive integer representing VND amount
3. THE Backend_API SHALL generate unique comboId and store combo record
4. WHEN admin updates combo, THE API_Client SHALL PUT /api/admin/food-combos/{comboId} with modified fields
5. WHEN admin deactivates combo, THE API_Client SHALL PATCH /api/admin/food-combos/{comboId} with isActive false
6. THE Backend_API SHALL exclude inactive combos from customer-facing GET /api/food-combos endpoint
7. WHEN combo has been ordered in active bookings, THE Backend_API SHALL allow deactivation but preserve historical combo data in those bookings

### Requirement 21: Admin Theater and Room Management API

**User Story:** As an admin, I want to manage theaters and screening rooms, so that I can configure cinema locations and capacities

#### Acceptance Criteria

1. WHEN admin creates theater, THE API_Client SHALL POST /api/admin/theaters with name, address, city, latitude, longitude, and phone
2. THE Backend_API SHALL generate unique theaterId and store theater record
3. WHEN admin creates room, THE API_Client SHALL POST /api/admin/rooms with theaterId, name, capacity, screenType, and seat layout configuration
4. THE Backend_API SHALL validate capacity matches total seat count in layout configuration
5. THE Backend_API SHALL generate room-specific Showtime_Seat records based on layout with seatCode, row, column, and seatType
6. WHEN admin updates room status, THE API_Client SHALL PATCH /api/admin/rooms/{roomId}/status with status ready or maintenance
7. WHEN room is set to maintenance, THE Backend_API SHALL prevent new showtime creation for that room
8. THE Backend_API SHALL return room details including seat layout and current status

### Requirement 22: Admin Showtime Scheduling API

**User Story:** As an admin, I want to schedule movie showtimes, so that customers can book tickets for specific screenings

#### Acceptance Criteria

1. WHEN admin creates showtime, THE API_Client SHALL POST /api/admin/showtimes with movieId, roomId, startTime, and basePrice
2. THE Backend_API SHALL calculate endTime by adding movie durationMinutes plus 15-minute cleanup buffer to startTime
3. THE Backend_API SHALL validate room is not in maintenance status
4. THE Backend_API SHALL validate no scheduling conflict exists (other showtime in same room overlapping time range)
5. WHEN scheduling conflict is detected, THE Backend_API SHALL return 409 Conflict with details of conflicting showtime
6. THE Backend_API SHALL validate startTime is at least 1 hour in the future
7. THE Backend_API SHALL generate unique showtimeId and create showtime record with status scheduled
8. THE Backend_API SHALL create Showtime_Seat records linking all room seats to new showtime with status available
9. WHEN admin updates showtime, THE API_Client SHALL PUT /api/admin/showtimes/{showtimeId} with modified startTime or basePrice
10. WHEN admin deletes showtime with existing bookings, THE Backend_API SHALL prevent deletion and return 409 Conflict

### Requirement 23: Admin User Account Management API

**User Story:** As an admin, I want to manage user accounts and permissions, so that I can control system access

#### Acceptance Criteria

1. WHEN admin lists users, THE API_Client SHALL GET /api/admin/users with role filter and pagination
2. THE Backend_API SHALL return users with id, fullName, email, phone, role, memberRank, points, isActive, and permissions
3. WHEN admin creates staff account, THE API_Client SHALL POST /api/admin/users with fullName, email, role staff, and permissions array
4. THE Backend_API SHALL generate temporary password and send welcome email with credentials
5. WHEN admin toggles user status, THE API_Client SHALL PATCH /api/admin/users/{userId}/status with isActive boolean
6. WHEN user is deactivated, THE Backend_API SHALL revoke all active JWT tokens for that user
7. WHEN admin updates permissions, THE API_Client SHALL PATCH /api/admin/users/{userId}/permissions with permissions array
8. THE Backend_API SHALL validate permissions are valid values: "Soát vé", "Quản lý phòng", "Báo cáo kỹ thuật"
9. WHEN admin deletes user, THE API_Client SHALL DELETE /api/admin/users/{userId}
10. WHEN user has active bookings, THE Backend_API SHALL prevent deletion and return 409 Conflict

### Requirement 24: Admin Revenue and Booking Reports API

**User Story:** As an admin, I want to view revenue and booking reports, so that I can analyze business performance


#### Acceptance Criteria

1. WHEN admin requests revenue report, THE API_Client SHALL GET /api/admin/reports/revenue with startDate and endDate parameters
2. THE Backend_API SHALL aggregate successful payments within date range and return totalRevenue, totalBookings, and averageBookingValue
3. THE Backend_API SHALL break down revenue by payment method (vnpay, momo, cash) with amount and count per method
4. THE Backend_API SHALL include daily revenue series for chart visualization
5. WHEN admin requests booking report, THE API_Client SHALL GET /api/admin/reports/bookings with date range
6. THE Backend_API SHALL return booking statistics: total, confirmed, cancelled, refunded counts and percentages
7. THE Backend_API SHALL rank movies by ticket sales with movieTitle, totalTickets, and totalRevenue
8. THE Backend_API SHALL calculate Occupancy_Rate per theater as (bookedSeats / totalSeats) × 100
9. THE Backend_API SHALL complete report generation within 2 seconds for date ranges up to 90 days

### Requirement 25: Admin Real-time Dashboard API

**User Story:** As an admin, I want to see real-time metrics on my dashboard, so that I can monitor current operations

#### Acceptance Criteria

1. WHEN admin opens dashboard, THE API_Client SHALL GET /api/admin/dashboard/metrics
2. THE Backend_API SHALL return today's revenue, today's booking count, active user count (last 24 hours), and current concurrent users
3. THE Backend_API SHALL return upcoming showtimes in next 4 hours with occupancy percentage
4. THE Backend_API SHALL return top 5 movies by ticket sales this week with sales counts
5. THE Backend_API SHALL return recent booking activity (last 10 bookings) with customerName, movieTitle, amount, and timestamp
6. THE Backend_API SHALL cache dashboard metrics with 30-second TTL to reduce database load
7. THE Admin_Dashboard SHALL refresh metrics every 60 seconds using polling or WebSocket updates

### Requirement 26: Admin VNPay Configuration API

**User Story:** As an admin, I want to configure VNPay payment settings, so that I can manage payment gateway integration

#### Acceptance Criteria

1. WHEN admin views payment settings, THE API_Client SHALL GET /api/admin/settings/payment
2. THE Backend_API SHALL return VNPay configuration with terminalId, environment (sandbox/production), and masked secretKey (showing only last 4 characters)
3. WHEN admin updates settings, THE API_Client SHALL PUT /api/admin/settings/payment with terminalId, secretKey, and environment
4. THE Backend_API SHALL validate terminalId format matches VNPay specification (8 alphanumeric characters)
5. THE Backend_API SHALL validate secretKey is at least 32 characters
6. THE Backend_API SHALL encrypt secretKey before storing in database
7. THE Backend_API SHALL log configuration changes with adminId and timestamp for audit trail

### Requirement 27: Staff Room Status Management API

**User Story:** As a staff member, I want to update room status and report technical issues, so that operations team can respond to problems

#### Acceptance Criteria

1. WHEN staff sets room to maintenance, THE API_Client SHALL POST /api/staff/rooms/{roomId}/maintenance with reason and description
2. THE Backend_API SHALL verify staff has "Quản lý phòng" permission
3. WHEN permission is missing, THE Backend_API SHALL return 403 Forbidden
4. THE Backend_API SHALL update room status to maintenance and create TechnicalIssue record with staffId, roomId, description, and status "Đã gửi Admin"
5. THE Backend_API SHALL notify admin users via push notification about technical issue
6. WHEN staff resolves issue, THE API_Client SHALL POST /api/staff/rooms/{roomId}/ready with resolution notes
7. THE Backend_API SHALL update room status to ready and close TechnicalIssue record with resolvedAt timestamp

### Requirement 28: Staff Customer Support API

**User Story:** As a staff member, I want to assist customers with booking modifications, so that I can resolve customer service issues

#### Acceptance Criteria

1. WHEN customer requests seat change, staff SHALL POST /api/staff/bookings/{bookingId}/modify-seats with new seatCodes and staffId
2. THE Backend_API SHALL verify booking status is active and showtime is at least 30 minutes in future
3. THE Backend_API SHALL verify new seats are available and count matches original seat count
4. THE Backend_API SHALL calculate price difference if new seats have different types
5. WHEN price difference is positive, THE Backend_API SHALL require additional payment before applying change
6. WHEN price difference is negative or zero, THE Backend_API SHALL apply seat change immediately
7. THE Backend_API SHALL log modification with staffId, originalSeats, newSeats, and timestamp
8. WHEN customer requests combo modification, staff SHALL POST /api/staff/bookings/{bookingId}/modify-combos with new comboIds
9. THE Backend_API SHALL recalculate totalAmount and issue refund or charge difference as appropriate

### Requirement 29: Automated Seat Release Scheduled Job


**User Story:** As a system administrator, I want expired seat holds to release automatically, so that seats don't remain blocked unnecessarily

#### Acceptance Criteria

1. THE Backend_API SHALL run scheduled job every 60 seconds checking for expired seat holds
2. WHEN seat hold expiresAt timestamp is before current time, THE Backend_API SHALL update Showtime_Seat status from held to available
3. THE Backend_API SHALL broadcast seat status change to all connected WebSocket clients
4. THE Backend_API SHALL log hold release with holdId, showtimeId, seatCodes, and releaseReason "timeout"
5. THE Backend_API SHALL delete hold record after seat release
6. THE scheduled job SHALL process expired holds within 30 seconds of expiration time
7. THE scheduled job SHALL handle concurrent execution safely using distributed locks when running multiple API instances

### Requirement 30: API Performance and Error Handling

**User Story:** As a developer, I want consistent error responses and performance monitoring, so that I can diagnose issues effectively

#### Acceptance Criteria

1. THE Backend_API SHALL return errors in consistent JSON format with fields: code, message, timestamp, and path
2. WHEN validation fails, THE Backend_API SHALL return 400 Bad Request with detailed field errors
3. WHEN authentication fails, THE Backend_API SHALL return 401 Unauthorized with message "Invalid or expired token"
4. WHEN authorization fails, THE Backend_API SHALL return 403 Forbidden with message "Insufficient permissions"
5. WHEN resource not found, THE Backend_API SHALL return 404 Not Found with message identifying missing resource
6. WHEN server error occurs, THE Backend_API SHALL return 500 Internal Server Error and log full stack trace
7. THE Backend_API SHALL respond to 95% of requests within 500ms measured at server
8. THE Backend_API SHALL respond to GET requests within 300ms for 95% of requests
9. THE Backend_API SHALL log all requests with method, path, responseTime, statusCode, and userId
10. THE Backend_API SHALL expose /health endpoint returning status up or down and database connectivity status

### Requirement 31: API Rate Limiting and Security

**User Story:** As a system administrator, I want API rate limiting and security controls, so that the system is protected from abuse

#### Acceptance Criteria

1. THE Backend_API SHALL enforce rate limit of 100 requests per minute per IP address for unauthenticated endpoints
2. THE Backend_API SHALL enforce rate limit of 500 requests per minute per userId for authenticated endpoints
3. WHEN rate limit is exceeded, THE Backend_API SHALL return 429 Too Many Requests with Retry-After header
4. THE Backend_API SHALL validate all input data against SQL injection patterns and reject suspicious requests
5. THE Backend_API SHALL sanitize all user-provided content before storing to prevent XSS attacks
6. THE Backend_API SHALL use HTTPS for all API communications in production environment
7. THE Backend_API SHALL implement CORS policy allowing only configured frontend origins
8. THE Backend_API SHALL log all authentication failures with IP address, attempted email, and timestamp for security monitoring

### Requirement 32: Database Schema and Migrations

**User Story:** As a developer, I want a well-defined database schema with migration support, so that schema changes are managed safely


#### Acceptance Criteria

1. THE Backend_API SHALL use relational database with tables: Users, Movies, Theaters, Rooms, RoomSeats, Showtimes, ShowtimeSeats, SeatHolds, Bookings, Payments, Reviews, FoodCombos, BookingCombos, Notifications, TechnicalIssues
2. THE Backend_API SHALL implement foreign key constraints ensuring referential integrity
3. THE Backend_API SHALL index frequently queried columns: Users.email, Bookings.userId, Bookings.showtimeId, ShowtimeSeats.showtimeId, Payments.bookingId
4. THE Backend_API SHALL use database migrations for schema changes with up and down functions
5. THE Backend_API SHALL version migrations with timestamp-based naming: YYYYMMDDHHMMSS_description
6. THE Backend_API SHALL store createdAt and updatedAt timestamps on all entities using database triggers or ORM hooks
7. THE Backend_API SHALL use UUID or auto-incrementing integers for primary keys
8. THE Backend_API SHALL implement soft deletes with deletedAt column for Users, Movies, and Bookings to preserve history

### Requirement 33: Flutter API Client Integration

**User Story:** As a Flutter developer, I want a typed API client library, so that I can make API requests with type safety

#### Acceptance Criteria

1. THE API_Client SHALL use Dio HTTP client library with interceptors for authentication and error handling
2. THE API_Client SHALL automatically attach JWT_Token to Authorization header as "Bearer {token}" for authenticated requests
3. WHEN JWT_Token expires (401 response), THE API_Client SHALL automatically refresh using Refresh_Token and retry original request
4. WHEN token refresh fails, THE API_Client SHALL clear local session and navigate to login screen
5. THE API_Client SHALL parse error responses into typed exception classes: ApiValidationException, ApiAuthException, ApiNotFoundException, ApiServerException
6. THE API_Client SHALL provide request timeout of 30 seconds for standard requests and 60 seconds for payment operations
7. THE API_Client SHALL implement retry logic with exponential backoff for network failures up to 3 attempts
8. THE API_Client SHALL serialize Dart model classes to JSON using code generation (json_serializable)
9. THE API_Client SHALL deserialize JSON responses into typed Dart model classes matching backend DTOs

### Requirement 34: WebSocket Client Implementation

**User Story:** As a Flutter developer, I want a WebSocket client for real-time updates, so that seat status stays synchronized

#### Acceptance Criteria

1. THE WebSocket_Client SHALL use web_socket_channel package for WebSocket connectivity
2. THE WebSocket_Client SHALL connect to wss://api.example.com/ws/showtimes/{showtimeId}/seats with JWT token in query parameter
3. THE WebSocket_Client SHALL handle connection state changes: connecting, connected, disconnected, error
4. WHEN connection is established, THE WebSocket_Client SHALL emit connected event to listeners
5. WHEN seat update message is received, THE WebSocket_Client SHALL parse JSON and update Cinema_Store seat state
6. WHEN connection drops, THE WebSocket_Client SHALL attempt reconnection with exponential backoff: 1s, 2s, 4s, 8s, max 30s
7. WHEN app goes to background, THE WebSocket_Client SHALL close connection to preserve battery
8. WHEN app returns to foreground, THE WebSocket_Client SHALL reconnect and sync seat state
9. THE WebSocket_Client SHALL provide close method to cleanly disconnect when leaving seat selection screen

### Requirement 35: Offline Support and Caching


**User Story:** As a customer, I want to view my tickets offline, so that I can access them without internet connectivity

#### Acceptance Criteria

1. WHEN booking payment succeeds, THE Customer_App SHALL cache booking details including QR code image in local storage
2. THE Customer_App SHALL use sqflite database for local caching with tables: cached_bookings, cached_movies
3. WHEN customer views booking list offline, THE Customer_App SHALL display cached bookings with offline indicator
4. WHEN customer taps cached booking, THE Customer_App SHALL display full details and QR code from local storage
5. WHEN app regains connectivity, THE Customer_App SHALL sync cached bookings with backend to detect cancellations or modifications
6. THE Customer_App SHALL cache movie list and details with 1-hour TTL
7. WHEN cached data is stale, THE Customer_App SHALL fetch fresh data from API and update cache
8. THE Customer_App SHALL display loading state with cache data while fetching updates (stale-while-revalidate pattern)

### Requirement 36: Payment Flow Integration

**User Story:** As a customer, I want a smooth payment experience, so that I can complete my booking quickly

#### Acceptance Criteria

1. WHEN customer taps "Pay Now", THE Customer_App SHALL show loading indicator and POST booking to API
2. WHEN API returns payment URL, THE Customer_App SHALL open webview with URL and navigation controls
3. THE Customer_App SHALL monitor webview URL changes to detect return URL with payment result
4. WHEN return URL is detected, THE Customer_App SHALL close webview and parse payment result parameters
5. WHEN payment succeeds, THE Customer_App SHALL show success animation and navigate to booking confirmation screen
6. WHEN payment fails, THE Customer_App SHALL show error message with failure reason and offer retry option
7. WHEN payment times out (15 minutes), THE Customer_App SHALL show timeout message and release held seats
8. THE Customer_App SHALL prevent back navigation during payment to avoid incomplete transactions
9. WHEN user forces webview close, THE Customer_App SHALL poll booking status API to confirm payment state

### Requirement 37: Push Notification Device Registration

**User Story:** As a customer, I want to receive push notifications, so that the system can send me reminders and updates

#### Acceptance Criteria

1. WHEN app launches and user is authenticated, THE Customer_App SHALL request notification permission from OS
2. WHEN permission is granted, THE Push_Notifier SHALL obtain FCM token (Android) or APNs token (iOS)
3. THE Customer_App SHALL POST /api/users/{userId}/devices with deviceToken, platform, and deviceModel
4. THE Backend_API SHALL store device registration with userId, deviceToken, platform, isActive, and registeredAt
5. WHEN device token changes (app reinstall), THE Customer_App SHALL update registration with new token
6. WHEN user logs out, THE Customer_App SHALL DELETE /api/users/{userId}/devices/{deviceToken} to stop notifications
7. THE Backend_API SHALL mark device as inactive when push delivery fails repeatedly (3+ consecutive failures)

### Requirement 38: Notification Preferences Management

**User Story:** As a customer, I want to control which notifications I receive, so that I only get relevant alerts

#### Acceptance Criteria

1. WHEN customer opens notification settings, THE API_Client SHALL GET /api/users/{userId}/notification-preferences
2. THE Backend_API SHALL return preferences with categories: showtimeReminders, promotions, newMovies, bookingUpdates (each boolean)
3. WHEN customer toggles preference, THE API_Client SHALL PATCH /api/users/{userId}/notification-preferences with updated category
4. THE Backend_API SHALL respect preferences when sending notifications, skipping categories disabled by user
5. THE Backend_API SHALL always send critical notifications (payment confirmations, booking cancellations) regardless of preferences
6. THE Customer_App SHALL display toggle switches for each category with descriptive labels

### Requirement 39: Language Localization Support

**User Story:** As a customer, I want to use the app in Vietnamese or English, so that I can understand the interface in my preferred language

#### Acceptance Criteria

1. THE Customer_App SHALL detect device language on first launch and default to Vietnamese or English
2. WHEN customer changes language in settings, THE Customer_App SHALL update all UI text immediately without restart
3. THE Customer_App SHALL use flutter_localizations package with ARB files for translations
4. THE Customer_App SHALL format currency amounts as Vietnamese Dong (₫) or USD ($) based on selected language
5. THE Customer_App SHALL format dates and times using locale-appropriate formatting
6. THE Backend_API SHALL accept Accept-Language header and return localized error messages when available
7. THE Cinema_Store SHALL persist language preference in local storage

### Requirement 40: Image Upload and CDN Integration

**User Story:** As an admin, I want to upload movie posters and food images, so that they display in the app


#### Acceptance Criteria

1. WHEN admin selects image file, THE Admin_Dashboard SHALL POST /api/admin/upload with multipart form data
2. THE Backend_API SHALL validate file type is JPEG, PNG, or WebP
3. THE Backend_API SHALL validate file size does not exceed 5MB
4. THE Backend_API SHALL generate unique filename using UUID and preserve file extension
5. THE Backend_API SHALL upload image to cloud storage (AWS S3 or Cloudinary) with public read permissions
6. THE Backend_API SHALL return CDN URL in response: {url: "https://cdn.example.com/images/{uuid}.jpg"}
7. THE Admin_Dashboard SHALL update movie or combo record with returned URL
8. THE Customer_App SHALL use cached_network_image package to load and cache images efficiently
9. THE Customer_App SHALL display placeholder image while loading and error icon if load fails

### Requirement 41: Analytics and Tracking

**User Story:** As a product manager, I want to track user behavior and conversions, so that I can optimize the booking experience

#### Acceptance Criteria

1. THE Customer_App SHALL track events: app_open, login, movie_view, seat_selection_start, booking_complete, payment_success, payment_fail
2. THE Customer_App SHALL use Firebase Analytics or Mixpanel for event tracking
3. THE Customer_App SHALL include event properties: userId, movieId, showtimeId, totalAmount, seatCount
4. THE Customer_App SHALL track screen views with screen name and duration
5. THE Backend_API SHALL log conversion funnel stages: showtime_view, seat_hold, payment_initiate, payment_complete
6. THE Backend_API SHALL calculate conversion rates: seat_hold→payment_initiate, payment_initiate→payment_complete
7. THE Analytics system SHALL anonymize IP addresses and comply with GDPR requirements

### Requirement 42: Testing and Quality Assurance

**User Story:** As a developer, I want comprehensive test coverage, so that the system is reliable and maintainable

#### Acceptance Criteria

1. THE Backend_API SHALL have integration tests covering all API endpoints with request/response validation
2. THE Backend_API SHALL have unit tests for business logic including Refund_Calculator, HMAC_Validator, and Seat_Lock mechanisms
3. THE Backend_API SHALL achieve minimum 80% code coverage measured by coverage tools
4. THE Customer_App SHALL have widget tests for critical flows: login, seat selection, payment, ticket display
5. THE Customer_App SHALL have unit tests for API_Client, WebSocket_Client, and state management
6. THE test suite SHALL include property-based tests for seat reservation race conditions using QuickCheck or Hypothesis
7. THE Backend_API SHALL have load tests simulating 1,000 concurrent seat selection requests to verify race condition handling
8. THE test environment SHALL use Docker containers with isolated test database

### Requirement 43: Deployment and DevOps

**User Story:** As a DevOps engineer, I want automated deployment pipelines, so that releases are consistent and reliable

#### Acceptance Criteria

1. THE Backend_API SHALL use Docker containers for deployment with multi-stage builds
2. THE deployment pipeline SHALL run all tests before deploying to staging or production
3. THE Backend_API SHALL use environment variables for configuration: DATABASE_URL, JWT_SECRET, VNPAY_SECRET, FCM_KEY
4. THE Backend_API SHALL implement health checks responding to /health and /ready endpoints for load balancer
5. THE Backend_API SHALL use database connection pooling with minimum 5 and maximum 20 connections
6. THE Backend_API SHALL implement graceful shutdown handling in-flight requests up to 30 seconds
7. THE system SHALL use blue-green deployment strategy to minimize downtime during releases
8. THE Backend_API SHALL expose metrics endpoint /metrics in Prometheus format for monitoring

### Requirement 44: Monitoring and Observability

**User Story:** As an operations engineer, I want comprehensive monitoring and logging, so that I can diagnose production issues

#### Acceptance Criteria

1. THE Backend_API SHALL use structured logging with fields: timestamp, level, message, userId, requestId, duration
2. THE Backend_API SHALL integrate with logging aggregation service (ELK Stack or CloudWatch Logs)
3. THE Backend_API SHALL emit metrics: request_count, response_time_histogram, error_rate, database_query_duration
4. THE Backend_API SHALL set up alerts for: error_rate > 1%, response_time_p95 > 1s, database_connection_pool_exhausted
5. THE Backend_API SHALL use distributed tracing (OpenTelemetry or Jaeger) to trace requests across services
6. THE monitoring system SHALL track WebSocket connection count and message throughput
7. THE Backend_API SHALL log all payment transactions with full request/response data for audit and debugging

### Requirement 45: Data Privacy and Compliance

**User Story:** As a compliance officer, I want data privacy controls, so that we meet legal requirements


#### Acceptance Criteria

1. THE Backend_API SHALL hash all passwords using bcrypt with minimum cost factor 12
2. THE Backend_API SHALL encrypt sensitive data at rest: payment tokens, VNPay secretKey
3. THE Backend_API SHALL implement data retention policy: booking records retained for 2 years, then archived
4. THE Backend_API SHALL provide user data export endpoint returning all user data in JSON format
5. THE Backend_API SHALL implement account deletion endpoint removing all user PII within 30 days
6. THE Backend_API SHALL anonymize deleted user data in historical records (replace name/email with "Deleted User")
7. THE Backend_API SHALL log all access to sensitive data with userId, action, and timestamp
8. THE Customer_App SHALL display privacy policy acceptance during registration
9. THE Backend_API SHALL comply with PCI-DSS requirements by never storing full payment card details

### Requirement 46: Disaster Recovery and Backup

**User Story:** As a system administrator, I want automated backups and recovery procedures, so that data is protected

#### Acceptance Criteria

1. THE Backend_API SHALL perform automated database backups daily at 2:00 AM with retention period of 30 days
2. THE backup system SHALL encrypt backup files using AES-256 encryption
3. THE backup system SHALL store backups in geographically separate location from primary database
4. THE Backend_API SHALL test backup restoration quarterly to verify backup integrity
5. THE Backend_API SHALL maintain transaction logs enabling point-in-time recovery up to 24 hours in past
6. THE Backend_API SHALL document recovery time objective (RTO) of 4 hours and recovery point objective (RPO) of 1 hour
7. THE system SHALL maintain runbook documenting disaster recovery procedures and escalation contacts

### Requirement 47: API Documentation

**User Story:** As a developer, I want comprehensive API documentation, so that I can integrate with the backend efficiently

#### Acceptance Criteria

1. THE Backend_API SHALL generate OpenAPI 3.0 specification from code annotations
2. THE API documentation SHALL include for each endpoint: path, method, request parameters, request body schema, response schemas, authentication requirements
3. THE Backend_API SHALL host interactive API documentation using Swagger UI at /api-docs
4. THE API documentation SHALL include example requests and responses for each endpoint
5. THE API documentation SHALL document all error codes and their meanings
6. THE Backend_API SHALL version API endpoints using URL prefix: /api/v1/, /api/v2/
7. THE Backend_API SHALL maintain backward compatibility for at least 2 minor versions

### Requirement 48: Feature Flags and A/B Testing

**User Story:** As a product manager, I want to control feature rollout and run experiments, so that I can validate changes safely

#### Acceptance Criteria

1. THE Backend_API SHALL integrate feature flag service (LaunchDarkly or custom solution)
2. THE Backend_API SHALL check feature flags for: new_payment_flow, enhanced_seat_selection, loyalty_rewards
3. WHEN feature is disabled, THE Backend_API SHALL use legacy code path without exposing new functionality
4. THE Customer_App SHALL fetch feature flags on app start and store in memory
5. THE Backend_API SHALL support percentage-based rollouts: enable feature for 10%, 25%, 50%, or 100% of users
6. THE Backend_API SHALL support user segmentation for flags: enable for memberRank platinum, or city Hanoi
7. THE Analytics system SHALL track conversion metrics per feature flag variant for A/B test analysis

### Requirement 49: Graceful Degradation and Resilience

**User Story:** As a user, I want the app to remain functional during partial outages, so that I can complete essential tasks

#### Acceptance Criteria

1. WHEN WebSocket connection fails, THE Customer_App SHALL fall back to polling seat status every 5 seconds
2. WHEN Backend_API is unreachable, THE Customer_App SHALL display cached movie list and booking history
3. WHEN payment gateway is down, THE Backend_API SHALL accept alternative payment method or allow cash payment at counter
4. WHEN push notification service fails, THE Backend_API SHALL log failure and continue booking flow without blocking
5. WHEN database read replica is down, THE Backend_API SHALL route read queries to primary database
6. WHEN CDN is unavailable, THE Customer_App SHALL fall back to direct image URLs from origin server
7. THE Backend_API SHALL implement circuit breaker pattern for external service calls with 5-failure threshold and 30-second timeout

### Requirement 50: API Request and Response Validation

**User Story:** As a security engineer, I want strict input validation and output sanitization, so that the system resists attacks

#### Acceptance Criteria

1. THE Backend_API SHALL validate all request parameters against defined JSON schemas before processing
2. THE Backend_API SHALL reject requests with unexpected fields and return 400 Bad Request
3. THE Backend_API SHALL validate string fields against maximum length constraints to prevent buffer overflow
4. THE Backend_API SHALL validate numeric fields against minimum and maximum bounds
5. THE Backend_API SHALL validate email format using RFC 5322 compliant regex
6. THE Backend_API SHALL validate phone numbers match regional format patterns
7. THE Backend_API SHALL sanitize all HTML content in user reviews before storage and display
8. THE Backend_API SHALL escape special characters in error messages to prevent injection attacks
9. THE Backend_API SHALL validate file uploads against allowed MIME types and magic number signatures
10. THE Backend_API SHALL implement request size limits: 1KB for GET query strings, 10MB for POST bodies

## Non-Functional Requirements

### NFR-1: Performance

- THE Backend_API SHALL respond to 95% of requests within 500ms measured from server receipt to response sent
- THE Backend_API SHALL support 1,000 concurrent active users without performance degradation
- THE Backend_API SHALL handle 100 requests per second sustained load on standard production hardware
- THE WebSocket_Client SHALL deliver seat status updates to all connected clients within 2 seconds of change
- THE Customer_App SHALL complete full booking flow (seat selection to payment confirmation) in under 5 steps

### NFR-2: Scalability

- THE Backend_API SHALL scale horizontally to handle increased load by adding application server instances
- THE Backend_API SHALL use stateless architecture enabling load balancing across multiple instances
- THE Backend_API SHALL implement database read replicas for read-heavy operations like movie search
- THE Backend_API SHALL use caching layer (Redis) for frequently accessed data with appropriate TTLs
- THE Backend_API SHALL partition large tables (Bookings, Payments) by date for query performance

### NFR-3: Reliability and Availability

- THE Backend_API SHALL maintain 99.5% uptime measured monthly (maximum 3.6 hours downtime per month)
- THE Backend_API SHALL implement health checks responding within 100ms for load balancer monitoring
- THE Backend_API SHALL use database connection pooling with automatic reconnection on failure
- THE Backend_API SHALL implement automatic retry with exponential backoff for transient failures
- THE Backend_API SHALL maintain service during deployment using rolling updates with zero downtime

### NFR-4: Security

- THE Backend_API SHALL use HTTPS/TLS 1.3 for all API communications in production
- THE Backend_API SHALL implement JWT token expiration: 15 minutes for access tokens, 7 days for refresh tokens
- THE Backend_API SHALL rotate JWT signing keys quarterly
- THE Backend_API SHALL hash passwords using bcrypt with cost factor 12 minimum
- THE Backend_API SHALL implement rate limiting: 100 req/min unauthenticated, 500 req/min authenticated
- THE Backend_API SHALL log all authentication failures and security events for audit
- THE Backend_API SHALL validate VNPay payment signatures using HMAC-SHA512 to prevent tampering

### NFR-5: Maintainability

- THE Backend_API SHALL use dependency injection for testability and modularity
- THE Backend_API SHALL follow RESTful API design principles with consistent resource naming
- THE Backend_API SHALL maintain code coverage above 80% for unit and integration tests
- THE Backend_API SHALL use automated linting and formatting with pre-commit hooks
- THE Backend_API SHALL use environment-specific configuration files managed through secure secret management
- THE Backend_API SHALL generate OpenAPI documentation automatically from code annotations

### NFR-6: Usability

- THE Customer_App SHALL complete booking flow in maximum 5 steps: select showtime → select seats → select combos → review → pay
- THE Customer_App SHALL provide visual feedback within 100ms for all user interactions
- THE Customer_App SHALL display loading states during API requests to set user expectations
- THE Customer_App SHALL show clear error messages with actionable guidance for recovery
- THE Customer_App SHALL support iOS 12+ and Android 8.0+ operating systems
- THE Customer_App SHALL work on screen sizes from 4.7" to 6.7" smartphones and tablets

### NFR-7: Compatibility

- THE Backend_API SHALL support API versioning with backward compatibility for 2 minor versions
- THE Backend_API SHALL accept requests from Flutter mobile apps (iOS and Android)
- THE Backend_API SHALL support web admin dashboard using modern browsers (Chrome, Firefox, Safari, Edge)
- THE Customer_App SHALL use Flutter 3.0+ with Dart 3.0+ for development
- THE Backend_API SHALL use Node.js 18 LTS or Python 3.10+ or Java 17 LTS for implementation

### NFR-8: Data Integrity

- THE Backend_API SHALL use database transactions for multi-step operations (booking creation, seat hold, payment)
- THE Backend_API SHALL implement foreign key constraints ensuring referential integrity
- THE Backend_API SHALL use optimistic locking to prevent lost updates in concurrent modifications
- THE Backend_API SHALL validate all data against business rules before persistence
- THE Backend_API SHALL maintain audit trail of all data modifications with userId and timestamp

### NFR-9: Localization

- THE Customer_App SHALL support Vietnamese and English languages with runtime switching
- THE Customer_App SHALL format currency using Vietnamese Dong (₫) formatting rules
- THE Customer_App SHALL format dates and times using Vietnamese locale conventions
- THE Backend_API SHALL return localized error messages based on Accept-Language header
- THE Customer_App SHALL use proper UTF-8 encoding for Vietnamese diacritical marks

### NFR-10: Compliance

- THE Backend_API SHALL comply with Vietnam personal data protection regulations
- THE Backend_API SHALL implement GDPR-compliant data export and deletion for European users
- THE Backend_API SHALL enforce age rating compliance with content regulations (T18 verification)
- THE Backend_API SHALL maintain financial transaction logs for regulatory audit requirements
- THE Backend_API SHALL comply with PCI-DSS Level 1 requirements for payment processing

## Technical Constraints

1. **Backend Technology**: Node.js/Express, Python/Django, or Java/Spring Boot
2. **Database**: PostgreSQL 14+ or MySQL 8+ with transactional support
3. **Real-time**: WebSocket or Server-Sent Events for seat synchronization
4. **Payment Gateway**: VNPay API integration (required by Vietnam market)
5. **Push Notifications**: Firebase Cloud Messaging (FCM) and Apple Push Notification Service (APNs)
6. **Flutter Version**: Flutter 3.0+ with Dart 3.0+
7. **Authentication**: JWT with RS256 or HS512 signing algorithm
8. **API Protocol**: REST with JSON payloads, WebSocket for real-time features
9. **Image Storage**: Cloud storage (AWS S3, Cloudinary, or equivalent CDN)
10. **Deployment**: Docker containers with orchestration (Kubernetes or Docker Compose)
