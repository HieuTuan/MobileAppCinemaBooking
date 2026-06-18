package com.cineluxe.service.impl;

import com.cineluxe.dto.request.UpdateNotificationPreferenceRequest;
import com.cineluxe.dto.response.NotificationPreferenceResponse;
import com.cineluxe.entity.NotificationPreference;
import com.cineluxe.repository.NotificationPreferenceRepository;
import com.cineluxe.service.NotificationPreferenceService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Implementation of NotificationPreferenceService.
 */
@Service
@RequiredArgsConstructor
@Slf4j
@Transactional
public class NotificationPreferenceServiceImpl implements NotificationPreferenceService {

  private final NotificationPreferenceRepository repository;

  @Override
  @Transactional(readOnly = true)
  public NotificationPreferenceResponse getPreferences(String userId) {
    return repository.findByUserId(userId)
        .map(NotificationPreferenceResponse::from)
        .orElseGet(() -> defaults(userId));
  }

  @Override
  public NotificationPreferenceResponse updatePreferences(
      String userId, UpdateNotificationPreferenceRequest request) {
    var pref = repository.findByUserId(userId)
        .orElseGet(() -> new NotificationPreference(userId));
    pref.update(
        request.showtimeReminders(),
        request.promotions(),
        request.newMovies(),
        request.bookingUpdates());
    var saved = repository.save(pref);
    log.debug("Updated notification preferences for user: {}", userId);
    return NotificationPreferenceResponse.from(saved);
  }

  private NotificationPreferenceResponse defaults(String userId) {
    return new NotificationPreferenceResponse(
        userId,
        true,
        true,
        true,
        true,
        null,
        null);
  }
}
