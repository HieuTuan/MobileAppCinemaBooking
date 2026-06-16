package com.cineluxe.dto.response;

import java.time.Instant;
import java.util.List;

public record ValidationResult(
    boolean success,
    String status,
    String message,
    String bookingId,
    String customerName,
    String movieTitle,
    String showtimeId,
    Instant showtimeDateTime,
    List<String> seatCodes,
    Instant validatedAt
) {}
