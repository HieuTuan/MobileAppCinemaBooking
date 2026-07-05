package com.cineluxe.dto.request;

import jakarta.validation.constraints.*;

public record CreateReviewRequest(
    @NotBlank String userId,
    @NotBlank String movieId,
    @Min(1) @Max(10) int rating,
    @NotBlank @Size(min = 10, max = 500) String comment
) {}
