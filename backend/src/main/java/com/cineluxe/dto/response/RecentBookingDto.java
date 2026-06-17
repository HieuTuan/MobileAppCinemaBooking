package com.cineluxe.dto.response;

import java.time.Instant;

public record RecentBookingDto(
    String bookingId, String customerName, String movieTitle,
    long totalAmount, String status, Instant createdAt
) {}
