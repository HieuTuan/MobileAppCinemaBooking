package com.cineluxe.dto.response;

import com.cineluxe.entity.NotificationPreferences;

/**
 * DTO for notification preferences response.
 * 
 * Requirements Coverage:
 * - Requirement 38.2: Returns preferences with categories (showtimeReminders, promotions, newMovies, bookingUpdates)
 */
public class NotificationPreferencesResponse {
    
    private Boolean showtimeReminders;
    private Boolean promotions;
    private Boolean newMovies;
    private Boolean bookingUpdates;
    
    public NotificationPreferencesResponse() {
    }
    
    public NotificationPreferencesResponse(
            Boolean showtimeReminders,
            Boolean promotions,
            Boolean newMovies,
            Boolean bookingUpdates) {
        this.showtimeReminders = showtimeReminders;
        this.promotions = promotions;
        this.newMovies = newMovies;
        this.bookingUpdates = bookingUpdates;
    }
    
    /**
     * Create DTO from entity
     */
    public static NotificationPreferencesResponse fromEntity(NotificationPreferences entity) {
        return new NotificationPreferencesResponse(
            entity.getShowtimeReminders(),
            entity.getPromotions(),
            entity.getNewMovies(),
            entity.getBookingUpdates()
        );
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
