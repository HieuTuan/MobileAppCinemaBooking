package com.cineluxe.service;

import com.cineluxe.dto.request.CreateReviewRequest;
import com.cineluxe.dto.response.ReviewPageResponse;
import com.cineluxe.dto.response.ReviewResponse;

public interface ReviewService {

    ReviewResponse createReview(CreateReviewRequest request, String authenticatedUserId);

    ReviewPageResponse getMovieReviews(String movieId, int page, int pageSize);

    ReviewPageResponse getAllReviews(int page, int pageSize);

    void deleteReview(String reviewId);
}
