package com.cineluxe.dto.response;

import com.cineluxe.entity.NotificationPreference;
import java.time.Instant;

/**
 * Response DTO for notification preferences.
 */
public record NotificationPreferenceResponse(
    String userId,
    boolean showtimeReminders,
    boolean promotions,
    boolean newMovies,
    boolean bookingUpdates,
    Instant createdAt,
    Instant updatedAt
) {

  public static NotificationPreferenceResponse from(NotificationPreference pref) {
    return new NotificationPreferenceResponse(
        pref.getUserId(),
        pref.isShowtimeReminders(),
        pref.isPromotions(),
        pref.isNewMovies(),
        pref.isBookingUpdates(),
        pref.getCreatedAt(),
        pref.getUpdatedAt());
  }
}
