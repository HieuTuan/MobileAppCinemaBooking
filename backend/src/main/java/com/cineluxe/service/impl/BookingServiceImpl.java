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
import java.net.URLEncoder;
import java.time.LocalDateTime;
import java.time.ZoneId;
import java.time.format.DateTimeFormatter;
import java.util.TreeMap;
import java.util.UUID;
import java.util.stream.Collectors;
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

    @Value("${booking.vnpay-secret:cineluxe-demo-vnpay-secret-key-123456789}")
    private String vnpaySecret;

    @Value("${booking.api-base-url:http://10.0.2.2:8080}")
    private String apiBaseUrl;

    @Value("${booking.vnpay-pay-url:}")
    private String vnpayPayUrl;

    @Value("${booking.vnpay-terminal-id:}")
    private String vnpayTerminalId;

    @Value("${booking.vnpay-return-url:}")
    private String vnpayReturnUrl;

    @Value("${booking.vnpay-order-type:other}")
    private String vnpayOrderType;

    @Value("${booking.vnpay-locale:vn}")
    private String vnpayLocale;

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
    public BookingResponse createBooking(
            CreateBookingRequest request,
            String authenticatedUserId,
            String requestBaseUrl) {
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
        // Req 41.5 — funnel: payment_initiate
        analyticsService.logPaymentInitiate(userId, bookingId, seats.get(0).getShowtimeId(), total);

        return new BookingResponse(
                bookingId,
                booking.getStatus(),
                booking.getPaymentStatus(),
                total,
                createPaymentUrl(bookingId, total, requestBaseUrl),
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
                List.copyOf(booking.getSeatCodes()));
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
        booking.cancel(refund);
        bookingRepository.save(booking);
        releaseBookingSeats(booking);
        notificationService.sendBookingCancellation(userId, booking);
        return new CancelBookingResponse(booking.getId(), booking.getStatus(), refund, "refunded");
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
        if (request.expectedShowtimeId() != null && !request.expectedShowtimeId().isBlank()
                && !booking.getShowtimeId().equals(request.expectedShowtimeId())) {
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
        var minus24Hours = now.minus(Duration.ofHours(24));
        var plus24Hours = now.plus(Duration.ofHours(24));
        var bookingId = request.bookingId() == null ? "" : request.bookingId();
        var customerName = request.customerName() == null ? "" : request.customerName();

        var bookings = bookingRepository.searchBookingsForValidation(
                bookingId, customerName, minus24Hours, plus24Hours);
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
        // JS fetch calls confirm endpoint (updates DB), then navigates to cineluxe:// deep-link.
        // Android WebView cannot follow HTTP 302 to a custom URI scheme (ERR_UNKNOWN_URL_SCHEME).
        return """
        <!doctype html><html><head><meta name="viewport" content="width=device-width,initial-scale=1">
        <style>
        *{box-sizing:border-box;margin:0;padding:0}
        body{font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',sans-serif;background:#f5f5f5;min-height:100vh;display:flex;align-items:center;justify-content:center;padding:24px}
        main{background:white;border-radius:16px;padding:32px;max-width:420px;width:100%%;box-shadow:0 4px 24px rgba(0,0,0,.08)}
        .logo{font-size:28px;font-weight:900;color:#111;margin-bottom:4px}
        .badge{display:inline-block;background:#fff2c5;color:#a37200;font-size:11px;font-weight:700;padding:2px 8px;border-radius:99px;margin-bottom:20px}
        .info{background:#f8f8f8;border-radius:8px;padding:14px;margin-bottom:24px;font-size:14px;line-height:1.7}
        .btn{display:block;padding:16px;text-align:center;font-size:15px;font-weight:700;border-radius:10px;cursor:pointer;margin-bottom:12px;border:none;width:100%%}
        .btn-ok{background:#111;color:white}.btn-fail{background:white;color:#b42318;border:2px solid #b42318}
        </style></head>
        <body><main>
          <div class="logo">VNPay</div><span class="badge">SANDBOX</span>
          <div class="info"><div><b>Mã vé:</b> %s</div><div><b>Số tiền:</b> %,d VND</div></div>
          <button class="btn btn-ok"   onclick="pay('00')">Thanh toán thành công</button>
          <button class="btn btn-fail" onclick="pay('24')">Giả lập thất bại</button>
        </main>
        <script>
        async function pay(code){
          var s=code==='00'?'success':'failed';
          try{await fetch('/api/payments/sandbox/%s/confirm?responseCode='+code,{method:'POST'});}catch(e){}
          window.location.href='cineluxe://payment-return?bookingId=%s&status='+s+'&responseCode='+code;
        }
        </script></body></html>
        """.formatted(bookingId, booking.getTotalAmount(), bookingId, bookingId);
    }

    @Override
    public PaymentStatusResponse processPaymentReturn(Map<String, String> parameters) {
        if (parameters.containsKey("vnp_SecureHash")) {
            return processVnpayGatewayReturn(parameters);
        }
        var bookingId    = parameters.getOrDefault("bookingId", "");
        var responseCode = parameters.getOrDefault("responseCode", "");
        var transactionId = parameters.getOrDefault("transactionId", "");
        var signature    = parameters.getOrDefault("signature", "");
        var payload = callbackPayload(bookingId, responseCode, transactionId);
        if (!MessageDigest.isEqual(
                sign(payload).getBytes(StandardCharsets.UTF_8),
                signature.getBytes(StandardCharsets.UTF_8))) {
            throw new ApiException(HttpStatus.BAD_REQUEST, "Invalid sandbox callback signature");
        }
        return applyPaymentResult(bookingId, responseCode, transactionId);
    }

    private PaymentStatusResponse processVnpayGatewayReturn(Map<String, String> parameters) {
        var signedParams = new TreeMap<>(parameters);
        var receivedHash = signedParams.remove("vnp_SecureHash");
        signedParams.remove("vnp_SecureHashType");
        if (receivedHash == null || !MessageDigest.isEqual(
                sign(buildHashData(signedParams)).getBytes(StandardCharsets.UTF_8),
                receivedHash.getBytes(StandardCharsets.UTF_8))) {
            throw new ApiException(HttpStatus.BAD_REQUEST, "Invalid VNPay signature");
        }
        var bookingId     = parameters.getOrDefault("vnp_TxnRef", "");
        var responseCode  = parameters.getOrDefault("vnp_ResponseCode", "");
        var transactionId = parameters.getOrDefault("vnp_TransactionNo",
                            parameters.getOrDefault("vnp_BankTranNo", ""));
        return applyPaymentResult(bookingId, responseCode, transactionId);
    }

    @Override
    public PaymentStatusResponse confirmSandboxPayment(String bookingId, String responseCode) {
        return applyPaymentResult(bookingId, responseCode, "VNP-" + System.currentTimeMillis());
    }

    private PaymentStatusResponse applyPaymentResult(
            String bookingId, String responseCode, String transactionId) {
        var booking = requireBooking(bookingId);
        if ("pendingPayment".equals(booking.getStatus())) {
            if ("00".equals(responseCode)) {
                booking.completePayment(transactionId, responseCode);
                notificationService.sendPaymentConfirmation(booking.getUserId(), booking);
                analyticsService.logPaymentComplete(
                        booking.getUserId(), bookingId, transactionId, booking.getTotalAmount());
            } else {
                booking.failPayment(transactionId, responseCode);
                releaseBookingSeats(booking);
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
                showtimeRepository.findById(booking.getShowtimeId())
                        .map(showtime -> showtime.getMovieId())
                        .orElse(null),
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
        return stripTrailingSlash(apiBaseUrl) + "/api/payments/vnpay/return?" + payload + "&signature=" + sign(payload);
    }

    private String callbackPayload(String bookingId, String responseCode, String transactionId) {
        return "bookingId=" + bookingId + "&responseCode=" + responseCode
                + "&transactionId=" + transactionId;
    }


    private String createPaymentUrl(String bookingId, long totalAmount, String requestBaseUrl) {
        var callbackBaseUrl = resolveCallbackBaseUrl(requestBaseUrl);
        if (!isVnpayGatewayConfigured()) {
            var p = "amount=" + totalAmount + "&bookingId=" + bookingId;
            return stripTrailingSlash(callbackBaseUrl) + "/api/payments/sandbox/" + bookingId
                    + "?" + p + "&signature=" + sign(p);
        }
        var zone = ZoneId.of("Asia/Ho_Chi_Minh");
        var fmt  = DateTimeFormatter.ofPattern("yyyyMMddHHmmss");
        var now  = LocalDateTime.now(zone);
        var returnUrl = (vnpayReturnUrl == null || vnpayReturnUrl.isBlank())
                ? stripTrailingSlash(callbackBaseUrl) + "/api/payments/vnpay/return"
                : vnpayReturnUrl.trim();
        var params = new TreeMap<String, String>();
        params.put("vnp_Version",   "2.1.0");
        params.put("vnp_Command",   "pay");
        params.put("vnp_TmnCode",   vnpayTerminalId.trim());
        params.put("vnp_Amount",    String.valueOf(totalAmount * 100));
        params.put("vnp_CurrCode",  "VND");
        params.put("vnp_TxnRef",    bookingId);
        params.put("vnp_OrderInfo", "Thanh toan don hang " + bookingId);
        params.put("vnp_OrderType", vnpayOrderType);
        params.put("vnp_Locale",    vnpayLocale);
        params.put("vnp_ReturnUrl", returnUrl);
        params.put("vnp_IpAddr",    "127.0.0.1");
        params.put("vnp_CreateDate",  fmt.format(now));
        params.put("vnp_ExpireDate",  fmt.format(now.plusMinutes(15)));
        return stripTrailingSlash(vnpayPayUrl) + "?"
                + buildQueryString(params)
                + "&vnp_SecureHash=" + sign(buildHashData(params));
    }

    private boolean isVnpayGatewayConfigured() {
        return vnpayPayUrl != null && !vnpayPayUrl.isBlank()
                && vnpayTerminalId != null && !vnpayTerminalId.isBlank()
                && vnpaySecret != null && !vnpaySecret.isBlank();
    }

    private String resolveCallbackBaseUrl(String requestBaseUrl) {
        if (requestBaseUrl != null && !requestBaseUrl.isBlank()) {
            return stripTrailingSlash(requestBaseUrl);
        }
        return stripTrailingSlash(apiBaseUrl);
    }

    private String buildQueryString(Map<String, String> params) {
        return params.entrySet().stream()
                .filter(e -> e.getValue() != null && !e.getValue().isBlank())
                .map(e -> encode(e.getKey()) + "=" + encode(e.getValue()))
                .collect(Collectors.joining("&"));
    }

    private String buildHashData(Map<String, String> params) {
        return params.entrySet().stream()
                .filter(e -> e.getValue() != null && !e.getValue().isBlank())
                .map(e -> e.getKey() + "=" + encode(e.getValue()))
                .collect(Collectors.joining("&"));
    }

    private String encode(String value) {
        return URLEncoder.encode(value, StandardCharsets.UTF_8);
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
