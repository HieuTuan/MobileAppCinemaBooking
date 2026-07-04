package com.cineluxe.repository;

import com.cineluxe.entity.RefundRequest;
import java.util.List;
import org.springframework.data.jpa.repository.JpaRepository;

public interface RefundRequestRepository extends JpaRepository<RefundRequest, String> {
    List<RefundRequest> findByStatusOrderByRequestedAtDesc(String status);
    List<RefundRequest> findAllByOrderByRequestedAtDesc();
    List<RefundRequest> findByUserIdOrderByRequestedAtDesc(String userId);
    boolean existsByBookingIdAndStatus(String bookingId, String status);
}
