package com.cineluxe.service;

import static com.cineluxe.api.ApiDtos.*;

import com.cineluxe.api.ApiException;
import com.cineluxe.domain.Booking;
import com.cineluxe.domain.FoodCombo;
import com.cineluxe.domain.SeatStatus;
import com.cineluxe.domain.ShowtimeSeat;
import com.cineluxe.repository.BookingRepository;
import com.cineluxe.repository.FoodComboRepository;
import com.cineluxe.repository.ShowtimeSeatRepository;
import com.cineluxe.websocket.SeatWebSocketHandler;
import java.time.Duration;
import java.time.Instant;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.util.HexFormat;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;
import org.springframework.http.HttpStatus;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class BookingService {
  private static final Duration HOLD_DURATION = Duration.ofMinutes(10);
  private static final long DEFAULT_SEAT_PRICE = 120_000L;
  private static final String VNPAY_SECRET = "cineluxe-demo-vnpay-secret-key-123456789";
  private static final String API_BASE_URL = "http://10.0.2.2:8080";

  private final ShowtimeSeatRepository seatRepository;
  private final FoodComboRepository comboRepository;
  private final BookingRepository bookingRepository;
  private final SeatWebSocketHandler webSocketHandler;

  public BookingService(
      ShowtimeSeatRepository seatRepository,
      FoodComboRepository comboRepository,
      BookingRepository bookingRepository,
      SeatWebSocketHandler webSocketHandler) {
    this.seatRepository = seatRepository;
    this.comboRepository = comboRepository;
    this.bookingRepository = bookingRepository;
    this.webSocketHandler = webSocketHandler;
  }

  @Transactional(readOnly = true)
  public SeatMapResponse getSeats(String showtimeId) {
    return new SeatMapResponse(
        showtimeId,
        seatRepository.findByShowtimeIdOrderBySeatRowAscSeatColumnAsc(showtimeId)
            .stream().map(SeatDto::from).toList());
  }

  @Transactional
  public HoldResponse holdSeats(String showtimeId, HoldRequest request, String authenticatedUserId) {
    var userId = request.userId() == null || request.userId().isBlank()
        ? authenticatedUserId
        : request.userId();
    var requestedCodes = request.seatCodes().stream().distinct().sorted().toList();
    if (requestedCodes.size() > 8) {
      throw new ApiException(HttpStatus.BAD_REQUEST, "Maximum 8 seats per booking");
    }

    var seats = seatRepository.lockSeats(showtimeId, requestedCodes);
    if (seats.size() != requestedCodes.size()) {
      throw new ApiException(HttpStatus.BAD_REQUEST, "One or more seat codes do not exist");
    }
    var now = Instant.now();
    var unavailable = seats.stream()
        .filter(seat -> seat.getStatus() == SeatStatus.booked
            || (seat.getStatus() == SeatStatus.held
                && seat.getHoldExpiresAt().isAfter(now)
                && !userId.equals(seat.getHeldByUserId())))
        .map(ShowtimeSeat::getCode)
        .toList();
    if (!unavailable.isEmpty()) {
      throw new ApiException(HttpStatus.CONFLICT, "Seats are no longer available", unavailable);
    }

    var existingSeats = seatRepository.findByShowtimeIdAndHeldByUserId(showtimeId, userId).stream()
        .filter(seat -> seat.getHoldExpiresAt() != null && seat.getHoldExpiresAt().isAfter(now))
        .toList();
    var combinedSeats = java.util.stream.Stream.concat(existingSeats.stream(), seats.stream())
        .distinct()
        .toList();
    if (combinedSeats.size() > 8) {
      throw new ApiException(HttpStatus.BAD_REQUEST, "Maximum 8 seats per booking");
    }
    var existingHoldId = existingSeats.stream()
        .filter(seat -> seat.getHoldId() != null)
        .map(ShowtimeSeat::getHoldId)
        .findFirst();
    var holdId = existingHoldId.orElseGet(() -> "HOLD-" + UUID.randomUUID());
    var expiresAt = now.plus(HOLD_DURATION);
    combinedSeats.forEach(seat -> seat.hold(holdId, userId, expiresAt));
    seatRepository.saveAll(combinedSeats);
    webSocketHandler.broadcastAll(showtimeId, combinedSeats);
    return new HoldResponse(
        holdId,
        showtimeId,
        combinedSeats.stream().map(ShowtimeSeat::getCode).sorted().toList(),
        expiresAt);
  }

  @Transactional(readOnly = true)
  public List<ComboDto> getCombos() {
    return comboRepository.findByActiveTrue().stream().map(ComboDto::from).toList();
  }

  @Transactional
  public BookingResponse createBooking(CreateBookingRequest request, String authenticatedUserId) {
    var seats = seatRepository.findByHoldId(request.holdId());
    if (seats.isEmpty() || seats.stream().anyMatch(
        seat -> seat.getHoldExpiresAt() == null || seat.getHoldExpiresAt().isBefore(Instant.now()))) {
      throw new ApiException(HttpStatus.BAD_REQUEST, "Invalid or expired holdId");
    }
    var userId = request.userId() == null || request.userId().isBlank()
        ? authenticatedUserId
        : request.userId();
    var comboSelections = request.combos() == null ? List.<ComboSelection>of() : request.combos();
    var comboTotal = comboSelections.stream().mapToLong(selection -> {
      FoodCombo combo = comboRepository.findById(selection.comboId())
          .filter(FoodCombo::isActive)
          .orElseThrow(() -> new ApiException(
              HttpStatus.BAD_REQUEST, "Invalid food combo selection"));
      return combo.getPrice() * selection.quantity();
    }).sum();
    var bookingId = "BK-" + UUID.randomUUID();
    var total = seats.size() * DEFAULT_SEAT_PRICE + comboTotal;
    var booking = bookingRepository.save(new Booking(
        bookingId,
        userId,
        seats.get(0).getShowtimeId(),
        total,
        seats.stream().map(ShowtimeSeat::getCode).toList(),
        comboSelections.stream()
            .map(selection -> selection.comboId() + ":" + selection.quantity())
            .toList()));
    seats.forEach(ShowtimeSeat::book);
    seatRepository.saveAll(seats);
    webSocketHandler.broadcastAll(booking.getShowtimeId(), seats);
    var paymentParameters = "amount=" + total + "&bookingId=" + bookingId;
    return new BookingResponse(
        bookingId,
        booking.getStatus(),
        booking.getPaymentStatus(),
        total,
        API_BASE_URL + "/api/payments/sandbox/" + bookingId
            + "?" + paymentParameters + "&signature=" + sign(paymentParameters),
        booking.getPaymentExpiresAt());
  }

  @Transactional(readOnly = true)
  public BookingDetailsResponse getBooking(String bookingId) {
    return details(requireBooking(bookingId));
  }

  @Transactional(readOnly = true)
  public List<BookingDetailsResponse> getUserBookings(String userId, String status) {
    var bookings = status == null || status.isBlank()
        ? bookingRepository.findByUserIdOrderByCreatedAtDesc(userId)
        : bookingRepository.findByUserIdAndStatusOrderByCreatedAtDesc(userId, status);
    return bookings.stream().map(this::details).toList();
  }

  @Transactional(readOnly = true)
  public BookingQrResponse getBookingQr(String bookingId) {
    var booking = requireBooking(bookingId);
    if (!"active".equals(booking.getStatus()) || booking.getQrCode() == null) {
      throw new ApiException(HttpStatus.CONFLICT, "QR ticket is available after successful payment");
    }
    return new BookingQrResponse(
        booking.getId(),
        booking.getQrCode(),
        booking.getMovieTitle(),
        booking.getShowtimeDateTime(),
        booking.getRoomName(),
        booking.getCinemaName(),
        List.copyOf(booking.getSeatCodes()));
  }

  @Transactional
  public CancelBookingResponse cancelBooking(
      String bookingId, CancelBookingRequest request, String authenticatedUserId) {
    var booking = requireBooking(bookingId);
    var userId = request == null || request.userId() == null || request.userId().isBlank()
        ? authenticatedUserId
        : request.userId();
    if (!booking.getUserId().equals(userId)) {
      throw new ApiException(HttpStatus.FORBIDDEN, "Booking does not belong to requesting user");
    }
    if (!"active".equals(booking.getStatus())) {
      throw new ApiException(HttpStatus.CONFLICT, "Only active bookings can be cancelled");
    }
    var now = Instant.now();
    if (!booking.getShowtimeDateTime().isAfter(now)) {
      throw new ApiException(HttpStatus.BAD_REQUEST, "Cannot cancel after showtime");
    }
    var refund = booking.getShowtimeDateTime().isAfter(now.plus(Duration.ofHours(2)))
        ? booking.getTotalAmount()
        : booking.getTotalAmount() / 2;
    booking.cancel(refund);
    bookingRepository.save(booking);
    releaseBookingSeats(booking);
    return new CancelBookingResponse(booking.getId(), booking.getStatus(), refund, "refunded");
  }

  @Transactional
  public ValidationResult validateTicket(
      String bookingId, ValidateTicketRequest request, String authenticatedStaffId) {
    var booking = requireBooking(bookingId);
    if ("used".equals(booking.getStatus())) {
      throw new ApiException(HttpStatus.CONFLICT, "Ticket already validated");
    }
    if ("cancelled".equals(booking.getStatus()) || "refunded".equals(booking.getStatus())) {
      throw new ApiException(HttpStatus.FORBIDDEN, "Ticket cancelled, entry denied");
    }
    if (!"active".equals(booking.getStatus())) {
      throw new ApiException(HttpStatus.CONFLICT, "Ticket is not active");
    }
    if (!booking.getShowtimeId().equals(request.expectedShowtimeId())) {
      throw new ApiException(
          HttpStatus.BAD_REQUEST,
          "Wrong showtime. Ticket belongs to " + booking.getShowtimeId());
    }
    var now = Instant.now();
    var validationOpensAt = booking.getShowtimeDateTime().minus(Duration.ofHours(2));
    var validationClosesAt = booking.getShowtimeDateTime().plus(Duration.ofMinutes(30));
    if (now.isBefore(validationOpensAt) || now.isAfter(validationClosesAt)) {
      throw new ApiException(HttpStatus.BAD_REQUEST, "Validation window closed");
    }
    var staffId = request.staffId() == null || request.staffId().isBlank()
        ? authenticatedStaffId
        : request.staffId();
    booking.validateTicket(staffId);
    bookingRepository.save(booking);
    return new ValidationResult(
        true,
        booking.getStatus(),
        "Ticket validated successfully",
        booking.getId(),
        booking.getUserId(),
        booking.getMovieTitle(),
        booking.getShowtimeId(),
        booking.getShowtimeDateTime(),
        List.copyOf(booking.getSeatCodes()),
        booking.getValidatedAt());
  }

  @Transactional(readOnly = true)
  public PaymentStatusResponse getPaymentStatus(String bookingId) {
    var booking = requireBooking(bookingId);
    return paymentStatus(booking);
  }

  @Transactional(readOnly = true)
  public String sandboxPaymentPage(String bookingId) {
    var booking = requireBooking(bookingId);
    if (!"pendingPayment".equals(booking.getStatus())) {
      return "<html><body><h2>Payment already processed</h2></body></html>";
    }
    var transactionId = "VNP-" + System.currentTimeMillis();
    var success = paymentReturnUrl(bookingId, "00", transactionId);
    var failure = paymentReturnUrl(bookingId, "24", transactionId);
    return """
        <!doctype html><html><head><meta name="viewport" content="width=device-width,initial-scale=1">
        <style>body{font-family:sans-serif;padding:32px;background:#f5f5f5}main{max-width:520px;margin:auto;background:white;padding:28px;border-radius:16px}
        a{display:block;margin:16px 0;padding:16px;text-align:center;text-decoration:none;border-radius:8px;background:#111;color:white}
        a.fail{background:#b42318}</style></head><body><main><h2>VNPay Sandbox</h2>
        <p>Booking: %s</p><p>Amount: %,d VND</p>
        <a href="%s">Complete payment</a><a class="fail" href="%s">Simulate failure</a>
        </main></body></html>
        """.formatted(bookingId, booking.getTotalAmount(), success, failure);
  }

  @Transactional
  public PaymentStatusResponse processPaymentReturn(Map<String, String> parameters) {
    var bookingId = parameters.getOrDefault("bookingId", "");
    var responseCode = parameters.getOrDefault("responseCode", "");
    var transactionId = parameters.getOrDefault("transactionId", "");
    var signature = parameters.getOrDefault("signature", "");
    var payload = callbackPayload(bookingId, responseCode, transactionId);
    if (!MessageDigest.isEqual(
        sign(payload).getBytes(StandardCharsets.UTF_8),
        signature.getBytes(StandardCharsets.UTF_8))) {
      throw new ApiException(HttpStatus.BAD_REQUEST, "Invalid VNPay signature");
    }
    var booking = requireBooking(bookingId);
    if ("pendingPayment".equals(booking.getStatus())) {
      if ("00".equals(responseCode)) {
        booking.completePayment(transactionId, responseCode);
      } else {
        booking.failPayment(transactionId, responseCode);
        releaseBookingSeats(booking);
      }
      bookingRepository.save(booking);
    }
    return paymentStatus(booking);
  }

  @Scheduled(fixedDelay = 5_000)
  @Transactional
  public void releaseExpiredHolds() {
    var expired = seatRepository.findByStatusAndHoldExpiresAtBefore(SeatStatus.held, Instant.now());
    expired.forEach(ShowtimeSeat::release);
    seatRepository.saveAll(expired);
    expired.stream().map(ShowtimeSeat::getShowtimeId).distinct().forEach(showtimeId ->
        webSocketHandler.broadcastAll(
            showtimeId,
            expired.stream().filter(seat -> showtimeId.equals(seat.getShowtimeId())).toList()));
  }

  @Scheduled(fixedDelay = 30_000)
  @Transactional
  public void cancelExpiredPayments() {
    bookingRepository.findByStatusAndPaymentExpiresAtBefore("pendingPayment", Instant.now())
        .forEach(booking -> {
          booking.failPayment(null, "TIMEOUT");
          bookingRepository.save(booking);
          releaseBookingSeats(booking);
        });
  }

  private Booking requireBooking(String bookingId) {
    return bookingRepository.findById(bookingId)
        .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Booking not found: " + bookingId));
  }

  private BookingDetailsResponse details(Booking booking) {
    return new BookingDetailsResponse(
        booking.getId(),
        booking.getUserId(),
        booking.getShowtimeId(),
        booking.getMovieTitle(),
        booking.getRoomName(),
        booking.getCinemaName(),
        booking.getShowtimeDateTime(),
        List.copyOf(booking.getSeatCodes()),
        List.copyOf(booking.getComboSelections()),
        booking.getTotalAmount(),
        booking.getStatus(),
        booking.getPaymentStatus(),
        booking.getCreatedAt(),
        booking.getQrCode());
  }

  private PaymentStatusResponse paymentStatus(Booking booking) {
    return new PaymentStatusResponse(
        booking.getId(),
        booking.getStatus(),
        booking.getPaymentStatus(),
        booking.getTransactionId(),
        booking.getResponseCode());
  }

  private void releaseBookingSeats(Booking booking) {
    var seats = seatRepository.lockSeats(booking.getShowtimeId(), booking.getSeatCodes());
    seats.forEach(ShowtimeSeat::release);
    seatRepository.saveAll(seats);
    webSocketHandler.broadcastAll(booking.getShowtimeId(), seats);
  }

  private String paymentReturnUrl(String bookingId, String responseCode, String transactionId) {
    var payload = callbackPayload(bookingId, responseCode, transactionId);
    return API_BASE_URL + "/api/payments/vnpay/return?" + payload + "&signature=" + sign(payload);
  }

  private String callbackPayload(String bookingId, String responseCode, String transactionId) {
    return "bookingId=" + bookingId + "&responseCode=" + responseCode
        + "&transactionId=" + transactionId;
  }

  private String sign(String payload) {
    try {
      var mac = Mac.getInstance("HmacSHA512");
      mac.init(new SecretKeySpec(VNPAY_SECRET.getBytes(StandardCharsets.UTF_8), "HmacSHA512"));
      return HexFormat.of().formatHex(mac.doFinal(payload.getBytes(StandardCharsets.UTF_8)));
    } catch (Exception exception) {
      throw new IllegalStateException("Unable to sign VNPay parameters", exception);
    }
  }
}
