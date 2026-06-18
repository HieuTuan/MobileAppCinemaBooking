package com.cineluxe.controller;

import com.cineluxe.dto.request.CreateReviewRequest;
import com.cineluxe.dto.response.ApiResponse;
import com.cineluxe.dto.response.ReviewPageResponse;
import com.cineluxe.dto.response.ReviewResponse;
import com.cineluxe.service.ReviewService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api")
@RequiredArgsConstructor
@Tag(name = "Reviews", description = "Movie review management")
public class ReviewController {

    private final ReviewService reviewService;

    @PostMapping("/reviews")
    @Operation(summary = "Create a movie review")
    public ResponseEntity<ApiResponse<ReviewResponse>> createReview(
            @Valid @RequestBody CreateReviewRequest request,
            @RequestHeader(value = "X-User-Id", defaultValue = "demo-user") String userId) {
        return ApiResponse.created(reviewService.createReview(request, userId));
    }

    @GetMapping("/movies/{movieId}/reviews")
    @Operation(summary = "Get paginated reviews for a movie")
    public ResponseEntity<ApiResponse<ReviewPageResponse>> getMovieReviews(
            @PathVariable String movieId,
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "5") int pageSize) {
        return ApiResponse.success(reviewService.getMovieReviews(movieId, page, pageSize));
    }
}
