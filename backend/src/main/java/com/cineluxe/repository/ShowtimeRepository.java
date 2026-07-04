package com.cineluxe.repository;

import com.cineluxe.entity.Showtime;
import java.time.Instant;
import java.util.List;
import org.springframework.data.jpa.repository.JpaRepository;

public interface ShowtimeRepository extends JpaRepository<Showtime, String> {

    List<Showtime> findByMovieIdAndStatusNotOrderByStartTimeAsc(String movieId, String status);

    List<Showtime> findByStatusNotOrderByStartTimeAsc(String status);

    List<Showtime> findByStatusAndEndTimeBefore(String status, Instant endTime);

    /**
     * Check nếu phim có showtime chưa bị cancel → dùng cho 409 khi xoá phim (R19-5).
     */
    boolean existsByMovieIdAndStatusNot(String movieId, String status);
}
