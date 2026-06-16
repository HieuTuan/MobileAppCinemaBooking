package com.cineluxe.dto.response;

import java.time.Instant;

public record BookingResponse(
    String bookingId,
    String status,
    String paymentStatus,
    long totalAmount,
    String paymentUrl,
    Instant paymentExpiresAt
) {}
