# Critical Notifications Implementation Guide

## Overview

This document explains how to use the critical notification override feature implemented in Task 20.2.

**Requirement Coverage:** Requirement 38.5 - Critical notifications (payment confirmations and booking cancellations) always send regardless of user preferences.

## Critical Notification Categories

The system defines two types of critical notifications that **bypass user preferences**:

1. **Payment Confirmations** - Sent when:
   - Payment succeeds
   - Payment fails
   - Payment requires additional action

2. **Booking Cancellations** - Sent when:
   - User cancels a booking
   - System automatically cancels a booking (timeout, etc.)
   - Admin cancels a booking

## Usage in Notification Services

### Check if Notification Should Be Sent

Use the `NotificationPreferencesService.shouldSendNotification()` method before sending any notification:

```java
@Service
public class PushNotificationService {
    
    @Autowired
    private NotificationPreferencesService preferencesService;
    
    public void sendNotification(String userId, String category, String title, String message) {
        // Check if user should receive this notification
        // Critical notifications will ALWAYS return true
        if (preferencesService.shouldSendNotification(userId, category)) {
            // Send the notification via FCM/APNs
            fcmService.send(userId, title, message);
            logger.info("Sent {} notification to user: {}", category, userId);
        } else {
            logger.info("Skipped {} notification for user {} due to preferences", category, userId);
        }
    }
}
```

### Example: Payment Confirmation (Critical)

```java
// Payment confirmation - ALWAYS sent
String category = "paymentConfirmation";
boolean shouldSend = preferencesService.shouldSendNotification(userId, category);
// shouldSend will ALWAYS be true, regardless of user preferences

pushNotificationService.sendNotification(
    userId,
    "paymentConfirmation",  // Critical category
    "Payment Successful",
    "Your booking has been confirmed. Total: 250,000 VND"
);
```

### Example: Booking Cancellation (Critical)

```java
// Booking cancellation - ALWAYS sent
String category = "bookingCancellation";
boolean shouldSend = preferencesService.shouldSendNotification(userId, category);
// shouldSend will ALWAYS be true, regardless of user preferences

pushNotificationService.sendNotification(
    userId,
    "bookingCancellation",  // Critical category
    "Booking Cancelled",
    "Your booking for 'Avatar 2' has been cancelled. Refund: 125,000 VND"
);
```

### Example: Showtime Reminder (Non-Critical)

```java
// Showtime reminder - Respects user preferences
String category = "showtimeReminders";
boolean shouldSend = preferencesService.shouldSendNotification(userId, category);
// shouldSend depends on user's preference for showtime reminders

if (shouldSend) {
    pushNotificationService.sendNotification(
        userId,
        "showtimeReminders",  // Non-critical category
        "Showtime Reminder",
        "Your movie starts in 2 hours!"
    );
}
```

## Category Names

The system supports multiple string formats for category names:

### Critical Categories
- **Payment Confirmation**: `"paymentConfirmation"`, `"payment_confirmation"`, `"PAYMENTCONFIRMATION"`
- **Booking Cancellation**: `"bookingCancellation"`, `"booking_cancellation"`, `"BOOKINGCANCELLATION"`

### Non-Critical Categories
- **Showtime Reminders**: `"showtimeReminders"`, `"showtime_reminders"`, `"SHOWTIMEREMINDERS"`
- **Promotions**: `"promotions"`, `"PROMOTIONS"`
- **New Movies**: `"newMovies"`, `"new_movies"`, `"NEWMOVIES"`
- **Booking Updates**: `"bookingUpdates"`, `"booking_updates"`, `"BOOKINGUPDATES"`

## Check if Category is Critical

You can explicitly check if a category is critical:

```java
boolean isCritical = preferencesService.isCriticalNotification("paymentConfirmation");
// Returns: true

boolean isCritical = preferencesService.isCriticalNotification("promotions");
// Returns: false
```

## Integration Points

