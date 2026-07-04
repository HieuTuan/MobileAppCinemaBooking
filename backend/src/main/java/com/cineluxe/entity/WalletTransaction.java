package com.cineluxe.entity;

import jakarta.persistence.*;
import java.time.Instant;

/** Lịch sử giao dịch ví điện tử */
@Entity
@Table(name = "wallet_transactions", indexes = {
    @Index(name = "idx_wtx_user",   columnList = "userId"),
    @Index(name = "idx_wtx_wallet", columnList = "walletId")
})
public class WalletTransaction {

    @Id
    private String id;

    private String walletId;
    private String userId;

    /** CREDIT | DEBIT */
    private String type;

    private long amount;
    private String description;

    /** bookingId, withdrawalId, hoặc ref tương tự */
    private String refId;

    private Instant createdAt;

    protected WalletTransaction() {}

    public WalletTransaction(String id, String walletId, String userId,
                              String type, long amount, String description, String refId) {
        this.id = id;
        this.walletId = walletId;
        this.userId = userId;
        this.type = type;
        this.amount = amount;
        this.description = description;
        this.refId = refId;
        this.createdAt = Instant.now();
    }

    // Getters
    public String getId()          { return id; }
    public String getWalletId()    { return walletId; }
    public String getUserId()      { return userId; }
    public String getType()        { return type; }
    public long getAmount()        { return amount; }
    public String getDescription() { return description; }
    public String getRefId()       { return refId; }
    public Instant getCreatedAt()  { return createdAt; }
}
