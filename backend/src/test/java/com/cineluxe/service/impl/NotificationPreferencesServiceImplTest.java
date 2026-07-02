package com.cineluxe.service.impl;

import com.cineluxe.dto.request.UpdateNotificationPreferencesRequest;
import com.cineluxe.dto.response.NotificationPreferencesResponse;
import com.cineluxe.entity.NotificationPreferences;
import com.cineluxe.repository.NotificationPreferencesRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

/**
 * Unit tests for NotificationPreferencesServiceImpl.
 * 
 * Tests Coverage:
 * - Requirement 38.4: Respect user preferences for non-critical notifications
 * - Requirement 38.5: Critical notifications always sent regardless of preferences
 */
@ExtendWith(MockitoExtension.class)
class NotificationPreferencesServiceImplTest {
    
    @Mock
    private NotificationPreferencesRepository preferencesRepository;
    
    @InjectMocks
    private NotificationPreferencesServiceImpl service;
    
    private String testUserId;
    private NotificationPreferences testPreferences;
    
    @BeforeEach
    void setUp() {
        testUserId = "user123";
        testPreferences = new NotificationPreferences(testUserId);
        // Default all to true
        testPreferences.setShowtimeReminders(true);
        testPreferences.setPromotions(true);
        testPreferences.setNewMovies(true);
        testPreferences.setBookingUpdates(true);
    }
    
    // ===== Tests for Critical Notification Override (Requirement 38.5) =====
    
    @Test
    void shouldSendNotification_PaymentConfirmation_AlwaysReturnsTrue_EvenWhenAllPreferencesDisabled() {
        // Arrange: User has disabled ALL notification categories
        testPreferences.setShowtimeReminders(false);
        testPreferences.setPromotions(false);
        testPreferences.setNewMovies(false);
        testPreferences.setBookingUpdates(false);
        
        
        // Act: Check if payment confirmation should be sent
        boolean shouldSend = service.shouldSendNotification(testUserId, "paymentConfirmation");
        
        // Assert: Payment confirmation is CRITICAL - must return true
        assertTrue(shouldSend, "Payment confirmations must be sent regardless of user preferences");
        
        // Verify repository was not even called since critical notifications bypass preferences
        verify(preferencesRepository, never()).findByUserId(any());
    }
    
    @Test
    void shouldSendNotification_BookingCancellation_AlwaysReturnsTrue_EvenWhenAllPreferencesDisabled() {
        // Arrange: User has disabled ALL notification categories
        testPreferences.setShowtimeReminders(false);
        testPreferences.setPromotions(false);
        testPreferences.setNewMovies(false);
        testPreferences.setBookingUpdates(false);
        
        
        // Act: Check if booking cancellation should be sent
        boolean shouldSend = service.shouldSendNotification(testUserId, "bookingCancellation");
        
        // Assert: Booking cancellation is CRITICAL - must return true
        assertTrue(shouldSend, "Booking cancellations must be sent regardless of user preferences");
        
        // Verify repository was not called
        verify(preferencesRepository, never()).findByUserId(any());
    }
    
    @Test
    void shouldSendNotification_PaymentConfirmation_WorksWithVariousFormats() {
        // Test various string formats for payment confirmation
        String[] formats = {
            "paymentConfirmation",
            "payment_confirmation",
            "PAYMENTCONFIRMATION",
            "Payment_Confirmation"
        };
        
        for (String format : formats) {
            boolean shouldSend = service.shouldSendNotification(testUserId, format);
            assertTrue(shouldSend, "Payment confirmation with format '" + format + "' should always be sent");
        }
    }
    
    @Test
    void shouldSendNotification_BookingCancellation_WorksWithVariousFormats() {
        // Test various string formats for booking cancellation
        String[] formats = {
            "bookingCancellation",
            "booking_cancellation",
            "BOOKINGCANCELLATION",
            "Booking_Cancellation"
        };
        
        for (String format : formats) {
            boolean shouldSend = service.shouldSendNotification(testUserId, format);
            assertTrue(shouldSend, "Booking cancellation with format '" + format + "' should always be sent");
        }
    }
    
