package com.cineluxe.dto.response;

import com.cineluxe.entity.WalletTransaction;
import java.time.Instant;
import java.util.List;

public record WalletResponse(
        String walletId,
        String userId,
        long balance,
        List<WalletTransactionDto> transactions
) {
    public record WalletTransactionDto(
            String id,
            String type,
            long amount,
            String description,
            String refId,
            Instant createdAt
    ) {
        public static WalletTransactionDto from(WalletTransaction t) {
            return new WalletTransactionDto(
                    t.getId(), t.getType(), t.getAmount(),
                    t.getDescription(), t.getRefId(), t.getCreatedAt()
            );
        }
    }
}
