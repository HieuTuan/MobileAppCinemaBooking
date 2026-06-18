package com.cineluxe.enums;

import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.*;

/**
 * Unit tests for NotificationCategory enum.
 * 
 * Tests Coverage:
 * - Requirement 38.5: Critical notification identification
 * - String parsing with various formats
 */
class NotificationCategoryTest {
    
    // ===== Tests for Critical Notification Identification =====
    
    @Test
    void paymentConfirmation_IsCritical() {
        assertTrue(NotificationCategory.PAYMENT_CONFIRMATION.isCritical(), 
            "Payment confirmation should be marked as critical");
    }
    
    @Test
    void bookingCancellation_IsCritical() {
        assertTrue(NotificationCategory.BOOKING_CANCELLATION.isCritical(), 
            "Booking cancellation should be marked as critical");
    }
    
    @Test
    void showtimeReminders_IsNotCritical() {
        assertFalse(NotificationCategory.SHOWTIME_REMINDERS.isCritical(), 
            "Showtime reminders should not be critical");
    }
    
    @Test
    void promotions_IsNotCritical() {
        assertFalse(NotificationCategory.PROMOTIONS.isCritical(), 
            "Promotions should not be critical");
    }
    
    @Test
    void newMovies_IsNotCritical() {
        assertFalse(NotificationCategory.NEW_MOVIES.isCritical(), 
            "New movies should not be critical");
    }
    
    @Test
    void bookingUpdates_IsNotCritical() {
        assertFalse(NotificationCategory.BOOKING_UPDATES.isCritical(), 
            "Booking updates should not be critical");
    }
    
    // ===== Tests for Static isCriticalNotification Method =====
    
    @Test
    void isCriticalNotification_PaymentConfirmation_ReturnsTrue() {
        assertTrue(NotificationCategory.isCriticalNotification("paymentConfirmation"));
    }
    
    @Test
    void isCriticalNotification_BookingCancellation_ReturnsTrue() {
        assertTrue(NotificationCategory.isCriticalNotification("bookingCancellation"));
    }
    
    @Test
    void isCriticalNotification_ShowtimeReminders_ReturnsFalse() {
        assertFalse(NotificationCategory.isCriticalNotification("showtimeReminders"));
    }
    
    @Test
    void isCriticalNotification_Promotions_ReturnsFalse() {
        assertFalse(NotificationCategory.isCriticalNotification("promotions"));
    }
    
    @Test
    void isCriticalNotification_UnknownCategory_ReturnsFalse() {
        assertFalse(NotificationCategory.isCriticalNotification("unknownCategory"));
    }
    
    @Test
    void isCriticalNotification_NullCategory_ReturnsFalse() {
        assertFalse(NotificationCategory.isCriticalNotification(null));
    }
    
    // ===== Tests for String Parsing (fromString) =====
    
    @Test
    void fromString_PaymentConfirmation_CamelCase() {
        assertEquals(NotificationCategory.PAYMENT_CONFIRMATION, 
            NotificationCategory.fromString("paymentConfirmation"));
    }
    
    @Test
    void fromString_PaymentConfirmation_SnakeCase() {
        assertEquals(NotificationCategory.PAYMENT_CONFIRMATION, 
            NotificationCategory.fromString("payment_confirmation"));
    }
    
    @Test
    void fromString_PaymentConfirmation_Uppercase() {
        assertEquals(NotificationCategory.PAYMENT_CONFIRMATION, 
            NotificationCategory.fromString("PAYMENTCONFIRMATION"));
    }
    
    @Test
    void fromString_PaymentConfirmation_MixedCase() {
        assertEquals(NotificationCategory.PAYMENT_CONFIRMATION, 
            NotificationCategory.fromString("Payment_Confirmation"));
    }
    
    @Test
    void fromString_BookingCancellation_VariousFormats() {
        assertEquals(NotificationCategory.BOOKING_CANCELLATION, 
            NotificationCategory.fromString("bookingCancellation"));
        assertEquals(NotificationCategory.BOOKING_CANCELLATION, 
            NotificationCategory.fromString("booking_cancellation"));
        assertEquals(NotificationCategory.BOOKING_CANCELLATION, 
            NotificationCategory.fromString("BOOKINGCANCELLATION"));
    }
    
    @Test
    void fromString_ShowtimeReminders_VariousFormats() {
        assertEquals(NotificationCategory.SHOWTIME_REMINDERS, 
            NotificationCategory.fromString("showtimeReminders"));
        assertEquals(NotificationCategory.SHOWTIME_REMINDERS, 
            NotificationCategory.fromString("showtime_reminders"));
        assertEquals(NotificationCategory.SHOWTIME_REMINDERS, 
            NotificationCategory.fromString("SHOWTIMEREMINDERS"));
    }
    
    @Test
    void fromString_Promotions_VariousFormats() {
        assertEquals(NotificationCategory.PROMOTIONS, 
            NotificationCategory.fromString("promotions"));
        assertEquals(NotificationCategory.PROMOTIONS, 
            NotificationCategory.fromString("PROMOTIONS"));
    }
    
    @Test
    void fromString_NewMovies_VariousFormats() {
        assertEquals(NotificationCategory.NEW_MOVIES, 
            NotificationCategory.fromString("newMovies"));
        assertEquals(NotificationCategory.NEW_MOVIES, 
            NotificationCategory.fromString("new_movies"));
    }
    
    @Test
    void fromString_BookingUpdates_VariousFormats() {
        assertEquals(NotificationCategory.BOOKING_UPDATES, 
            NotificationCategory.fromString("bookingUpdates"));
        assertEquals(NotificationCategory.BOOKING_UPDATES, 
            NotificationCategory.fromString("booking_updates"));
    }
    
    @Test
    void fromString_UnknownCategory_ReturnsNull() {
        assertNull(NotificationCategory.fromString("unknownCategory"));
    }
    
    @Test
    void fromString_NullInput_ReturnsNull() {
        assertNull(NotificationCategory.fromString(null));
    }
    
    @Test
    void fromString_EmptyString_ReturnsNull() {
        assertNull(NotificationCategory.fromString(""));
    }
    
    // ===== Tests for getCategoryName =====
    
    @Test
    void getCategoryName_ReturnsCorrectNames() {
        assertEquals("showtimeReminders", NotificationCategory.SHOWTIME_REMINDERS.getCategoryName());
        assertEquals("promotions", NotificationCategory.PROMOTIONS.getCategoryName());
        assertEquals("newMovies", NotificationCategory.NEW_MOVIES.getCategoryName());
        assertEquals("bookingUpdates", NotificationCategory.BOOKING_UPDATES.getCategoryName());
        assertEquals("paymentConfirmation", NotificationCategory.PAYMENT_CONFIRMATION.getCategoryName());
        assertEquals("bookingCancellation", NotificationCategory.BOOKING_CANCELLATION.getCategoryName());
    }
}