    // ===== Tests for Non-Critical Notifications (Requirement 38.4) =====
    
    @Test
    void shouldSendNotification_ShowtimeReminders_RespectsUserPreference_WhenDisabled() {
        // Arrange: User has disabled showtime reminders
        testPreferences.setShowtimeReminders(false);
        when(preferencesRepository.findByUserId(testUserId)).thenReturn(Optional.of(testPreferences));
        
        // Act
        boolean shouldSend = service.shouldSendNotification(testUserId, "showtimeReminders");
        
        // Assert: Should respect user preference and NOT send
        assertFalse(shouldSend, "Showtime reminders should respect user preference when disabled");
        verify(preferencesRepository, times(1)).findByUserId(testUserId);
    }
    
    @Test
    void shouldSendNotification_ShowtimeReminders_RespectsUserPreference_WhenEnabled() {
        // Arrange: User has enabled showtime reminders
        testPreferences.setShowtimeReminders(true);
        when(preferencesRepository.findByUserId(testUserId)).thenReturn(Optional.of(testPreferences));
        
        // Act
        boolean shouldSend = service.shouldSendNotification(testUserId, "showtimeReminders");
        
        // Assert: Should respect user preference and send
        assertTrue(shouldSend, "Showtime reminders should be sent when user preference is enabled");
        verify(preferencesRepository, times(1)).findByUserId(testUserId);
    }
    
    @Test
    void shouldSendNotification_Promotions_RespectsUserPreference_WhenDisabled() {
        // Arrange
        testPreferences.setPromotions(false);
        when(preferencesRepository.findByUserId(testUserId)).thenReturn(Optional.of(testPreferences));
        
        // Act
        boolean shouldSend = service.shouldSendNotification(testUserId, "promotions");
        
        // Assert
        assertFalse(shouldSend, "Promotions should respect user preference when disabled");
    }
    
    @Test
    void shouldSendNotification_NewMovies_RespectsUserPreference_WhenDisabled() {
        // Arrange
        testPreferences.setNewMovies(false);
        when(preferencesRepository.findByUserId(testUserId)).thenReturn(Optional.of(testPreferences));
        
        // Act
        boolean shouldSend = service.shouldSendNotification(testUserId, "newMovies");
        
        // Assert
        assertFalse(shouldSend, "New movies notifications should respect user preference when disabled");
    }
    
    @Test
    void shouldSendNotification_BookingUpdates_RespectsUserPreference_WhenDisabled() {
        // Arrange
        testPreferences.setBookingUpdates(false);
        when(preferencesRepository.findByUserId(testUserId)).thenReturn(Optional.of(testPreferences));
        
        // Act
        boolean shouldSend = service.shouldSendNotification(testUserId, "bookingUpdates");
        
        // Assert
        assertFalse(shouldSend, "Booking updates should respect user preference when disabled");
    }
    
    @Test
    void shouldSendNotification_NoPreferencesExist_DefaultsToTrue() {
        // Arrange: No preferences found for user
        when(preferencesRepository.findByUserId(testUserId)).thenReturn(Optional.empty());
        
        // Act
        boolean shouldSend = service.shouldSendNotification(testUserId, "showtimeReminders");
        
        // Assert: Default to sending when no preferences exist
        assertTrue(shouldSend, "Should default to sending when no preferences exist");
    }
    
    // ===== Test for isCriticalNotification method =====
    
    @Test
    void isCriticalNotification_PaymentConfirmation_ReturnsTrue() {
        assertTrue(service.isCriticalNotification("paymentConfirmation"));
    }
    
    @Test
    void isCriticalNotification_BookingCancellation_ReturnsTrue() {
        assertTrue(service.isCriticalNotification("bookingCancellation"));
    }
    
