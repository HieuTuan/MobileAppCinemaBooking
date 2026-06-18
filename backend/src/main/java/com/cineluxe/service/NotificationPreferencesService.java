package com.cineluxe.service;

import com.cineluxe.dto.request.UpdateNotificationPreferencesRequest;
import com.cineluxe.dto.response.NotificationPreferencesResponse;

/**
 * Service interface for managing user notification preferences.
 * 
 * Requirements Coverage:
 * - Requirement 38.1: Get notification preferences for a user
 * - Requirement 38.3: Update notification preferences for a user
 * - Requirement 38.5: Critical notifications always sent regardless of preferences
 */
public interface NotificationPreferencesService {
    
    /**
     * Get notification preferences for a user.
     * Creates default preferences if none exist.
     * 
     * Requirement 38.1: GET /api/users/{userId}/notification-preferences
     * 
     * @param userId User ID
     * @return Notification preferences
     */
    NotificationPreferencesResponse getPreferences(String userId);
    
    /**
     * Update notification preferences for a user.
     * Creates preferences if none exist.
     * 
     * Requirement 38.3: PATCH /api/users/{userId}/notification-preferences
     * 
     * @param userId User ID
     * @param request Update request with new preference values
     */
    void updatePreferences(String userId, UpdateNotificationPreferencesRequest request);
    
    /**
     * Check if user should receive a specific type of notification.
     * Critical notifications (payment confirmations, booking cancellations) always return true.
     * 
     * Requirement 38.4: Respect preferences when sending notifications
     * Requirement 38.5: Critical notifications always sent regardless of preferences
     * 
     * @param userId User ID
     * @param category Notification category (showtimeReminders, promotions, newMovies, bookingUpdates, paymentConfirmation, bookingCancellation)
     * @return true if user has enabled this notification category OR if it's a critical notification
     */
    boolean shouldSendNotification(String userId, String category);
    
    /**
     * Check if a notification category is critical.
     * Critical notifications bypass user preferences and are always sent.
     * 
     * Requirement 38.5: Payment confirmations and booking cancellations are critical
     * 
     * @param category Notification category name
     * @return true if the category is critical (payment confirmation or booking cancellation)
     */
    boolean isCriticalNotification(String category);
}
