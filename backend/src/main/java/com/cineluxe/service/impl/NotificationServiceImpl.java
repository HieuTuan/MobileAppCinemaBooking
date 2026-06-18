package com.cineluxe.service.impl;

import com.cineluxe.entity.Booking;
import com.cineluxe.entity.Device;
import com.cineluxe.repository.DeviceRepository;
import com.cineluxe.repository.NotificationPreferenceRepository;
import com.cineluxe.service.NotificationService;
import java.util.List;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Implementation of NotificationService.
 *
 * <p>Critical notifications (payment confirmation, booking cancellation) are always sent.
 * All other notification types respect the user's {@link com.cineluxe.entity.NotificationPreference}.
 *
 * <p>FCM/APNs token delivery is delegated to the configured push provider.
 * When no provider is configured (e.g., in development), notifications are logged only.
 */
@Service
@RequiredArgsConstructor
@Slf4j
@Transactional(readOnly = true)
public class NotificationServiceImpl implements NotificationService {

  private final DeviceRepository deviceRepository;
  private final NotificationPreferenceRepository preferenceRepository;

  // ─── Critical notifications — always sent regardless of preferences ────────

  @Override
  public void sendPaymentConfirmation(String userId, Booking booking) {
    var title = "Thanh toán thành công";
    var body = String.format(
        "Vé xem phim \"%s\" đã được thanh toán thành công. Mã vé: %s",
        booking.getMovieTitle(), booking.getId());
    sendToUserDevices(userId, title, body);
    log.info("Critical notification [PAYMENT_CONFIRMATION] sent to user={}, booking={}",
        userId, booking.getId());
  }

  @Override
  public void sendBookingCancellation(String userId, Booking booking) {
    var title = "Đơn đặt vé đã bị hủy";
    var body = String.format(
        "Vé xem phim \"%s\" (mã: %s) đã bị hủy. Số tiền hoàn: %,d VND",
        booking.getMovieTitle(), booking.getId(), booking.getRefundAmount());
    sendToUserDevices(userId, title, body);
    log.info("Critical notification [BOOKING_CANCELLATION] sent to user={}, booking={}",
        userId, booking.getId());
  }

  // ─── Non-critical notifications — respect user preferences ─────────────────

  @Override
  public void sendShowtimeReminder(String userId, Booking booking) {
    if (!isEnabled(userId, pref -> pref.isShowtimeReminders())) {
      log.debug("Showtime reminder skipped for user={} (disabled)", userId);
      return;
    }
    var title = "Nhắc nhở lịch chiếu";
    var body = String.format(
        "Phim \"%s\" sẽ chiếu vào lúc %s tại %s. Chúc bạn xem phim vui vẻ!",
        booking.getMovieTitle(), booking.getShowtimeDateTime(), booking.getCinemaName());
    sendToUserDevices(userId, title, body);
    log.info("Showtime reminder sent to user={}, booking={}", userId, booking.getId());
  }

  @Override
  public void sendPromotion(String userId, String title, String body) {
    if (!isEnabled(userId, pref -> pref.isPromotions())) {
      log.debug("Promotion skipped for user={} (disabled)", userId);
      return;
    }
    sendToUserDevices(userId, title, body);
    log.info("Promotion sent to user={}: {}", userId, title);
  }

  @Override
  public void sendNewMovieAnnouncement(String userId, String title, String body) {
    if (!isEnabled(userId, pref -> pref.isNewMovies())) {
      log.debug("New movie announcement skipped for user={} (disabled)", userId);
      return;
    }
    sendToUserDevices(userId, title, body);
    log.info("New movie announcement sent to user={}: {}", userId, title);
  }

  @Override
  public void sendBookingUpdate(String userId, String title, String body) {
    if (!isEnabled(userId, pref -> pref.isBookingUpdates())) {
      log.debug("Booking update skipped for user={} (disabled)", userId);
      return;
    }
    sendToUserDevices(userId, title, body);
    log.info("Booking update sent to user={}: {}", userId, title);
  }

  // ─── Private helpers ──────────────────────────────────────────────────────

  private void sendToUserDevices(String userId, String title, String body) {
    List<Device> devices = deviceRepository.findAllByUserIdAndActiveTrue(userId);
    if (devices.isEmpty()) {
      log.debug("No active devices for user={}, notification not delivered: {}", userId, title);
      return;
    }
    for (Device device : devices) {
      deliver(device.getToken(), device.getPlatform().name(), title, body);
    }
  }

  private void deliver(String token, String platform, String title, String body) {
    // TODO: Integrate with Firebase Admin SDK for FCM (android/web)
    //       or APNs for iOS when a push provider is configured.
    //       For now, log the notification payload.
    log.debug("[{}] Notification → token={}: title=\"{}\", body=\"{}\"",
        platform, token, title, body);
  }

  @FunctionalInterface
  private interface PreferenceCheck {
    boolean test(com.cineluxe.entity.NotificationPreference pref);
  }

  private boolean isEnabled(String userId, PreferenceCheck check) {
    return preferenceRepository.findByUserId(userId)
        .map(check::test)
        .orElse(true); // Default to enabled when no preference record exists
  }
}