    @Test
    void isCriticalNotification_ShowtimeReminders_ReturnsFalse() {
        assertFalse(service.isCriticalNotification("showtimeReminders"));
    }
    
    @Test
    void isCriticalNotification_Promotions_ReturnsFalse() {
        assertFalse(service.isCriticalNotification("promotions"));
    }
    
    @Test
    void isCriticalNotification_NewMovies_ReturnsFalse() {
        assertFalse(service.isCriticalNotification("newMovies"));
    }
    
    @Test
    void isCriticalNotification_BookingUpdates_ReturnsFalse() {
        assertFalse(service.isCriticalNotification("bookingUpdates"));
    }
    
    @Test
    void isCriticalNotification_UnknownCategory_ReturnsFalse() {
        assertFalse(service.isCriticalNotification("unknownCategory"));
    }
    
    @Test
    void isCriticalNotification_NullCategory_ReturnsFalse() {
        assertFalse(service.isCriticalNotification(null));
    }
    
    // ===== Tests for getPreferences =====
    
    @Test
    void getPreferences_ExistingPreferences_ReturnsPreferences() {
        // Arrange
        when(preferencesRepository.findByUserId(testUserId)).thenReturn(Optional.of(testPreferences));
        
        // Act
        NotificationPreferencesResponse response = service.getPreferences(testUserId);
        
        // Assert
        assertNotNull(response);
        verify(preferencesRepository, times(1)).findByUserId(testUserId);
    }
    
    @Test
    void getPreferences_NoExistingPreferences_CreatesDefault() {
        // Arrange
        when(preferencesRepository.findByUserId(testUserId)).thenReturn(Optional.empty());
        when(preferencesRepository.save(any(NotificationPreferences.class))).thenReturn(testPreferences);
        
        // Act
        NotificationPreferencesResponse response = service.getPreferences(testUserId);
        
        // Assert
        assertNotNull(response);
        verify(preferencesRepository, times(1)).findByUserId(testUserId);
        verify(preferencesRepository, times(1)).save(any(NotificationPreferences.class));
    }
    
    // ===== Tests for updatePreferences =====
    
    @Test
    void updatePreferences_ExistingPreferences_UpdatesValues() {
        // Arrange
        UpdateNotificationPreferencesRequest request = new UpdateNotificationPreferencesRequest();
        request.setShowtimeReminders(false);
        request.setPromotions(false);
        request.setNewMovies(true);
        request.setBookingUpdates(true);
        
        when(preferencesRepository.findByUserId(testUserId)).thenReturn(Optional.of(testPreferences));
        when(preferencesRepository.save(any(NotificationPreferences.class))).thenReturn(testPreferences);
        
        // Act
        service.updatePreferences(testUserId, request);
        
        // Assert
        verify(preferencesRepository, times(1)).findByUserId(testUserId);
        verify(preferencesRepository, times(1)).save(testPreferences);
        assertFalse(testPreferences.getShowtimeReminders());
        assertFalse(testPreferences.getPromotions());
        assertTrue(testPreferences.getNewMovies());
        assertTrue(testPreferences.getBookingUpdates());
    }
    
    @Test
    void updatePreferences_NoExistingPreferences_CreatesNew() {
        // Arrange
        UpdateNotificationPreferencesRequest request = new UpdateNotificationPreferencesRequest();
        request.setShowtimeReminders(true);
        request.setPromotions(false);
        request.setNewMovies(true);
        request.setBookingUpdates(false);
        
        when(preferencesRepository.findByUserId(testUserId)).thenReturn(Optional.empty());
        when(preferencesRepository.save(any(NotificationPreferences.class))).thenReturn(testPreferences);
        
        // Act
        service.updatePreferences(testUserId, request);
        
        // Assert
        verify(preferencesRepository, times(1)).findByUserId(testUserId);
        verify(preferencesRepository, times(1)).save(any(NotificationPreferences.class));
    }
}
