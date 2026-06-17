package com.cineluxe.dto.request;

import jakarta.validation.constraints.NotNull;

/**
 * DTO for updating notification preferences.
 * 
 * Requirements Coverage:
 * - Requirement 38.3: PATCH /api/users/{userId}/notification-preferences with updated category
 */
public class UpdateNotificationPreferencesRequest {
    
    @NotNull(message = "showtimeReminders is required")
    private Boolean showtimeReminders;
    
    @NotNull(message = "promotions is required")
    private Boolean promotions;
    
    @NotNull(message = "newMovies is required")
    private Boolean newMovies;
    
    @NotNull(message = "bookingUpdates is required")
    private Boolean bookingUpdates;
    
    public UpdateNotificationPreferencesRequest() {
    }
    
    public UpdateNotificationPreferencesRequest(
            Boolean showtimeReminders,
            Boolean promotions,
            Boolean newMovies,
            Boolean bookingUpdates) {
        this.showtimeReminders = showtimeReminders;
        this.promotions = promotions;
        this.newMovies = newMovies;
        this.bookingUpdates = bookingUpdates;
    }
    
    // Getters and Setters
    
    public Boolean getShowtimeReminders() {
        return showtimeReminders;
    }
    
    public void setShowtimeReminders(Boolean showtimeReminders) {
        this.showtimeReminders = showtimeReminders;
    }
    
    public Boolean getPromotions() {
        return promotions;
    }
    
    public void setPromotions(Boolean promotions) {
        this.promotions = promotions;
    }
    
    public Boolean getNewMovies() {
        return newMovies;
    }
    
    public void setNewMovies(Boolean newMovies) {
        this.newMovies = newMovies;
    }
    
    public Boolean getBookingUpdates() {
        return bookingUpdates;
    }
    
    public void setBookingUpdates(Boolean bookingUpdates) {
        this.bookingUpdates = bookingUpdates;
    }
}
