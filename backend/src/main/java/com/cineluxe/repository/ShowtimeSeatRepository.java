package com.cineluxe.repository;

import com.cineluxe.entity.SeatStatus;
import com.cineluxe.entity.ShowtimeSeat;
import jakarta.persistence.LockModeType;
import java.time.Instant;
import java.util.Collection;
import java.util.List;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface ShowtimeSeatRepository extends JpaRepository<ShowtimeSeat, Long> {
  List<ShowtimeSeat> findByShowtimeIdOrderBySeatRowAscSeatColumnAsc(String showtimeId);

  @Lock(LockModeType.PESSIMISTIC_WRITE)
  @Query("select s from ShowtimeSeat s where s.showtimeId = :showtimeId and s.code in :codes")
  List<ShowtimeSeat> lockSeats(
      @Param("showtimeId") String showtimeId,
      @Param("codes") Collection<String> codes);

  @Lock(LockModeType.PESSIMISTIC_WRITE)
  List<ShowtimeSeat> findByHoldId(String holdId);

  @Lock(LockModeType.PESSIMISTIC_WRITE)
  List<ShowtimeSeat> findByShowtimeIdAndHeldByUserId(String showtimeId, String userId);

  List<ShowtimeSeat> findByStatusAndHoldExpiresAtBefore(SeatStatus status, Instant now);
}
