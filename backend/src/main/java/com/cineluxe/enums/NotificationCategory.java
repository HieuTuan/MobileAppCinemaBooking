package com.cineluxe.enums;

/**
 * Enumeration of notification categories used in the system.
 * 
 * Requirements Coverage:
 * - Requirement 38.2: Categories for notification preferences
 * - Requirement 38.5: Critical notifications that bypass preferences
 */
public enum NotificationCategory {
    /**
     * Showtime reminder notifications (2 hours before screening)
     * Non-critical - respects user preferences
     */
    SHOWTIME_REMINDERS("showtimeReminders", false),
    
    /**
     * Promotional and marketing notifications
     * Non-critical - respects user preferences
     */
    PROMOTIONS("promotions", false),
    
    /**
     * New movie release notifications
     * Non-critical - respects user preferences
     */
    NEW_MOVIES("newMovies", false),
    
    /**
     * Booking update notifications (general updates)
     * Non-critical - respects user preferences
     */
    BOOKING_UPDATES("bookingUpdates", false),
    
    /**
     * Payment confirmation notifications (success/failure)
     * CRITICAL - always sent regardless of preferences
     */
    PAYMENT_CONFIRMATION("paymentConfirmation", true),
    
    /**
     * Booking cancellation notifications
     * CRITICAL - always sent regardless of preferences
     */
    BOOKING_CANCELLATION("bookingCancellation", true);
    
    private final String categoryName;
    private final boolean isCritical;
    
    NotificationCategory(String categoryName, boolean isCritical) {
        this.categoryName = categoryName;
        this.isCritical = isCritical;
    }
    
    public String getCategoryName() {
        return categoryName;
    }
    
    public boolean isCritical() {
        return isCritical;
    }
    
    /**
     * Get NotificationCategory from category name string.
     * Supports various formats: camelCase, snake_case, lowercase
     * 
     * @param category Category name string
     * @return NotificationCategory or null if not found
     */
    public static NotificationCategory fromString(String category) {
        if (category == null) {
            return null;
        }
        
        String normalized = category.toLowerCase().replace("_", "");
        
        for (NotificationCategory cat : NotificationCategory.values()) {
            String catNormalized = cat.categoryName.toLowerCase().replace("_", "");
            if (catNormalized.equals(normalized)) {
                return cat;
            }
        }
        
        return null;
    }
    
    /**
     * Check if a notification category is critical.
     * Critical notifications bypass user preferences.
     * 
     * Requirement 38.5: Critical notifications always sent
     * 
     * @param category Category name string
     * @return true if critical, false otherwise
     */
    public static boolean isCriticalNotification(String category) {
        NotificationCategory cat = fromString(category);
        return cat != null && cat.isCritical();
    }
}
