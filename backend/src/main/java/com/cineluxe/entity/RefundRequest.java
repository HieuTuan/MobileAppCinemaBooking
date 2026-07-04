package com.cineluxe.entity;

import jakarta.persistence.*;
import java.time.Instant;

/**
 * Yêu cầu hoàn tiền từ khách hàng.
 * Status lifecycle: PENDING → APPROVED | REJECTED
 */
@Entity
@Table(name = "refund_requests", indexes = {
    @Index(name = "idx_refund_booking", columnList = "bookingId"),
    @Index(name = "idx_refund_user",    columnList = "userId"),
    @Index(name = "idx_refund_status",  columnList = "status")
})
public class RefundRequest {

    @Id
    private String id;

    private String bookingId;
    private String userId;
    private long refundAmount;

    /** PENDING | APPROVED | REJECTED */
    private String status;

    private Instant requestedAt;
    private Instant processedAt;
    private String processedByStaffId;
    private String reason;

    protected RefundRequest() {}

    public RefundRequest(String id, String bookingId, String userId, long refundAmount) {
        this.id = id;
        this.bookingId = bookingId;
        this.userId = userId;
        this.refundAmount = refundAmount;
        this.status = "PENDING";
        this.requestedAt = Instant.now();
    }

    public void approve(String staffId) {
        this.status = "APPROVED";
        this.processedAt = Instant.now();
        this.processedByStaffId = staffId;
    }

    public void reject(String staffId, String reason) {
        this.status = "REJECTED";
        this.processedAt = Instant.now();
        this.processedByStaffId = staffId;
        this.reason = reason;
    }

    // Getters
    public String getId()                  { return id; }
    public String getBookingId()           { return bookingId; }
    public String getUserId()              { return userId; }
    public long getRefundAmount()          { return refundAmount; }
    public String getStatus()              { return status; }
    public Instant getRequestedAt()        { return requestedAt; }
    public Instant getProcessedAt()        { return processedAt; }
    public String getProcessedByStaffId()  { return processedByStaffId; }
    public String getReason()              { return reason; }
}
