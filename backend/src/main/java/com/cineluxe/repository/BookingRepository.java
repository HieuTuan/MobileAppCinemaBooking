package com.cineluxe.repository;

import com.cineluxe.domain.Booking;
import java.time.Instant;
import java.util.List;
import org.springframework.data.jpa.repository.JpaRepository;

public interface BookingRepository extends JpaRepository<Booking, String> {
  List<Booking> findByUserIdOrderByCreatedAtDesc(String userId);
  List<Booking> findByUserIdAndStatusOrderByCreatedAtDesc(String userId, String status);
  List<Booking> findByStatusAndPaymentExpiresAtBefore(String status, Instant now);
}
