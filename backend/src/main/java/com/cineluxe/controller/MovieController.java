package com.cineluxe.controller;

import com.cineluxe.dto.response.ApiResponse;
import com.cineluxe.dto.response.MovieResponse;
import com.cineluxe.exception.ApiException;
import com.cineluxe.repository.MovieRepository;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import java.util.List;
import java.util.stream.Collectors;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

/**
 * Public endpoints for browsing movies (R19).
 *
 * GET /api/movies           – danh sách tất cả phim (filter by status)
 * GET /api/movies/{id}      – chi tiết phim
 */
@RestController
@RequestMapping("/api/movies")
@RequiredArgsConstructor
@Tag(name = "Movies", description = "Public movie listing endpoints (R19)")
public class MovieController {

    private final MovieRepository movieRepository;

    @GetMapping
    @Operation(summary = "Lấy danh sách phim (tùy chọn lọc theo status: comingSoon / nowShowing)")
    public ResponseEntity<ApiResponse<List<MovieResponse>>> listMovies(
            @RequestParam(required = false) String status) {

        var movies = movieRepository.findByOrderByReleaseDateDesc()
                .stream()
                .filter(m -> status == null || status.equals(m.getStatus()))
                .map(MovieResponse::from)
                .collect(Collectors.toList());

        return ApiResponse.success(movies);
    }

    @GetMapping("/{id}")
    @Operation(summary = "Lấy chi tiết phim theo id")
    public ResponseEntity<ApiResponse<MovieResponse>> getMovie(@PathVariable String id) {
        var movie = movieRepository.findById(id)
                .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND,
                        "Không tìm thấy phim với id: " + id));
        return ApiResponse.success(MovieResponse.from(movie));
    }
}
