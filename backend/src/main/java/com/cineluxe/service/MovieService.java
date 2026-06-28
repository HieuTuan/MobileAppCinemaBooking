package com.cineluxe.service;

import com.cineluxe.dto.response.MovieResponse;
import org.springframework.data.domain.Page;

/**
 * Luồng Tìm kiếm & lọc phim (Requirement R3).
 */
public interface MovieService {

    /**
     * Tìm kiếm & lọc phim theo nhiều tiêu chí với phân trang.
     *
     * @param search   từ khoá (khớp title, director, cast, genres — không phân biệt hoa thường)
     * @param genre    thể loại cần lọc (null = bỏ qua)
     * @param status   "nowShowing" | "comingSoon" | null = tất cả
     * @param page     trang hiện tại (bắt đầu từ 1)
     * @param pageSize số phim mỗi trang (mặc định 20)
     * @return trang phim khớp; nếu không có kết quả trả mảng rỗng, 200 OK
     */
    Page<MovieResponse> getMovies(String search, String genre, String status,
                                   int page, int pageSize);

    /**
     * Lấy chi tiết một phim theo ID.
     *
     * @param movieId ID phim
     * @return {@link MovieResponse} hoặc ném ApiException 404 nếu không tìm thấy
     */
    MovieResponse getMovieById(String movieId);
}
