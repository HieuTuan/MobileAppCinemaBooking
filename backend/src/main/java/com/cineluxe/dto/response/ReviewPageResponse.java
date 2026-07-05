package com.cineluxe.dto.response;

import java.util.List;

public record ReviewPageResponse(
    List<ReviewResponse> data,
    int page,
    int pageSize,
    int totalItems,
    int totalPages,
    boolean hasNext,
    boolean hasPrevious
) {}
