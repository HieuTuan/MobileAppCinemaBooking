package com.cineluxe.dto.response;

public record CancelBookingResponse(
    String bookingId,
    String status,
    long refundAmount,
    String refundStatus
) {}
