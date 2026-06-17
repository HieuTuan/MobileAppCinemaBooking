package com.cineluxe.dto.response;

import java.util.List;

public record ReviewPageResponse(
    List<ReviewResponse> data,
    int page,
    int totalPages,
    int totalItems
) {}
