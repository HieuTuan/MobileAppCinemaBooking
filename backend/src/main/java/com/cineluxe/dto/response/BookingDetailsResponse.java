package com.cineluxe.dto.response;

import java.time.Instant;
import java.util.List;

public record BookingDetailsResponse(
    String bookingId,
    String userId,
    String showtimeId,
    String movieTitle,
    String roomName,
    String cinemaName,
    Instant showtimeDateTime,
    List<String> seatCodes,
    List<String> combos,
    long totalAmount,
    String status,
    String paymentStatus,
    Instant createdAt,
    String qrCode
) {}
