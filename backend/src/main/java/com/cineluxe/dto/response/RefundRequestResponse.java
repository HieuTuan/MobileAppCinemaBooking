package com.cineluxe.dto.response;

import com.cineluxe.entity.RefundRequest;
import java.time.Instant;

public record RefundRequestResponse(
        String id,
        String bookingId,
        String userId,
        long refundAmount,
        String status,
        Instant requestedAt,
        Instant processedAt,
        String processedByStaffId,
        String reason,
        // Denormalized for display
        String movieTitle,
        String seatCodes
) {
    public static RefundRequestResponse from(RefundRequest r) {
        return new RefundRequestResponse(
                r.getId(), r.getBookingId(), r.getUserId(),
                r.getRefundAmount(), r.getStatus(),
                r.getRequestedAt(), r.getProcessedAt(),
                r.getProcessedByStaffId(), r.getReason(),
                null, null
        );
    }

    public static RefundRequestResponse from(RefundRequest r, String movieTitle, String seatCodes) {
        return new RefundRequestResponse(
                r.getId(), r.getBookingId(), r.getUserId(),
                r.getRefundAmount(), r.getStatus(),
                r.getRequestedAt(), r.getProcessedAt(),
                r.getProcessedByStaffId(), r.getReason(),
                movieTitle, seatCodes
        );
    }
}
