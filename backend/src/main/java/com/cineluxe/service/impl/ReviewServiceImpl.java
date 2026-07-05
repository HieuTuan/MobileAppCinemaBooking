package com.cineluxe.service.impl;

import com.cineluxe.dto.request.CreateReviewRequest;
import com.cineluxe.dto.response.ReviewPageResponse;
import com.cineluxe.dto.response.ReviewResponse;
import com.cineluxe.entity.Review;
import com.cineluxe.exception.ApiException;
import com.cineluxe.repository.BookingRepository;
import com.cineluxe.repository.ReviewRepository;
import com.cineluxe.repository.ShowtimeRepository;
import com.cineluxe.service.ReviewService;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.PageRequest;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Optional;
import java.util.UUID;

@Service
@RequiredArgsConstructor
@Transactional
public class ReviewServiceImpl implements ReviewService {

    private final ReviewRepository reviewRepository;
    private final BookingRepository bookingRepository;
    private final ShowtimeRepository showtimeRepository;

    @Override
    public ReviewResponse createReview(CreateReviewRequest request, String authenticatedUserId) {
        var userId = (request.userId() != null && !request.userId().isBlank())
                ? request.userId()
                : authenticatedUserId;

        // Verified purchase check: user must have a "used" booking for this movie.
        if (!hasUsedBookingForMovie(userId, request.movieId())) {
            throw new ApiException(HttpStatus.FORBIDDEN,
                    "You must watch the movie before reviewing");
        }

        // Prevent duplicate reviews for the same movie
        if (reviewRepository.existsByUserIdAndMovieId(userId, request.movieId())) {
            throw new ApiException(HttpStatus.CONFLICT,
                    "You have already reviewed this movie");
        }

        var review = new Review(
                "RV-" + UUID.randomUUID(),
                userId,
                request.movieId(),
                userId,  // userName defaults to userId in demo mode
                request.comment(),
                request.rating(),
                true     // verified because they have a "used" booking
        );

        return ReviewResponse.from(reviewRepository.save(review));
    }

    @Override
    @Transactional(readOnly = true)
    public ReviewPageResponse getMovieReviews(String movieId, int page, int pageSize) {
        var pageable = PageRequest.of(page - 1, pageSize); // client sends 1-indexed
        var result = reviewRepository.findByMovieIdOrderByCreatedAtDesc(movieId, pageable);
        return new ReviewPageResponse(
                result.getContent().stream().map(ReviewResponse::from).toList(),
                page,
                pageSize,
                (int) result.getTotalElements(),
                result.getTotalPages(),
                result.hasNext(),
                result.hasPrevious()
        );
    }

    @Override
    @Transactional(readOnly = true)
    public ReviewPageResponse getAllReviews(int page, int pageSize) {
        var pageable = PageRequest.of(page - 1, pageSize);
        var result = reviewRepository.findAllByOrderByCreatedAtDesc(pageable);
        return new ReviewPageResponse(
                result.getContent().stream().map(ReviewResponse::from).toList(),
                page,
                pageSize,
                (int) result.getTotalElements(),
                result.getTotalPages(),
                result.hasNext(),
                result.hasPrevious()
        );
    }

    @Override
    public void deleteReview(String reviewId) {
        if (!reviewRepository.existsById(reviewId)) {
            throw new ApiException(HttpStatus.NOT_FOUND, "Review not found");
        }
        reviewRepository.deleteById(reviewId);
    }

    private boolean hasUsedBookingForMovie(String userId, String movieId) {
        return bookingRepository.findByUserIdAndStatusOrderByCreatedAtDesc(userId, "used")
                .stream()
                .map(booking -> showtimeRepository.findById(booking.getShowtimeId()))
                .filter(Optional::isPresent)
                .map(Optional::get)
                .anyMatch(showtime -> movieId.equals(showtime.getMovieId()));
    }
}
