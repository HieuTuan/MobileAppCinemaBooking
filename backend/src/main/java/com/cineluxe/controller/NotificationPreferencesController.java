package com.cineluxe.controller;

import com.cineluxe.dto.request.UpdateNotificationPreferencesRequest;
import com.cineluxe.dto.response.ApiResponse;
import com.cineluxe.dto.response.NotificationPreferencesResponse;
import com.cineluxe.service.NotificationPreferencesService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

/**
 * REST Controller for notification preferences endpoints.
 * 
 * Requirements Coverage:
 * - Requirement 38.1: GET /api/users/{userId}/notification-preferences
 * - Requirement 38.3: PATCH /api/users/{userId}/notification-preferences
 */
@RestController
@RequestMapping("/api/users/{userId}/notification-preferences")
@Tag(name = "Notification Preferences", description = "User notification preference management")
public class NotificationPreferencesController {
    
    private static final Logger logger = LoggerFactory.getLogger(NotificationPreferencesController.class);
    
    @Autowired
    private NotificationPreferencesService preferencesService;
    
    /**
     * Get notification preferences for a user.
     * 
     * Requirement 38.1: WHEN customer opens notification settings, 
     * THE API_Client SHALL GET /api/users/{userId}/notification-preferences
     * 
     * Requirement 38.2: THE Backend_API SHALL return preferences with categories: 
     * showtimeReminders, promotions, newMovies, bookingUpdates (each boolean)
     * 
     * @param userId User ID from path variable
     * @return Notification preferences with all categories
     */
    @GetMapping
    @Operation(summary = "Get notification preferences", 
               description = "Retrieve user's notification preferences for all categories")
    public ResponseEntity<NotificationPreferencesResponse> getPreferences(
            @PathVariable String userId) {
        logger.info("GET /api/users/{}/notification-preferences", userId);
        
        NotificationPreferencesResponse preferences = preferencesService.getPreferences(userId);
        
        return ResponseEntity.ok(preferences);
    }
    
    /**
     * Update notification preferences for a user.
     * 
     * Requirement 38.3: WHEN customer toggles preference, 
     * THE API_Client SHALL PATCH /api/users/{userId}/notification-preferences 
     * with updated category
     * 
     * @param userId User ID from path variable
     * @param request Update request with new preference values
     * @return Success response
     */
    @PatchMapping
    @Operation(summary = "Update notification preferences",
               description = "Update user's notification preferences for one or more categories")
    public ResponseEntity<ApiResponse<Void>> updatePreferences(
            @PathVariable String userId,
            @Valid @RequestBody UpdateNotificationPreferencesRequest request) {
        logger.info("PATCH /api/users/{}/notification-preferences", userId);
        logger.debug("Request: {}", request);
        
        preferencesService.updatePreferences(userId, request);
        
        return ApiResponse.success(null, "Notification preferences updated successfully");
    }
}
