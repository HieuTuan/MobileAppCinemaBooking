package com.cineluxe.repository;

import com.cineluxe.entity.Showtime;
import org.springframework.data.jpa.repository.JpaRepository;

public interface ShowtimeRepository extends JpaRepository<Showtime, String> {

    /**
     * Check nếu phim có showtime chưa bị cancel → dùng cho 409 khi xoá phim (R19-5).
     */
    boolean existsByMovieIdAndStatusNot(String movieId, String status);
}
