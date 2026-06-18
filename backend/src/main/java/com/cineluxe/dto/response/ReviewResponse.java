package com.cineluxe.dto.response;

import com.cineluxe.entity.Review;
import java.time.Instant;

public record ReviewResponse(
    String id,
    String userId,
    String userName,
    String movieId,
    int rating,
    String comment,
    boolean isVerified,
    Instant createdAt
) {
    public static ReviewResponse from(Review r) {
        return new ReviewResponse(
            r.getId(),
            r.getUserId(),
            r.getUserName(),
            r.getMovieId(),
            r.getRating(),
            r.getComment(),
            r.isVerified(),
            r.getCreatedAt()
        );
    }
}
