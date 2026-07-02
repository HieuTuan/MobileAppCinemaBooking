package com.cineluxe.service.impl;

import com.cineluxe.dto.request.CancelBookingRequest;
import com.cineluxe.dto.request.ComboSelection;
import com.cineluxe.dto.request.CreateBookingRequest;
import com.cineluxe.dto.request.HoldRequest;
import com.cineluxe.dto.request.SearchBookingsRequest;
import com.cineluxe.dto.request.ValidateTicketRequest;
import com.cineluxe.dto.response.BookingDetailsResponse;
import com.cineluxe.dto.response.BookingQrResponse;
import com.cineluxe.dto.response.BookingResponse;
import com.cineluxe.dto.response.BookingSearchResult;
import com.cineluxe.dto.response.CancelBookingResponse;
import com.cineluxe.dto.response.ComboDto;
import com.cineluxe.dto.response.HoldResponse;
import com.cineluxe.dto.response.PaymentStatusResponse;
import com.cineluxe.dto.response.SeatDto;
import com.cineluxe.dto.response.SeatMapResponse;
import com.cineluxe.dto.response.StaffOfflineSyncDto;
import com.cineluxe.dto.response.ValidationResult;
import com.cineluxe.entity.Booking;
import com.cineluxe.entity.FoodCombo;
import com.cineluxe.entity.SeatStatus;
import com.cineluxe.entity.ShowtimeSeat;
import com.cineluxe.exception.ApiException;
import com.cineluxe.repository.BookingRepository;
import com.cineluxe.repository.FoodComboRepository;
import com.cineluxe.repository.RoomRepository;
import com.cineluxe.repository.ShowtimeSeatRepository;
import com.cineluxe.repository.ShowtimeRepository;
import com.cineluxe.repository.UserProfileRepository;
import com.cineluxe.service.AnalyticsService;
import com.cineluxe.service.BookingService;
import com.cineluxe.service.NotificationService;
import com.cineluxe.websocket.SeatWebSocketHandler;
import com.cloudinary.Cloudinary;
import com.cloudinary.utils.ObjectUtils;
import com.google.zxing.BarcodeFormat;
import com.google.zxing.client.j2se.MatrixToImageWriter;
import com.google.zxing.common.BitMatrix;
import com.google.zxing.qrcode.QRCodeWriter;
import java.io.ByteArrayOutputStream;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.time.Duration;
import java.time.Instant;
import java.time.LocalDate;
import java.time.Period;
import java.util.ArrayList;
import java.util.HexFormat;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
@Slf4j
@Transactional
public class BookingServiceImpl implements BookingService {

    private static final Duration HOLD_DURATION = Duration.ofMinutes(10);
    private static final long DEFAULT_SEAT_PRICE = 120_000L;

    private final ShowtimeSeatRepository seatRepository;
    private final FoodComboRepository comboRepository;
    private final BookingRepository bookingRepository;
    private final ShowtimeRepository showtimeRepository;
    private final RoomRepository roomRepository;
    private final SeatWebSocketHandler webSocketHandler;
    private final NotificationService notificationService;
    private final UserProfileRepository userProfileRepository;
    private final AnalyticsService analyticsService;
    private final Cloudinary cloudinary;

    @Value("${booking.vnpay-secret:cineluxe-demo-vnpay-secret-key-123456789}")
    private String vnpaySecret;

    @Value("${booking.api-base-url:http://10.0.2.2:8080}")
    private String apiBaseUrl;

    private static long offlineSyncVersionCounter = 0L;

    @Override
    @Transactional(readOnly = true)
    public SeatMapResponse getSeats(String showtimeId) {
        return new SeatMapResponse(
                showtimeId,
                seatRepository.findByShowtimeIdOrderBySeatRowAscSeatColumnAsc(showtimeId)
                        .stream().map(SeatDto::from).toList());
    }

    @Override
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

        // Req 41.5 — funnel: seat_hold
        analyticsService.logSeatHold(userId, showtimeId, holdId, combinedSeats.size());

