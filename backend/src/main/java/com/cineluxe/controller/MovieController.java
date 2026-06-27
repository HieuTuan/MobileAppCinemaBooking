package com.cineluxe.controller;

import com.cineluxe.dto.response.ApiResponse;
import com.cineluxe.dto.response.MovieResponse;
import com.cineluxe.dto.response.PagedMovieResponse;
import com.cineluxe.service.MovieService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.responses.ApiResponses;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

/**
 * Tìm kiếm & lọc phim — Luồng theo ảnh (Requirement R3).
 *
 * <p>Endpoints:
 * <ul>
 *   <li>{@code GET /api/movies}           — tìm kiếm + lọc + phân trang</li>
 *   <li>{@code GET /api/movies/{movieId}} — chi tiết một phim</li>
 * </ul>
 *
 * <p>Luồng:
 * <ol>
 *   <li>GET /api/movies với các query params tuỳ chọn</li>
 *   <li>Tìm text: khớp title, director, cast, genres (JPQL, không phân biệt hoa thường)</li>
 *   <li>Lọc theo genre hoặc status: nowShowing / comingSoon</li>
 *   <li>Không filter: tất cả phim active, sắp xếp releaseDate giảm dần</li>
 *   <li>Phân trang: page, pageSize (mặc định 20), trả về trong 300ms</li>
 * </ol>
 *
 * <p>Lỗi & ngoại lệ: Không có kết quả → mảng rỗng, 200 OK
 */
@RestController
@RequestMapping("/api/movies")
@RequiredArgsConstructor
@Tag(name = "Movies", description = "Tìm kiếm & lọc phim (R3)")
public class MovieController {

    private final MovieService movieService;

    // ── GET /api/movies ───────────────────────────────────────────────────────

    @GetMapping
    @Operation(
        summary     = "Tìm kiếm & lọc phim",
        description = """
            Tìm phim theo nhiều tiêu chí.
            - search: khớp title, director, cast, genres (không phân biệt hoa thường)
            - genre: lọc theo thể loại (ví dụ: "Hành động")
            - status: nowShowing | comingSoon
            - Không filter: trả tất cả phim, sắp xếp releaseDate giảm dần
            - Không có kết quả → mảng rỗng data=[], 200 OK
            """
    )
    @ApiResponses({
        @io.swagger.v3.oas.annotations.responses.ApiResponse(
            responseCode = "200",
            description  = "Danh sách phim (data=[] nếu không có kết quả)"
        )
    })
    public ResponseEntity<ApiResponse<PagedMovieResponse>> getMovies(
            @Parameter(description = "Từ khoá tìm kiếm (title, director, cast, genres)")
            @RequestParam(required = false) String search,

            @Parameter(description = "Thể loại cần lọc (ví dụ: Hành động)")
            @RequestParam(required = false) String genre,

            @Parameter(description = "Trạng thái phim: nowShowing | comingSoon")
            @RequestParam(required = false) String status,

            @Parameter(description = "Số trang (bắt đầu từ 1, mặc định 1)")
            @RequestParam(defaultValue = "1") int page,

            @Parameter(description = "Số phim mỗi trang (mặc định 20, tối đa 100)")
            @RequestParam(defaultValue = "20") int pageSize) {

        var springPage = movieService.getMovies(search, genre, status, page, pageSize);
        var result     = PagedMovieResponse.from(springPage, page);
        return ApiResponse.success(result);
    }

    // ── GET /api/movies/{movieId} ─────────────────────────────────────────────

    @GetMapping("/{movieId}")
    @Operation(
        summary     = "Lấy chi tiết một phim",
        description = "Trả về toàn bộ thông tin phim theo ID. 404 nếu không tìm thấy."
    )
    @ApiResponses({
        @io.swagger.v3.oas.annotations.responses.ApiResponse(
            responseCode = "200", description = "Chi tiết phim"),
        @io.swagger.v3.oas.annotations.responses.ApiResponse(
            responseCode = "404", description = "Không tìm thấy phim")
    })
    public ResponseEntity<ApiResponse<MovieResponse>> getMovieById(
            @Parameter(description = "ID phim")
            @PathVariable String movieId) {

        return ApiResponse.success(movieService.getMovieById(movieId));
    }
}
