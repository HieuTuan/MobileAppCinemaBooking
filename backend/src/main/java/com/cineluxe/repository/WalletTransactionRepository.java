package com.cineluxe.repository;

import com.cineluxe.entity.WalletTransaction;
import java.util.List;
import org.springframework.data.jpa.repository.JpaRepository;

public interface WalletTransactionRepository extends JpaRepository<WalletTransaction, String> {
    List<WalletTransaction> findByUserIdOrderByCreatedAtDesc(String userId);
    List<WalletTransaction> findByWalletIdOrderByCreatedAtDesc(String walletId);
}
