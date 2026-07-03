package com.cineluxe.dto.response;

import java.util.List;

/**
 * Paginated response for bookings, matching Flutter's PaginatedResponse<BookingDetails> model.
 */
public record PagedBookingResponse(
        List<BookingDetailsResponse> data,
        int page,
        int pageSize,
        long totalItems,
        int totalPages,
        boolean hasNext,
        boolean hasPrevious
) {
    public static PagedBookingResponse from(
            org.springframework.data.domain.Page<BookingDetailsResponse> springPage,
            int requestedPage) {

        int total = (int) springPage.getTotalElements();
        int size = springPage.getSize();
        int totalPages = springPage.getTotalPages() == 0 ? 1 : springPage.getTotalPages();

        return new PagedBookingResponse(
                springPage.getContent(),
                requestedPage,
                size,
                total,
                totalPages,
                springPage.hasNext(),
                springPage.hasPrevious()
        );
    }
}
