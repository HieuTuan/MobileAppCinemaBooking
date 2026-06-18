package com.cineluxe.service.impl;

import com.cineluxe.dto.request.UpdateNotificationPreferencesRequest;
import com.cineluxe.dto.response.NotificationPreferencesResponse;
import com.cineluxe.entity.NotificationPreferences;
import com.cineluxe.enums.NotificationCategory;
import com.cineluxe.repository.NotificationPreferencesRepository;
import com.cineluxe.service.NotificationPreferencesService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Implementation of NotificationPreferencesService.
 * 
 * Requirements Coverage:
 * - Requirement 38.1: Get notification preferences for a user
 * - Requirement 38.2: Return preferences with all categories
 * - Requirement 38.3: Update notification preferences
 * - Requirement 38.4: Check if notifications should be sent
 * - Requirement 38.5: Critical notifications always sent regardless of preferences
 */
@Service
@Transactional
public class NotificationPreferencesServiceImpl implements NotificationPreferencesService {
    
    private static final Logger logger = LoggerFactory.getLogger(NotificationPreferencesServiceImpl.class);
    
    @Autowired
    private NotificationPreferencesRepository preferencesRepository;
    
    /**
     * Get notification preferences for a user.
     * Creates default preferences if none exist.
     * 
     * Requirement 38.1: GET /api/users/{userId}/notification-preferences
     * Requirement 38.2: Return preferences with categories
     */
    @Override
    @Transactional(readOnly = true)
    public NotificationPreferencesResponse getPreferences(String userId) {
        logger.info("Getting notification preferences for user: {}", userId);
        
        NotificationPreferences preferences = preferencesRepository.findByUserId(userId)
            .orElseGet(() -> {
                logger.info("Creating default notification preferences for new user: {}", userId);
                NotificationPreferences newPreferences = new NotificationPreferences(userId);
                return preferencesRepository.save(newPreferences);
            });
        
        return NotificationPreferencesResponse.fromEntity(preferences);
    }
    
    /**
     * Update notification preferences for a user.
     * Creates preferences if none exist.
     * 
     * Requirement 38.3: PATCH /api/users/{userId}/notification-preferences
     */
    @Override
    public void updatePreferences(String userId, UpdateNotificationPreferencesRequest request) {
        logger.info("Updating notification preferences for user: {}", userId);
        
        NotificationPreferences preferences = preferencesRepository.findByUserId(userId)
            .orElseGet(() -> {
                logger.info("Creating new notification preferences for user: {}", userId);
                return new NotificationPreferences(userId);
            });
        
        // Update preference values
        preferences.setShowtimeReminders(request.getShowtimeReminders());
        preferences.setPromotions(request.getPromotions());
        preferences.setNewMovies(request.getNewMovies());
        preferences.setBookingUpdates(request.getBookingUpdates());
        
        preferencesRepository.save(preferences);
        
        logger.info("Successfully updated notification preferences for user: {}", userId);
    }
    
    /**
     * Check if user should receive a specific type of notification.
     * Critical notifications (payment confirmations, booking cancellations) always return true.
     * 
     * Requirement 38.4: Respect preferences when sending notifications
     * Requirement 38.5: Critical notifications always sent regardless of preferences
     */
    @Override
    @Transactional(readOnly = true)
    public boolean shouldSendNotification(String userId, String category) {
        // Check if this is a critical notification first
        if (isCriticalNotification(category)) {
            logger.info("Category {} is critical - bypassing preferences for user: {}", category, userId);
            return true;
        }
        
        NotificationPreferences preferences = preferencesRepository.findByUserId(userId)
            .orElse(null);
        
        // If no preferences found, default to sending (opt-in by default)
        if (preferences == null) {
            return true;
        }
        
        // Check the specific category
        switch (category.toLowerCase()) {
            case "showtimereminders":
            case "showtime_reminders":
                return preferences.getShowtimeReminders();
            case "promotions":
                return preferences.getPromotions();
            case "newmovies":
            case "new_movies":
                return preferences.getNewMovies();
            case "bookingupdates":
            case "booking_updates":
                return preferences.getBookingUpdates();
            default:
                logger.warn("Unknown notification category: {}", category);
                return false;
        }
    }
    
    /**
     * Check if a notification category is critical.
     * Critical notifications bypass user preferences and are always sent.
     * 
     * Requirement 38.5: Payment confirmations and booking cancellations are critical
     */
    @Override
    public boolean isCriticalNotification(String category) {
        return NotificationCategory.isCriticalNotification(category);
    }
}
