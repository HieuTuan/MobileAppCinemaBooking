package com.cineluxe.repository;

import com.cineluxe.entity.WithdrawalRequest;
import java.util.List;
import org.springframework.data.jpa.repository.JpaRepository;

public interface WithdrawalRequestRepository extends JpaRepository<WithdrawalRequest, String> {
    List<WithdrawalRequest> findByStatusOrderByRequestedAtDesc(String status);
    List<WithdrawalRequest> findByUserIdOrderByRequestedAtDesc(String userId);
    List<WithdrawalRequest> findAllByOrderByRequestedAtDesc();
}
