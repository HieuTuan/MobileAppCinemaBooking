package com.cineluxe.service.impl;

import com.cineluxe.dto.request.CreateReviewRequest;
import com.cineluxe.dto.response.ReviewPageResponse;
import com.cineluxe.dto.response.ReviewResponse;
import com.cineluxe.entity.Review;
import com.cineluxe.exception.ApiException;
import com.cineluxe.repository.BookingRepository;
import com.cineluxe.repository.MovieRepository;
import com.cineluxe.repository.ReviewRepository;
import com.cineluxe.repository.UserProfileRepository;
import com.cineluxe.service.ReviewService;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.PageRequest;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
@Transactional
public class ReviewServiceImpl implements ReviewService {

    private final ReviewRepository reviewRepository;
    private final BookingRepository bookingRepository;
    private final MovieRepository movieRepository;
    private final UserProfileRepository userProfileRepository;

    @Override
    public ReviewResponse createReview(CreateReviewRequest request, String authenticatedUserId) {
        var userId = (request.userId() != null && !request.userId().isBlank())
                ? request.userId()
                : authenticatedUserId;

        // Verified purchase check: user must have watched the specific movie
        if (!bookingRepository.hasUserWatchedMovie(userId, request.movieId())) {
            throw new ApiException(HttpStatus.FORBIDDEN,
                    "You must watch the movie before reviewing");
        }

        // Prevent duplicate reviews for the same movie
        if (reviewRepository.existsByUserIdAndMovieId(userId, request.movieId())) {
            throw new ApiException(HttpStatus.CONFLICT,
                    "You have already reviewed this movie");
        }

        // Lookup full name from user profile
        var profile = userProfileRepository.findById(userId).orElse(null);
        var userName = (profile != null) ? profile.getFullName() : userId;

        var review = new Review(
                "RV-" + UUID.randomUUID(),
                userId,
                request.movieId(),
                userName,
                request.comment(),
                request.rating(),
                true     // verified because they have a "used" booking
        );

        var savedReview = reviewRepository.save(review);

        // Recalculate average rating for the movie
        var movie = movieRepository.findById(request.movieId()).orElseThrow(() ->
                new ApiException(HttpStatus.NOT_FOUND, "Movie not found"));
        
        List<Review> movieReviews = reviewRepository.findByMovieId(request.movieId());
        double avg = movieReviews.stream()
                .mapToInt(Review::getRating)
                .average()
                .orElse(0.0);
        double roundedRating = Math.round(avg * 10.0) / 10.0;
        movie.setRating(roundedRating);
        movieRepository.save(movie);

        return ReviewResponse.from(savedReview);
    }

    @Override
    @Transactional(readOnly = true)
    public ReviewPageResponse getMovieReviews(String movieId, int page, int pageSize) {
        var pageable = PageRequest.of(page - 1, pageSize); // client sends 1-indexed
        var result = reviewRepository.findByMovieIdOrderByCreatedAtDesc(movieId, pageable);
        return new ReviewPageResponse(
                result.getContent().stream().map(ReviewResponse::from).toList(),
                page,
                result.getTotalPages(),
                (int) result.getTotalElements()
        );
    }
}
