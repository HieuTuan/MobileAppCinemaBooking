package com.cineluxe.repository;

import com.cineluxe.entity.Movie;
import java.util.List;
import org.springframework.data.jpa.repository.JpaRepository;

public interface MovieRepository extends JpaRepository<Movie, String> {

    /** Lấy tất cả phim theo status (comingSoon / nowShowing). */
    List<Movie> findByOrderByReleaseDateDesc();
}
