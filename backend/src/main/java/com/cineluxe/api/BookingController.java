package com.cineluxe.api;

import static com.cineluxe.api.ApiDtos.*;

import com.cineluxe.service.BookingService;
import jakarta.validation.Valid;
import java.util.List;
import java.util.Map;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api")
public class BookingController {
  private final BookingService bookingService;

  public BookingController(BookingService bookingService) {
    this.bookingService = bookingService;
  }

  @GetMapping("/showtimes/{showtimeId}/seats")
  SeatMapResponse getSeats(@PathVariable String showtimeId) {
    return bookingService.getSeats(showtimeId);
  }

  @PostMapping("/showtimes/{showtimeId}/seats/hold")
  HoldResponse holdSeats(
      @PathVariable String showtimeId,
      @Valid @RequestBody HoldRequest request,
      @RequestHeader(value = "X-User-Id", defaultValue = "demo-user") String userId) {
    return bookingService.holdSeats(showtimeId, request, userId);
  }

  @GetMapping("/food-combos")
  List<ComboDto> getFoodCombos() {
    return bookingService.getCombos();
  }

  @PostMapping("/bookings")
  @ResponseStatus(HttpStatus.CREATED)
  BookingResponse createBooking(
      @Valid @RequestBody CreateBookingRequest request,
      @RequestHeader(value = "X-User-Id", defaultValue = "demo-user") String userId) {
    return bookingService.createBooking(request, userId);
  }

  @GetMapping("/bookings/{bookingId}")
  BookingDetailsResponse getBooking(@PathVariable String bookingId) {
    return bookingService.getBooking(bookingId);
  }

  @GetMapping("/users/{userId}/bookings")
  List<BookingDetailsResponse> getUserBookings(
      @PathVariable String userId,
      @RequestParam(required = false) String status) {
    return bookingService.getUserBookings(userId, status);
  }

  @GetMapping("/bookings/{bookingId}/qr")
  BookingQrResponse getBookingQr(@PathVariable String bookingId) {
    return bookingService.getBookingQr(bookingId);
  }

  @PostMapping("/bookings/{bookingId}/cancel")
  CancelBookingResponse cancelBooking(
      @PathVariable String bookingId,
      @RequestBody(required = false) CancelBookingRequest request,
      @RequestHeader(value = "X-User-Id", defaultValue = "demo-user") String userId) {
    return bookingService.cancelBooking(bookingId, request, userId);
  }

  @PostMapping("/bookings/{bookingId}/validate")
  ValidationResult validateTicket(
      @PathVariable String bookingId,
      @Valid @RequestBody ValidateTicketRequest request,
      @RequestHeader(value = "X-Staff-Id", defaultValue = "demo-staff") String staffId) {
    return bookingService.validateTicket(bookingId, request, staffId);
  }

  @GetMapping("/bookings/{bookingId}/payment-status")
  PaymentStatusResponse getPaymentStatus(@PathVariable String bookingId) {
    return bookingService.getPaymentStatus(bookingId);
  }

  @GetMapping(value = "/payments/sandbox/{bookingId}", produces = MediaType.TEXT_HTML_VALUE)
  String sandboxPaymentPage(@PathVariable String bookingId) {
    return bookingService.sandboxPaymentPage(bookingId);
  }

  @GetMapping("/payments/vnpay/return")
  ResponseEntity<Void> vnpayReturn(@RequestParam Map<String, String> parameters) {
    var result = bookingService.processPaymentReturn(parameters);
    return ResponseEntity.status(HttpStatus.FOUND)
        .location(java.net.URI.create(
            "cineluxe://payment-return?bookingId=" + result.bookingId()
                + "&status=" + result.paymentStatus()
                + "&responseCode=" + result.responseCode()))
        .build();
  }
}