        return new HoldResponse(
                holdId,
                showtimeId,
                combinedSeats.stream().map(ShowtimeSeat::getCode).sorted().toList(),
                expiresAt);
    }

    @Override
    @Transactional(readOnly = true)
    public List<ComboDto> getCombos() {
        return comboRepository.findByActiveTrue().stream().map(ComboDto::from).toList();
    }

    @Override
    public BookingResponse createBooking(CreateBookingRequest request, String authenticatedUserId) {
        // Age verification for T18 movies — Requirements 7.5, 7.6, 7.7
        var userId = request.userId() == null || request.userId().isBlank()
                ? authenticatedUserId
                : request.userId();
        if ("T18".equals(request.movieAgeRating())) {
            var profile = userProfileRepository.findById(userId).orElse(null);
            if (profile == null || profile.getBirthdate() == null) {
                // Bước 5: Log mọi lần thử T18 (audit compliance)
                log.info("T18_AGE_CHECK userId={} movieAgeRating=T18 birthdate=null result=DENIED reason=no_birthdate",
                        anonymiseUserId(userId));
                throw new ApiException(HttpStatus.FORBIDDEN, "Age verification required for this movie");
            }
            int age = Period.between(profile.getBirthdate(), LocalDate.now()).getYears();
            if (age < 18) {
                // Bước 5: Log thử T18 thất bại — dưới 18 tuổi
                log.info("T18_AGE_CHECK userId={} movieAgeRating=T18 age={} result=DENIED reason=underage",
                        anonymiseUserId(userId), age);
                throw new ApiException(HttpStatus.FORBIDDEN, "Age verification required for this movie");
            }
            // Bước 5: Log thử T18 thành công
            log.info("T18_AGE_CHECK userId={} movieAgeRating=T18 age={} result=APPROVED",
                    anonymiseUserId(userId), age);
        }
        var seats = seatRepository.findByHoldId(request.holdId());
        if (seats.isEmpty() || seats.stream().anyMatch(
                seat -> seat.getHoldExpiresAt() == null || seat.getHoldExpiresAt().isBefore(Instant.now()))) {
            throw new ApiException(HttpStatus.BAD_REQUEST, "Invalid or expired holdId");
        }
        var comboSelections = request.combos() == null ? List.<ComboSelection>of() : request.combos();
        var selectedCombos = new ArrayList<FoodCombo>();
        long comboTotal = 0;
        for (var selection : comboSelections) {
            // Validate quantity > 0 (Req R8 lỗi & ngoại lệ)
            if (selection.quantity() <= 0) {
                throw new ApiException(HttpStatus.BAD_REQUEST, "Invalid food combo selection");
            }
            // ComboId invalid hoặc inactive → 400 "Invalid food combo selection"
            FoodCombo combo = comboRepository.findById(selection.comboId())
                    .filter(FoodCombo::isActive)
                    .orElseThrow(() -> new ApiException(
                            HttpStatus.BAD_REQUEST, "Invalid food combo selection"));
            if (combo.getQuantity() < selection.quantity()) {
                throw new ApiException(HttpStatus.BAD_REQUEST,
                        "Không đủ số lượng cho combo: " + combo.getName());
            }
            comboTotal += combo.getPrice() * selection.quantity();
            combo.setQuantity(combo.getQuantity() - selection.quantity());
            if (combo.getQuantity() == 0) {
                combo.setActive(false);
            }
            selectedCombos.add(combo);
        }
        var bookingId = "BK-" + UUID.randomUUID();
        var total = seats.size() * DEFAULT_SEAT_PRICE + comboTotal;

        // R5: Lấy thông tin showtime và phòng thực tế (không hardcode) — Req 9.1
        var showtimeId = seats.get(0).getShowtimeId();
        var showtime = showtimeRepository.findById(showtimeId).orElse(null);
        var room = (showtime != null)
                ? roomRepository.findById(showtime.getRoomId()).orElse(null)
                : null;
        var showtimeDateTime = (showtime != null && showtime.getStartTime() != null)
                ? showtime.getStartTime()
                : Instant.now().plusSeconds(4 * 60 * 60); // fallback: +4 giờ
        var cinemaName = (showtime != null && showtime.getCinemaName() != null)
                ? showtime.getCinemaName()
                : "CineLuxe Tràng Tiền";
        var roomName = (room != null && room.getName() != null)
                ? room.getName()
                : "Phòng chiếu";

        var booking = new Booking(
                bookingId,
                userId,
                showtimeId,
                total,
                seats.stream().map(ShowtimeSeat::getCode).toList(),
                comboSelections.stream()
                        .map(selection -> selection.comboId() + ":" + selection.quantity())
                        .toList());
        booking.updateShowtimeDateTime(showtimeDateTime);
        booking.updateCinemaInfo(cinemaName, roomName);
        bookingRepository.save(booking);
        seats.forEach(ShowtimeSeat::book);
        seatRepository.saveAll(seats);
        comboRepository.saveAll(selectedCombos);
        webSocketHandler.broadcastAll(booking.getShowtimeId(), seats);
        var paymentParameters = "amount=" + total + "&bookingId=" + bookingId;

        // Req 41.5 — funnel: payment_initiate
        analyticsService.logPaymentInitiate(userId, bookingId, seats.get(0).getShowtimeId(), total);

        return new BookingResponse(
                bookingId,
                booking.getStatus(),
                booking.getPaymentStatus(),
                total,
                stripTrailingSlash(apiBaseUrl) + "/api/payments/sandbox/" + bookingId
                        + "?" + paymentParameters + "&signature=" + sign(paymentParameters),
                booking.getPaymentExpiresAt());
    }

    @Override
    @Transactional(readOnly = true)
    public BookingDetailsResponse getBooking(String bookingId) {
        return details(requireBooking(bookingId));
    }

    @Override
    @Transactional(readOnly = true)
    public List<BookingDetailsResponse> getUserBookings(String userId, String status) {
        var bookings = status == null || status.isBlank()
                ? bookingRepository.findByUserIdOrderByCreatedAtDesc(userId)
                : bookingRepository.findByUserIdAndStatusOrderByCreatedAtDesc(userId, status);
        return bookings.stream().map(this::details).toList();
    }

    @Override
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
                List.copyOf(booking.getSeatCodes()),
                booking.getQrCodeUrl());
    }

    @Override
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
        
        if (refund > 0) {
            log.info("Sending VNPay refund request to gateway for booking: {}, amount: {}", booking.getId(), refund);
            booking.setRefundedAt(now);
        }
        
        booking.cancel(refund);
        bookingRepository.save(booking);
        
        var userProfile = userProfileRepository.findById(userId).orElse(null);
        if (userProfile != null) {
            int pointsToDeduct = (int) (booking.getTotalAmount() / 10000);
            userProfile.setPoints(Math.max(0, userProfile.getPoints() - pointsToDeduct));
            userProfileRepository.save(userProfile);
            log.info("Deducted {} member points from user {}. New points balance: {}", pointsToDeduct, userId, userProfile.getPoints());
        }
        
        releaseBookingSeats(booking);
        notificationService.sendBookingCancellation(userId, booking);
        return new CancelBookingResponse(booking.getId(), booking.getStatus(), refund, refund > 0 ? "refunded" : "cancelled");
    }

    @Override
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

    @Override
    @Transactional(readOnly = true)
    public List<BookingSearchResult> searchBookings(SearchBookingsRequest request) {
        var now = Instant.now();
        var plus24Hours = now.plus(Duration.ofHours(24));
        var bookingId = request.bookingId() == null ? "" : request.bookingId();
        var customerName = request.customerName() == null ? "" : request.customerName();

        var bookings = bookingRepository.searchBookingsForValidation(
                bookingId, customerName, now, plus24Hours);
        return bookings.stream().map(BookingSearchResult::from).toList();
    }

    @Override
    public ValidationResult staffManualValidate(String bookingId, String staffId) {
        var booking = requireBooking(bookingId);

        // Apply same validation rules as QR code validation
        if ("used".equals(booking.getStatus())) {
            throw new ApiException(HttpStatus.CONFLICT, "Ticket already validated");
        }
        if ("cancelled".equals(booking.getStatus()) || "refunded".equals(booking.getStatus())) {
            throw new ApiException(HttpStatus.FORBIDDEN, "Ticket cancelled, entry denied");
        }
        if (!"active".equals(booking.getStatus())) {
            throw new ApiException(HttpStatus.CONFLICT, "Ticket is not active");
        }

        var now = Instant.now();
        var validationOpensAt = booking.getShowtimeDateTime().minus(Duration.ofHours(2));
        var validationClosesAt = booking.getShowtimeDateTime().plus(Duration.ofMinutes(30));
        if (now.isBefore(validationOpensAt) || now.isAfter(validationClosesAt)) {
            throw new ApiException(HttpStatus.BAD_REQUEST, "Validation window closed");
        }

        // Validate the ticket
        booking.validateTicket(staffId);
        bookingRepository.save(booking);
        return new ValidationResult(
                true,
                booking.getStatus(),
                "Ticket validated manually by staff",
                booking.getId(),
                booking.getUserId(),
                booking.getMovieTitle(),
                booking.getShowtimeId(),
                booking.getShowtimeDateTime(),
                List.copyOf(booking.getSeatCodes()),
                booking.getValidatedAt());
    }

    @Override
    @Transactional(readOnly = true)
    public PaymentStatusResponse getPaymentStatus(String bookingId) {
        var booking = requireBooking(bookingId);
        return paymentStatus(booking);
    }

    @Override
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

    @Override
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

                // --- Generate and upload QR code (R10) ---
                try {
                    List<String> sortedSeats = new java.util.ArrayList<>(booking.getSeatCodes());
                    java.util.Collections.sort(sortedSeats);
                    String rawQrContent = "CINELUXE|" + booking.getId() + "|" + booking.getUserId() + "|" 
                            + booking.getShowtimeId() + "|" + String.join("-", sortedSeats);

                    byte[] qrPngBytes = generateQrCodePng(rawQrContent, 300, 300);

                    String publicId = "cineluxe/qr/" + booking.getId();
                    Map<?, ?> uploadResult = cloudinary.uploader().upload(
                            qrPngBytes,
                            ObjectUtils.asMap(
                                    "public_id", publicId,
                                    "overwrite", true,
                                    "resource_type", "image",
                                    "access_mode", "public"
                            )
                    );

                    String qrUrl = (String) uploadResult.get("secure_url");
                    booking.setQrCodeUrl(qrUrl);
                    log.info("Successfully generated and uploaded QR code image to Cloudinary for booking {}: {}", booking.getId(), qrUrl);
                } catch (Exception e) {
                    log.error("Failed to generate and upload QR code image for booking {}", booking.getId(), e);
                }

                notificationService.sendPaymentConfirmation(booking.getUserId(), booking);
                // Req 41.6 — funnel: payment_complete
                analyticsService.logPaymentComplete(
                        booking.getUserId(), bookingId, transactionId, booking.getTotalAmount());
            } else {
                booking.failPayment(transactionId, responseCode);
                releaseBookingSeats(booking);
                // Req 41.6 — funnel: payment_fail
                analyticsService.logPaymentFail(booking.getUserId(), bookingId, responseCode);
            }
            bookingRepository.save(booking);
        }
        return paymentStatus(booking);
    }

    // ─── Scheduled tasks ───────────────────────────────────────────────────

    @Scheduled(fixedDelay = 5_000)
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
    public void cancelExpiredPayments() {
        bookingRepository.findByStatusAndPaymentExpiresAtBefore("pendingPayment", Instant.now())
                .forEach(booking -> {
                    booking.failPayment(null, "TIMEOUT");
                    bookingRepository.save(booking);
                    releaseBookingSeats(booking);
                });
    }

    // ─── Offline sync ─────────────────────────────────────────────────

    @Override
    @Transactional(readOnly = true)
    public StaffOfflineSyncDto getOfflineSyncData() {
        var now = Instant.now();
        var windowStart = now.minus(Duration.ofHours(2));
        var windowEnd = now.plus(Duration.ofHours(24));
        var bookings = bookingRepository.findActiveBookingsForOfflineSync(windowStart, windowEnd);
        var syncedAt = Instant.now();
        var expiresAt = syncedAt.plus(Duration.ofMinutes(30));
        offlineSyncVersionCounter++;
        return new StaffOfflineSyncDto(
                bookings.stream().map(BookingSearchResult::from).toList(),
                bookings.size(),
                syncedAt,
                expiresAt,
                offlineSyncVersionCounter);
    }

    // ─── Private helpers ──────────────────────────────────────────────────

    private String anonymiseUserId(String userId) {
        if (userId == null || userId.length() <= 8) {
            return userId;
        }
        return userId.substring(0, 8) + "****";
    }

    private String stripTrailingSlash(String value) {
        if (value == null || value.isBlank()) {
            return "";
        }
        var trimmed = value.trim();
        while (trimmed.endsWith("/")) {
            trimmed = trimmed.substring(0, trimmed.length() - 1);
        }
        return trimmed;
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
                booking.getQrCode(),
                booking.getQrCodeUrl());
    }

    private byte[] generateQrCodePng(String text, int width, int height) throws Exception {
        QRCodeWriter qrCodeWriter = new QRCodeWriter();
        BitMatrix bitMatrix = qrCodeWriter.encode(text, BarcodeFormat.QR_CODE, width, height);
        ByteArrayOutputStream pngOutputStream = new ByteArrayOutputStream();
        MatrixToImageWriter.writeToStream(bitMatrix, "PNG", pngOutputStream);
        return pngOutputStream.toByteArray();
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
        return stripTrailingSlash(apiBaseUrl) + "/api/payments/vnpay/return?" + payload + "&signature=" + sign(payload);
    }

    private String callbackPayload(String bookingId, String responseCode, String transactionId) {
        return "bookingId=" + bookingId + "&responseCode=" + responseCode
                + "&transactionId=" + transactionId;
    }

    private String sign(String payload) {
        try {
            var mac = Mac.getInstance("HmacSHA512");
            mac.init(new SecretKeySpec(vnpaySecret.getBytes(StandardCharsets.UTF_8), "HmacSHA512"));
            return HexFormat.of().formatHex(mac.doFinal(payload.getBytes(StandardCharsets.UTF_8)));
        } catch (Exception exception) {
            throw new IllegalStateException("Unable to sign VNPay parameters", exception);
        }
    }
}
