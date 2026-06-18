package com.cineluxe.repository;

import com.cineluxe.entity.Review;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;

public interface ReviewRepository extends JpaRepository<Review, String> {

    Page<Review> findByMovieIdOrderByCreatedAtDesc(String movieId, Pageable pageable);

    boolean existsByUserIdAndMovieId(String userId, String movieId);
}
