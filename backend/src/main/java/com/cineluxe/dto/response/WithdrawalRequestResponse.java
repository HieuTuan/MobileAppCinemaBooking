package com.cineluxe.dto.response;

import com.cineluxe.entity.WithdrawalRequest;
import java.time.Instant;

public record WithdrawalRequestResponse(
        String id,
        String userId,
        long amount,
        String bankName,
        String accountNumber,
        String accountHolder,
        String status,
        Instant requestedAt,
        Instant processedAt,
        String processedByStaffId,
        String note,
        // Denormalized
        String userName
) {
    public static WithdrawalRequestResponse from(WithdrawalRequest w) {
        return from(w, null);
    }

    public static WithdrawalRequestResponse from(WithdrawalRequest w, String userName) {
        return new WithdrawalRequestResponse(
                w.getId(), w.getUserId(), w.getAmount(),
                w.getBankName(), w.getAccountNumber(), w.getAccountHolder(),
                w.getStatus(), w.getRequestedAt(), w.getProcessedAt(),
                w.getProcessedByStaffId(), w.getNote(), userName
        );
    }
}
