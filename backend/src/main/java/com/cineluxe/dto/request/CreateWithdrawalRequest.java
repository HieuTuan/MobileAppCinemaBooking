package com.cineluxe.dto.request;

public record CreateWithdrawalRequest(
        long amount,
        String bankName,
        String accountNumber,
        String accountHolder
) {}
