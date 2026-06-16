package com.cineluxe.service;

import com.cineluxe.dto.request.CancelBookingRequest;
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
import com.cineluxe.dto.response.SeatMapResponse;
import com.cineluxe.dto.response.ValidationResult;
import java.util.List;
import java.util.Map;

/**
 * Service interface for cinema booking operations.
 * Handles seat management, booking lifecycle, payments, and ticket validation.
 */
public interface BookingService {

    // ─── Seat operations ────────────────────────────────────────────────

    /** Get the seat map for a specific showtime. */
    SeatMapResponse getSeats(String showtimeId);

    /** Hold seats for a user in the given showtime. */
    HoldResponse holdSeats(String showtimeId, HoldRequest request, String authenticatedUserId);

    // ─── Combo operations ───────────────────────────────────────────────

    /** Get all active food combos. */
    List<ComboDto> getCombos();

    // ─── Booking operations ─────────────────────────────────────────────

    /** Create a new booking from held seats. */
    BookingResponse createBooking(CreateBookingRequest request, String authenticatedUserId);

    /** Get booking details by booking ID. */
    BookingDetailsResponse getBooking(String bookingId);

    /** Get all bookings for a user, optionally filtered by status. */
    List<BookingDetailsResponse> getUserBookings(String userId, String status);

    /** Get QR code for an active booking. */
    BookingQrResponse getBookingQr(String bookingId);

    /** Cancel a booking and process refund. */
    CancelBookingResponse cancelBooking(String bookingId, CancelBookingRequest request, String authenticatedUserId);

    // ─── Ticket validation ──────────────────────────────────────────────

    /** Validate a ticket at the cinema entrance. */
    ValidationResult validateTicket(String bookingId, ValidateTicketRequest request, String authenticatedStaffId);

    /** Search bookings for staff manual validation (within 24 hours). */
    List<BookingSearchResult> searchBookings(SearchBookingsRequest request);

    /** Manual validation by staff from search results. */
    ValidationResult staffManualValidate(String bookingId, String staffId);

    // ─── Payment operations ─────────────────────────────────────────────

    /** Get payment status for a booking. */
    PaymentStatusResponse getPaymentStatus(String bookingId);

    /** Generate the sandbox payment HTML page. */
    String sandboxPaymentPage(String bookingId);

    /** Process the VNPay payment return callback. */
    PaymentStatusResponse processPaymentReturn(Map<String, String> parameters);
}
