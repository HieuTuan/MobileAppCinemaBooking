package com.cineluxe.service;

import com.cineluxe.dto.response.WalletResponse;
import com.cineluxe.dto.response.WalletResponse.WalletTransactionDto;
import com.cineluxe.entity.Wallet;
import com.cineluxe.entity.WalletTransaction;
import com.cineluxe.repository.WalletRepository;
import com.cineluxe.repository.WalletTransactionRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
public class WalletService {

    private final WalletRepository walletRepo;
    private final WalletTransactionRepository txRepo;

    public WalletService(WalletRepository walletRepo, WalletTransactionRepository txRepo) {
        this.walletRepo = walletRepo;
        this.txRepo = txRepo;
    }

    /** Lấy ví (tự tạo nếu chưa có) */
    @Transactional
    public Wallet getOrCreateWallet(String userId) {
        return walletRepo.findByUserId(userId).orElseGet(() -> {
            Wallet w = new Wallet(UUID.randomUUID().toString(), userId);
            return walletRepo.save(w);
        });
    }

    /** Nạp tiền vào ví + ghi log giao dịch */
    @Transactional
    public void credit(String userId, long amount, String description, String refId) {
        Wallet wallet = getOrCreateWallet(userId);
        wallet.credit(amount);
        walletRepo.save(wallet);

        WalletTransaction tx = new WalletTransaction(
                UUID.randomUUID().toString(),
                wallet.getId(), userId,
                "CREDIT", amount, description, refId
        );
        txRepo.save(tx);
    }

    /** Trừ tiền khỏi ví + ghi log giao dịch */
    @Transactional
    public void debit(String userId, long amount, String description, String refId) {
        Wallet wallet = getOrCreateWallet(userId);
        wallet.debit(amount); // throws if insufficient
        walletRepo.save(wallet);

        WalletTransaction tx = new WalletTransaction(
                UUID.randomUUID().toString(),
                wallet.getId(), userId,
                "DEBIT", amount, description, refId
        );
        txRepo.save(tx);
    }

    /** Lấy thông tin ví + lịch sử giao dịch */
    @Transactional(readOnly = true)
    public WalletResponse getWalletInfo(String userId) {
        Wallet wallet = getOrCreateWallet(userId);
        List<WalletTransactionDto> txList = txRepo
                .findByUserIdOrderByCreatedAtDesc(userId)
                .stream()
                .map(WalletTransactionDto::from)
                .collect(Collectors.toList());
        return new WalletResponse(wallet.getId(), userId, wallet.getBalance(), txList);
    }
}
