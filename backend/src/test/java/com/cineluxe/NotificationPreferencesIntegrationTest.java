package com.cineluxe;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.patch;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

/**
 * Integration test for notification preferences endpoints.
 * 
 * Requirements Coverage:
 * - Requirement 38.1: GET /api/users/{userId}/notification-preferences
 * - Requirement 38.2: Return preferences with categories
 * - Requirement 38.3: PATCH /api/users/{userId}/notification-preferences
 * - Requirement 38.6: Display toggle switches for each category
 */
@SpringBootTest
@AutoConfigureMockMvc
class NotificationPreferencesIntegrationTest {
    
    @Autowired
    private MockMvc mockMvc;
    
    /**
     * Test getting notification preferences for a user.
     * 
     * Requirements 38.1, 38.2: GET endpoint returns all categories
     */
    @Test
    void getPreferences_ReturnsDefaultPreferencesForNewUser() throws Exception {
        String userId = "test-user-" + System.currentTimeMillis();
        
        mockMvc.perform(get("/api/users/{userId}/notification-preferences", userId))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.showtimeReminders").value(true))
            .andExpect(jsonPath("$.promotions").value(true))
            .andExpect(jsonPath("$.newMovies").value(true))
            .andExpect(jsonPath("$.bookingUpdates").value(true));
    }
    
    /**
     * Test updating notification preferences.
     * 
     * Requirements 38.3: PATCH endpoint updates preferences
     */
    @Test
    void updatePreferences_UpdatesAllCategories() throws Exception {
        String userId = "test-user-update-" + System.currentTimeMillis();
        
        String updateRequest = """
            {
                "showtimeReminders": false,
                "promotions": true,
                "newMovies": false,
                "bookingUpdates": true
            }
            """;
        
        // Update preferences
        mockMvc.perform(patch("/api/users/{userId}/notification-preferences", userId)
                .contentType(MediaType.APPLICATION_JSON)
                .content(updateRequest))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.message").value("Notification preferences updated successfully"));
        
        // Verify preferences were updated
        mockMvc.perform(get("/api/users/{userId}/notification-preferences", userId))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.showtimeReminders").value(false))
            .andExpect(jsonPath("$.promotions").value(true))
            .andExpect(jsonPath("$.newMovies").value(false))
            .andExpect(jsonPath("$.bookingUpdates").value(true));
    }
    
    /**
     * Test validation - all fields are required.
     * 
     * Requirements 38.3: Validate request data
     */
    @Test
    void updatePreferences_RejectsInvalidRequest() throws Exception {
        String userId = "test-user-invalid-" + System.currentTimeMillis();
        
        // Missing required field
        String invalidRequest = """
            {
                "showtimeReminders": false,
                "promotions": true,
                "newMovies": false
            }
            """;
        
        mockMvc.perform(patch("/api/users/{userId}/notification-preferences", userId)
                .contentType(MediaType.APPLICATION_JSON)
                .content(invalidRequest))
            .andExpect(status().isBadRequest());
    }
    
    /**
     * Test disabling all notifications.
     * 
     * Requirements 38.3: User can disable all notification types
     */
    @Test
    void updatePreferences_CanDisableAllNotifications() throws Exception {
        String userId = "test-user-disable-all-" + System.currentTimeMillis();
        
        String updateRequest = """
            {
                "showtimeReminders": false,
                "promotions": false,
                "newMovies": false,
                "bookingUpdates": false
            }
            """;
        
        // Update preferences to disable all
        mockMvc.perform(patch("/api/users/{userId}/notification-preferences", userId)
                .contentType(MediaType.APPLICATION_JSON)
                .content(updateRequest))
            .andExpect(status().isOk());
        
        // Verify all preferences are disabled
        mockMvc.perform(get("/api/users/{userId}/notification-preferences", userId))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.showtimeReminders").value(false))
            .andExpect(jsonPath("$.promotions").value(false))
            .andExpect(jsonPath("$.newMovies").value(false))
            .andExpect(jsonPath("$.bookingUpdates").value(false));
    }
    
    /**
     * Test preferences persistence across multiple requests.
     * 
     * Requirements 38.1, 38.2: Preferences should persist
     */
    @Test
    void getPreferences_ReturnsSamePreferencesAfterUpdate() throws Exception {
        String userId = "test-user-persist-" + System.currentTimeMillis();
        
        String updateRequest = """
            {
                "showtimeReminders": true,
                "promotions": false,
                "newMovies": true,
                "bookingUpdates": false
            }
            """;
        
        // Update preferences
        mockMvc.perform(patch("/api/users/{userId}/notification-preferences", userId)
                .contentType(MediaType.APPLICATION_JSON)
                .content(updateRequest))
            .andExpect(status().isOk());
        
        // First GET request
        mockMvc.perform(get("/api/users/{userId}/notification-preferences", userId))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.showtimeReminders").value(true))
            .andExpect(jsonPath("$.promotions").value(false))
            .andExpect(jsonPath("$.newMovies").value(true))
            .andExpect(jsonPath("$.bookingUpdates").value(false));
        
        // Second GET request - should return same values
        mockMvc.perform(get("/api/users/{userId}/notification-preferences", userId))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.showtimeReminders").value(true))
            .andExpect(jsonPath("$.promotions").value(false))
            .andExpect(jsonPath("$.newMovies").value(true))
            .andExpect(jsonPath("$.bookingUpdates").value(false));
    }
}
