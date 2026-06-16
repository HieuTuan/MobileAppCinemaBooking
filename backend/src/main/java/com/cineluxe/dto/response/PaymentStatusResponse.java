package com.cineluxe.dto.response;

public record PaymentStatusResponse(
    String bookingId,
    String status,
    String paymentStatus,
    String transactionId,
    String responseCode
) {}
