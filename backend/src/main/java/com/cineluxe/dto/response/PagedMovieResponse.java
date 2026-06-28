package com.cineluxe.dto.response;

import java.util.List;

/**
 * Phản hồi phân trang cho danh sách phim (Req R3.8).
 *
 * <p>Khớp với Flutter {@code PaginatedResponse<Movie>} model:
 * <pre>
 * {
 *   "data":        [...],
 *   "page":        1,
 *   "pageSize":    20,
 *   "totalItems":  100,
 *   "totalPages":  5,
 *   "hasNext":     true,
 *   "hasPrevious": false
 * }
 * </pre>
 */
public record PagedMovieResponse(
        List<MovieResponse> data,
        int  page,
        int  pageSize,
        long totalItems,
        int  totalPages,
        boolean hasNext,
        boolean hasPrevious
) {
    /** Tạo từ Spring {@code Page<MovieResponse>} và số trang gốc (1-indexed). */
    public static PagedMovieResponse from(
            org.springframework.data.domain.Page<MovieResponse> springPage,
            int requestedPage) {

        int  total      = (int) springPage.getTotalElements();
        int  size       = springPage.getSize();
        int  totalPages = springPage.getTotalPages() == 0 ? 1 : springPage.getTotalPages();

        return new PagedMovieResponse(
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
