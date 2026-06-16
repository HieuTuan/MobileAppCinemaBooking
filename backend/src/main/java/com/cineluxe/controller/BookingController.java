package com.cineluxe.controller;

import com.cineluxe.dto.request.CancelBookingRequest;
import com.cineluxe.dto.request.CreateBookingRequest;
import com.cineluxe.dto.request.HoldRequest;
import com.cineluxe.dto.request.SearchBookingsRequest;
import com.cineluxe.dto.request.StaffValidationRequest;
import com.cineluxe.dto.request.ValidateTicketRequest;
import static com.cineluxe.dto.response.ApiResponse.success;
import static com.cineluxe.dto.response.ApiResponse.created;
import com.cineluxe.dto.response.ApiResponse;
import com.cineluxe.dto.response.BookingDetailsResponse;
import com.cineluxe.dto.response.BookingQrResponse;
import com.cineluxe.dto.response.BookingResponse;
import com.cineluxe.dto.response.BookingSearchResult;
import com.cineluxe.dto.response.CancelBookingResponse;
import com.cineluxe.dto.response.ComboDto;
import com.cineluxe.dto.response.HoldResponse;
import com.cineluxe.dto.response.PaymentStatusResponse;
import com.cineluxe.dto.response.SeatMapResponse;
import com.cineluxe.dto.response.ValidationResult;
import com.cineluxe.service.BookingService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.media.Content;
import io.swagger.v3.oas.annotations.responses.ApiResponses;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api")
@RequiredArgsConstructor
@Tag(name = "Booking", description = "Cinema Booking Management APIs")
public class BookingController {

    private final BookingService bookingService;