### 1. Payment Service
When payment status changes, send payment confirmation notification:

```java
@Service
public class PaymentService {
    
    @Autowired
    private NotificationPreferencesService preferencesService;
    
    @Autowired
    private PushNotificationService pushService;
    
    public void processPaymentCallback(PaymentCallbackRequest callback) {
        // ... process payment ...
        
        if (payment.isSuccessful()) {
            // Send critical payment confirmation
            pushService.sendNotification(
                booking.getUserId(),
                "paymentConfirmation",
                "Payment Successful",
                buildPaymentSuccessMessage(booking)
            );
        } else {
            // Send critical payment failure notification
            pushService.sendNotification(
                booking.getUserId(),
                "paymentConfirmation",
                "Payment Failed",
                buildPaymentFailureMessage(booking)
            );
        }
    }
}
```

### 2. Booking Service
When booking is cancelled, send cancellation notification:

```java
@Service
public class BookingService {
    
    @Autowired
    private NotificationPreferencesService preferencesService;
    
    @Autowired
    private PushNotificationService pushService;
    
    public void cancelBooking(String bookingId, String userId) {
        Booking booking = bookingRepository.findById(bookingId)
            .orElseThrow(() -> new NotFoundException("Booking not found"));
        
        // ... process cancellation and refund ...
        
        // Send critical booking cancellation notification
        pushService.sendNotification(
            userId,
            "bookingCancellation",
            "Booking Cancelled",
            buildCancellationMessage(booking)
        );
    }
    
    @Scheduled(fixedRate = 60000) // Run every minute
    public void cancelExpiredBookings() {
        List<Booking> expiredBookings = bookingRepository.findExpiredBookings();
        
        for (Booking booking : expiredBookings) {
            booking.setStatus(BookingStatus.CANCELLED);
            bookingRepository.save(booking);
            
            // Send critical automatic cancellation notification
            pushService.sendNotification(
                booking.getUserId(),
                "bookingCancellation",
                "Booking Automatically Cancelled",
                "Your unpaid booking has expired and was automatically cancelled."
            );
        }
    }
}
```

## Testing

Comprehensive unit tests are provided in:
- `NotificationPreferencesServiceImplTest.java` - Service layer tests
- `NotificationCategoryTest.java` - Enum tests

### Key Test Cases

1. **Critical notifications bypass preferences**:
   - Payment confirmations are sent even when all preferences are disabled
   - Booking cancellations are sent even when all preferences are disabled

2. **Non-critical notifications respect preferences**:
   - Showtime reminders respect user preference
   - Promotions respect user preference
   - New movies respect user preference
   - Booking updates respect user preference

3. **String format flexibility**:
   - Supports camelCase, snake_case, UPPERCASE formats
   - Case-insensitive matching

## Implementation Files

1. **`NotificationCategory.java`** (enum)
   - Defines all notification categories
   - Marks critical vs non-critical
   - Provides string parsing utilities

2. **`NotificationPreferencesService.java`** (interface)
   - Added `isCriticalNotification()` method
   - Updated `shouldSendNotification()` documentation

3. **`NotificationPreferencesServiceImpl.java`** (implementation)
   - Checks critical notifications first, bypassing preference check
   - Falls back to checking user preferences for non-critical notifications

## User Experience

From the user's perspective:
- Users can disable showtime reminders, promotions, new movies, and booking updates via the notification preferences UI (Task 20.1)
- Users **cannot** disable payment confirmations or booking cancellations
- The UI does not provide toggles for critical notifications
- Critical notifications are sent transparently to ensure users receive important updates about their transactions

## Logging

The implementation includes logging for transparency:

```
INFO  - Category paymentConfirmation is critical - bypassing preferences for user: user123
INFO  - Sent paymentConfirmation notification to user: user123
```

```
INFO  - Skipped promotions notification for user user456 due to preferences
```

This allows administrators to verify that critical notifications are being sent correctly and debug notification delivery issues.
