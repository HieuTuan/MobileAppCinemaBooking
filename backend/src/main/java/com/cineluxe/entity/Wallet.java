package com.cineluxe.entity;

import jakarta.persistence.*;
import java.time.Instant;

/** Ví điện tử của khách hàng — balance tính bằng VND */
@Entity
@Table(name = "wallets", indexes = {
    @Index(name = "idx_wallet_user", columnList = "userId", unique = true)
})
public class Wallet {

    @Id
    private String id;

    @Column(unique = true, nullable = false)
    private String userId;

    private long balance; // VND, không âm

    private Instant createdAt;
    private Instant updatedAt;

    protected Wallet() {}

    public Wallet(String id, String userId) {
        this.id = id;
        this.userId = userId;
        this.balance = 0;
        this.createdAt = Instant.now();
        this.updatedAt = Instant.now();
    }

    public void credit(long amount) {
        if (amount <= 0) throw new IllegalArgumentException("Credit amount must be positive");
        this.balance += amount;
        this.updatedAt = Instant.now();
    }

    public void debit(long amount) {
        if (amount <= 0) throw new IllegalArgumentException("Debit amount must be positive");
        if (this.balance < amount) throw new IllegalStateException("Insufficient wallet balance");
        this.balance -= amount;
        this.updatedAt = Instant.now();
    }

    // Getters
    public String getId()        { return id; }
    public String getUserId()    { return userId; }
    public long getBalance()     { return balance; }
    public Instant getCreatedAt() { return createdAt; }
    public Instant getUpdatedAt() { return updatedAt; }
}