    @Operation(summary = "Get seat map for a showtime",
            description = "Retrieve all seats and their current status for a specific showtime")
    @ApiResponses(value = {
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "200", description = "Successfully retrieved seat map"),
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "404", description = "Showtime not found",
                    content = @Content)
    })
    @GetMapping("/showtimes/{showtimeId}/seats")
    public ResponseEntity<ApiResponse<SeatMapResponse>> getSeats(
            @Parameter(description = "Showtime ID") @PathVariable String showtimeId) {
        return success(bookingService.getSeats(showtimeId));
    }

    @Operation(summary = "Hold seats for booking",
            description = "Temporarily hold selected seats for a user during the booking process")
    @ApiResponses(value = {
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "200", description = "Seats held successfully"),
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "400", description = "Seats are not available or invalid request",
                    content = @Content),
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "404", description = "Showtime not found",
                    content = @Content)
    })
    @PostMapping("/showtimes/{showtimeId}/seats/hold")
    public ResponseEntity<ApiResponse<HoldResponse>> holdSeats(
            @Parameter(description = "Showtime ID") @PathVariable String showtimeId,
            @Valid @RequestBody HoldRequest request,
            @RequestHeader(value = "X-User-Id", defaultValue = "demo-user") String userId) {
        return success(bookingService.holdSeats(showtimeId, request, userId));
    }

    @Operation(summary = "Get all food combos",
            description = "Retrieve list of available food and beverage combos")
    @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "200", description = "Successfully retrieved food combos")
    @GetMapping("/food-combos")
    public ResponseEntity<ApiResponse<List<ComboDto>>> getFoodCombos() {
        return success(bookingService.getCombos());
    }

    @Operation(summary = "Create a new booking",
            description = "Create a new cinema ticket booking with selected seats and combos")
    @ApiResponses(value = {
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "201", description = "Booking created successfully"),
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "400", description = "Invalid booking request or seats unavailable",
                    content = @Content)
    })
    @PostMapping("/bookings")
    public ResponseEntity<ApiResponse<BookingResponse>> createBooking(
            @Valid @RequestBody CreateBookingRequest request,
            @RequestHeader(value = "X-User-Id", defaultValue = "demo-user") String userId) {
        return created(bookingService.createBooking(request, userId));
    }

    @Operation(summary = "Get booking details",
            description = "Retrieve detailed information about a specific booking")
    @ApiResponses(value = {
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "200", description = "Successfully retrieved booking details"),
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "404", description = "Booking not found",
                    content = @Content)
    })
    @GetMapping("/bookings/{bookingId}")
    public ResponseEntity<ApiResponse<BookingDetailsResponse>> getBooking(
            @Parameter(description = "Booking ID") @PathVariable String bookingId) {
        return success(bookingService.getBooking(bookingId));
    }

    @Operation(summary = "Get user's bookings",
            description = "Retrieve all bookings for a specific user with optional status filter")
    @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "200", description = "Successfully retrieved user bookings")
    @GetMapping("/users/{userId}/bookings")
    public ResponseEntity<ApiResponse<List<BookingDetailsResponse>>> getUserBookings(
            @Parameter(description = "User ID") @PathVariable String userId,
            @Parameter(description = "Filter by booking status (optional)") @RequestParam(required = false) String status) {
        return success(bookingService.getUserBookings(userId, status));
    }

    @Operation(summary = "Get booking QR code",
            description = "Retrieve QR code for a booking to use at cinema entry")
    @ApiResponses(value = {
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "200", description = "Successfully retrieved QR code"),
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "404", description = "Booking not found",
                    content = @Content)
    })
    @GetMapping("/bookings/{bookingId}/qr")
    public ResponseEntity<ApiResponse<BookingQrResponse>> getBookingQr(
            @Parameter(description = "Booking ID") @PathVariable String bookingId) {
        return success(bookingService.getBookingQr(bookingId));
    }

    @Operation(summary = "Cancel a booking",
            description = "Cancel an existing booking and release held seats")
    @ApiResponses(value = {
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "200", description = "Booking cancelled successfully"),
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "400", description = "Cannot cancel booking (e.g., already used)",
                    content = @Content),
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "404", description = "Booking not found",
                    content = @Content)
    })
    @PostMapping("/bookings/{bookingId}/cancel")
    public ResponseEntity<ApiResponse<CancelBookingResponse>> cancelBooking(
            @Parameter(description = "Booking ID") @PathVariable String bookingId,
            @RequestBody(required = false) CancelBookingRequest request,
            @RequestHeader(value = "X-User-Id", defaultValue = "demo-user") String userId) {
        return success(bookingService.cancelBooking(bookingId, request, userId));
    }

    @Operation(summary = "Validate ticket for entry",
            description = "Staff validates a ticket QR code for cinema entry")
    @ApiResponses(value = {
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "200", description = "Ticket validation result"),
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "400", description = "Invalid validation request",
                    content = @Content),
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "404", description = "Booking not found",
                    content = @Content)
    })
    @PostMapping("/bookings/{bookingId}/validate")
    public ResponseEntity<ApiResponse<ValidationResult>> validateTicket(
            @Parameter(description = "Booking ID") @PathVariable String bookingId,
            @Valid @RequestBody ValidateTicketRequest request,
            @RequestHeader(value = "X-Staff-Id", defaultValue = "demo-staff") String staffId) {
        return success(bookingService.validateTicket(bookingId, request, staffId));
    }

    @Operation(summary = "Search bookings for staff validation",
            description = "Search active bookings within 24 hours by booking ID or customer name for manual validation")
    @ApiResponses(value = {
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "200", description = "Search results retrieved successfully"),
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "400", description = "Invalid search parameters",
                    content = @Content)
    })
    @GetMapping("/staff/bookings/search")
    public ResponseEntity<ApiResponse<List<BookingSearchResult>>> searchBookings(
            @Parameter(description = "Booking ID to search (optional, partial match supported)")
            @RequestParam(required = false) String bookingId,
            @Parameter(description = "Customer name/ID to search (optional, partial match supported)")
            @RequestParam(required = false) String customerName) {
        return success(bookingService.searchBookings(new SearchBookingsRequest(bookingId, customerName)));
    }

    @Operation(summary = "Staff manual validation from search",
            description = "Manually validate a ticket from search results. Applies same rules as QR validation.")
    @ApiResponses(value = {
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "200", description = "Ticket validated successfully"),
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "400", description = "Validation window closed or invalid booking",
                    content = @Content),
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "404", description = "Booking not found",
                    content = @Content),
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "409", description = "Ticket already validated or cancelled",
                    content = @Content)
    })
    @PostMapping("/staff/bookings/{bookingId}/validate")
    public ResponseEntity<ApiResponse<ValidationResult>> staffManualValidate(
            @Parameter(description = "Booking ID") @PathVariable String bookingId,
            @Valid @RequestBody StaffValidationRequest request) {
        return success(bookingService.staffManualValidate(bookingId, request.staffId()));
    }

    @Operation(summary = "Get payment status",
            description = "Check the current payment status of a booking")
    @ApiResponses(value = {
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "200", description = "Successfully retrieved payment status"),
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "404", description = "Booking not found",
                    content = @Content)
    })
    @GetMapping("/bookings/{bookingId}/payment-status")
    public ResponseEntity<ApiResponse<PaymentStatusResponse>> getPaymentStatus(
            @Parameter(description = "Booking ID") @PathVariable String bookingId) {
        return success(bookingService.getPaymentStatus(bookingId));
    }

    @Operation(summary = "Sandbox payment page",
            description = "Get HTML page for sandbox payment testing (development only)")
    @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "200", description = "HTML payment page",
            content = @Content(mediaType = MediaType.TEXT_HTML_VALUE))
    @GetMapping(value = "/payments/sandbox/{bookingId}", produces = MediaType.TEXT_HTML_VALUE)
    public String sandboxPaymentPage(
            @Parameter(description = "Booking ID") @PathVariable String bookingId) {
        return bookingService.sandboxPaymentPage(bookingId);
    }

    @Operation(summary = "VNPay payment return",
            description = "Handle VNPay payment gateway return callback")
    @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "302", description = "Redirect to app with payment result")
    @GetMapping("/payments/vnpay/return")
    public ResponseEntity<Void> vnpayReturn(@RequestParam Map<String, String> parameters) {
        var result = bookingService.processPaymentReturn(parameters);
        return ResponseEntity.status(HttpStatus.FOUND)
                .location(java.net.URI.create(
                        "cineluxe://payment-return?bookingId=" + result.bookingId()
                                + "&status=" + result.paymentStatus()
                                + "&responseCode=" + result.responseCode()))
                .build();
    }
}
