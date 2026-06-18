package com.cineluxe.service;

import com.cineluxe.dto.request.UpdateNotificationPreferenceRequest;
import com.cineluxe.dto.response.NotificationPreferenceResponse;

/**
 * Service interface for managing user notification preferences.
 */
public interface NotificationPreferenceService {

  /**
   * Get notification preferences for a user.
   * If the user has no preferences record, returns defaults (all enabled).
   */
  NotificationPreferenceResponse getPreferences(String userId);

  /**
   * Update notification preferences for a user.
   * Creates a record if it does not exist.
   */
  NotificationPreferenceResponse updatePreferences(
      String userId, UpdateNotificationPreferenceRequest request);
}
