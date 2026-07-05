package com.cineluxe.repository;

import com.cineluxe.entity.Review;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.Optional;

public interface ReviewRepository extends JpaRepository<Review, String> {

    Page<Review> findByMovieIdOrderByCreatedAtDesc(String movieId, Pageable pageable);

    Page<Review> findAllByOrderByCreatedAtDesc(Pageable pageable);

    boolean existsByUserIdAndMovieId(String userId, String movieId);

    /** Tính điểm trung bình (thang 1–10) từ các review thực tế của phim. */
    @Query("SELECT AVG(r.rating) FROM Review r WHERE r.movieId = :movieId")
    Optional<Double> findAverageRatingByMovieId(@Param("movieId") String movieId);
}
