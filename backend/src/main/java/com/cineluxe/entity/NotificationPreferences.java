package com.cineluxe.entity;

import jakarta.persistence.*;
import java.time.LocalDateTime;

/**
 * JPA Entity representing user notification preferences.
 * 
 * Requirements Coverage:
 * - Requirement 38.2: Preferences with categories (showtimeReminders, promotions, newMovies, bookingUpdates)
 * - Each category is a boolean flag indicating whether the user wants to receive that type of notification
 * 
 * One-to-one relationship with User entity (userId is unique).
 */
@Entity
@Table(name = "notification_preferences")
public class NotificationPreferences {
    
    /**
     * User ID - primary key ensures one preference record per user
     */
    @Id
    @Column(name = "user_id", nullable = false)
    private String userId;
    
    /**
     * Enable showtime reminder notifications (2 hours before showtime)
     */
    @Column(name = "showtime_reminders", nullable = false)
    private Boolean showtimeReminders = true;
    
    /**
     * Enable promotional and marketing notifications
     */
    @Column(name = "promotions", nullable = false)
    private Boolean promotions = true;
    
    /**
     * Enable new movie release notifications
     */
    @Column(name = "new_movies", nullable = false)
    private Boolean newMovies = true;
    
    /**
     * Enable booking update notifications (confirmations, changes)
     */
    @Column(name = "booking_updates", nullable = false)
    private Boolean bookingUpdates = true;
    
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;
    
    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt;
    
    @PrePersist
    protected void onCreate() {
        createdAt = LocalDateTime.now();
        updatedAt = LocalDateTime.now();
    }
    
    @PreUpdate
    protected void onUpdate() {
        updatedAt = LocalDateTime.now();
    }
    
    // Constructors
    
    public NotificationPreferences() {
    }
    
    public NotificationPreferences(String userId) {
        this.userId = userId;
        // Default all preferences to true
        this.showtimeReminders = true;
        this.promotions = true;
        this.newMovies = true;
        this.bookingUpdates = true;
    }
    
    // Getters and Setters
    
    public String getUserId() {
        return userId;
    }
    
    public void setUserId(String userId) {
        this.userId = userId;
    }
    
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
    
    public LocalDateTime getCreatedAt() {
        return createdAt;
    }
    
    public void setCreatedAt(LocalDateTime createdAt) {
        this.createdAt = createdAt;
    }
    
    public LocalDateTime getUpdatedAt() {
        return updatedAt;
    }
    
    public void setUpdatedAt(LocalDateTime updatedAt) {
        this.updatedAt = updatedAt;
    }
}
