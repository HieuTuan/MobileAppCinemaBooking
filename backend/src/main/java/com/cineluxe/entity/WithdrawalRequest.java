package com.cineluxe.entity;

import jakarta.persistence.*;
import java.time.Instant;

/**
 * Yêu cầu rút tiền từ ví về tài khoản ngân hàng.
 * Status lifecycle: PENDING → PROCESSING → COMPLETED | REJECTED
 */
@Entity
@Table(name = "withdrawal_requests", indexes = {
    @Index(name = "idx_withdrawal_user",   columnList = "userId"),
    @Index(name = "idx_withdrawal_status", columnList = "status")
})
public class WithdrawalRequest {

    @Id
    private String id;

    private String userId;
    private long amount;

    // Bank info
    private String bankName;
    private String accountNumber;
    private String accountHolder;

    /** PENDING | PROCESSING | COMPLETED | REJECTED */
    private String status;

    private Instant requestedAt;
    private Instant processedAt;
    private String processedByStaffId;
    private String note;

    protected WithdrawalRequest() {}

    public WithdrawalRequest(String id, String userId, long amount,
                              String bankName, String accountNumber, String accountHolder) {
        this.id = id;
        this.userId = userId;
        this.amount = amount;
        this.bankName = bankName;
        this.accountNumber = accountNumber;
        this.accountHolder = accountHolder;
        this.status = "PENDING";
        this.requestedAt = Instant.now();
    }

    public void markCompleted(String staffId) {
        this.status = "COMPLETED";
        this.processedAt = Instant.now();
        this.processedByStaffId = staffId;
    }

    public void markRejected(String staffId, String note) {
        this.status = "REJECTED";
        this.processedAt = Instant.now();
        this.processedByStaffId = staffId;
        this.note = note;
    }

    // Getters
    public String getId()                 { return id; }
    public String getUserId()             { return userId; }
    public long getAmount()               { return amount; }
    public String getBankName()           { return bankName; }
    public String getAccountNumber()      { return accountNumber; }
    public String getAccountHolder()      { return accountHolder; }
    public String getStatus()             { return status; }
    public Instant getRequestedAt()       { return requestedAt; }
    public Instant getProcessedAt()       { return processedAt; }
    public String getProcessedByStaffId() { return processedByStaffId; }
    public String getNote()               { return note; }
}
