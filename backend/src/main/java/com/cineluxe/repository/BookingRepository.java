package com.cineluxe.repository;

import com.cineluxe.entity.Booking;
import java.time.Instant;
import java.util.List;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;

public interface BookingRepository extends JpaRepository<Booking, String> {
  List<Booking> findByUserIdOrderByCreatedAtDesc(String userId);
  List<Booking> findByUserIdAndStatusOrderByCreatedAtDesc(String userId, String status);
  List<Booking> findByStatusAndPaymentExpiresAtBefore(String status, Instant now);

  @Query("SELECT b FROM Booking b WHERE b.userId = :userId " +
      "AND (:status IS NULL OR b.status = :status) " +
      "AND (cast(:startDate as timestamp) IS NULL OR b.createdAt >= :startDate) " +
      "AND (cast(:endDate as timestamp) IS NULL OR b.createdAt <= :endDate)")
  Page<Booking> findUserBookingsWithFilters(
      @Param("userId") String userId,
      @Param("status") String status,
      @Param("startDate") Instant startDate,
      @Param("endDate") Instant endDate,
      Pageable pageable);

  boolean existsByUserIdAndStatus(String userId, String status);

  /**
   * Search bookings by booking ID and/or customer name, limited to showtimes within 24 hours.
   * Used by staff for manual ticket validation lookup.
   */
  @Query("SELECT b FROM Booking b WHERE " +
      "(:bookingId IS NULL OR :bookingId = '' OR LOWER(b.id) LIKE LOWER(CONCAT('%', :bookingId, '%'))) AND " +
      "(:customerName IS NULL OR :customerName = '' OR LOWER(b.userId) LIKE LOWER(CONCAT('%', :customerName, '%'))) AND " +
      "b.showtimeDateTime BETWEEN :now AND :plus24Hours AND " +
      "b.status = 'active' " +
      "ORDER BY b.showtimeDateTime ASC")
  List<Booking> searchBookingsForValidation(
      @Param("bookingId") String bookingId,
      @Param("customerName") String customerName,
      @Param("now") Instant now,
      @Param("plus24Hours") Instant plus24Hours);

  /**
   * Lấy toàn bộ vé active trong khoảng thời gian offline-sync.
   * Dùng cho app nhân viên cache dữ liệu offline.
   * Chỉ trả về các vé có thể được validate (active + trong cửa sổ validate).
   */
  @Query("SELECT b FROM Booking b WHERE " +
      "b.status = 'active' " +
      "AND b.showtimeDateTime BETWEEN :windowStart AND :windowEnd " +
      "ORDER BY b.showtimeDateTime ASC")
  List<Booking> findActiveBookingsForOfflineSync(
      @Param("windowStart") Instant windowStart,
      @Param("windowEnd") Instant windowEnd);
}
