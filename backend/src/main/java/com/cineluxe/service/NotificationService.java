package com.cineluxe.service;

import com.cineluxe.entity.Booking;

/**
 * Service responsible for sending push notifications to user devices.
 * Delegates actual delivery to Firebase Cloud Messaging (FCM) / APNs.
 */
public interface NotificationService {

  /**
   * Send a payment confirmation notification.
   * Critical — sent regardless of user preferences.
   *
   * @param userId  the target user ID
   * @param booking the confirmed booking
   */
  void sendPaymentConfirmation(String userId, Booking booking);

  /**
   * Send a booking cancellation notification.
   * Critical — sent regardless of user preferences.
   *
   * @param userId  the target user ID
   * @param booking the cancelled booking
   */
  void sendBookingCancellation(String userId, Booking booking);

  /**
   * Send a showtime reminder notification.
   * Respects user preferences ({@code showtimeReminders}).
   *
   * @param userId the target user ID
   * @param booking the booking to remind about
   */
  void sendShowtimeReminder(String userId, Booking booking);

  /**
   * Send a promotion notification.
   * Respects user preferences ({@code promotions}).
   *
   * @param userId the target user ID
   * @param title  notification title
   * @param body   notification body
   */
  void sendPromotion(String userId, String title, String body);

  /**
   * Send a new movie announcement notification.
   * Respects user preferences ({@code newMovies}).
   *
   * @param userId the target user ID
   * @param title  notification title
   * @param body   notification body
   */
  void sendNewMovieAnnouncement(String userId, String title, String body);

  /**
   * Send a booking update notification (e.g., status change).
   * Respects user preferences ({@code bookingUpdates}).
   *
   * @param userId the target user ID
   * @param title  notification title
   * @param body   notification body
   */
  void sendBookingUpdate(String userId, String title, String body);
}
