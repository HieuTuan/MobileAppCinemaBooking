package com.cineluxe.controller;

import com.cineluxe.dto.request.CreateMovieRequest;
import com.cineluxe.dto.request.UpdateMovieRequest;
import com.cineluxe.dto.response.ApiResponse;
import com.cineluxe.dto.response.MovieResponse;
import com.cineluxe.entity.Movie;
import com.cineluxe.entity.Showtime;
import com.cineluxe.exception.ApiException;
import com.cineluxe.repository.MovieRepository;
import com.cineluxe.repository.ShowtimeRepository;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import java.util.List;
import java.util.UUID;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

/**
 * Admin CRUD endpoints for Movie management (R19).
 *
 * POST   /api/admin/movies        – tạo phim
 * PUT    /api/admin/movies/{id}   – cập nhật phim
 * DELETE /api/admin/movies/{id}   – xoá phim (409 nếu có showtime active)
 */
@RestController
@RequestMapping("/api/admin/movies")
@RequiredArgsConstructor
@Tag(name = "Admin – Movies", description = "Movie CRUD for admins (R19)")
public class AdminMovieController {

    private final MovieRepository movieRepository;
    private final ShowtimeRepository showtimeRepository;

    // ── POST /api/admin/movies ─────────────────────────────────────────────

    @PostMapping
    @Operation(summary = "Tạo phim mới")
    public ResponseEntity<ApiResponse<MovieResponse>> createMovie(
            @Valid @RequestBody CreateMovieRequest req) {

        validateMovieRequest(req.ageRating(), req.durationMinutes(), req.isAgeRatingValid());

        var movie = new Movie(UUID.randomUUID().toString());
        applyFields(movie, req.title(), req.releaseDate(), req.durationMinutes(),
                req.ageRating(), req.genres(), req.description(),
                req.posterUrl(), req.trailerUrl(), req.director(),
                req.cast(), req.rating());

        movieRepository.save(movie);
        return ApiResponse.created(MovieResponse.from(movie), "Tạo phim thành công");
    }

    // ── PUT /api/admin/movies/{id} ─────────────────────────────────────────

    @PutMapping("/{id}")
    @Operation(summary = "Cập nhật thông tin phim")
    public ResponseEntity<ApiResponse<MovieResponse>> updateMovie(
            @PathVariable String id,
            @Valid @RequestBody UpdateMovieRequest req) {

        var movie = findMovieOrThrow(id);

        if (req.ageRating() != null && !req.isAgeRatingValid()) {
            throw new ApiException(HttpStatus.BAD_REQUEST,
                    "ageRating không hợp lệ. Giá trị hợp lệ: P, C13, C16, C18, T18");
        }
        if (req.durationMinutes() != null
                && (req.durationMinutes() < 30 || req.durationMinutes() > 300)) {
            throw new ApiException(HttpStatus.BAD_REQUEST,
                    "Thời lượng phim phải từ 30 đến 300 phút");
        }

        if (req.title()           != null) movie.setTitle(req.title());
        if (req.releaseDate()     != null) movie.setReleaseDate(req.releaseDate());
        if (req.durationMinutes() != null) movie.setDurationMinutes(req.durationMinutes());
        if (req.ageRating()       != null) movie.setAgeRating(req.ageRating());
        if (req.genres()          != null) movie.setGenres(req.genres());
        if (req.description()     != null) movie.setDescription(req.description());
        if (req.posterUrl()       != null) movie.setPosterUrl(req.posterUrl());
        if (req.trailerUrl()      != null) movie.setTrailerUrl(req.trailerUrl());

        if (req.director()      != null) movie.setDirector(req.director());
        if (req.cast()          != null) movie.setCast(req.cast());
        if (req.rating()        != null) movie.setRating(req.rating());

        movieRepository.save(movie);
        return ApiResponse.success(MovieResponse.from(movie), "Cập nhật phim thành công");
    }

    // ── DELETE /api/admin/movies/{id} ─────────────────────────────────────

    @DeleteMapping("/{id}")
    @Operation(summary = "Xoá phim (409 nếu còn showtime đang lên lịch)")
    public ResponseEntity<ApiResponse<Void>> deleteMovie(@PathVariable String id) {

        findMovieOrThrow(id);

        // R19-5: 409 nếu phim có showtime chưa kết thúc / huỷ
        boolean hasActiveShowtimes = showtimeRepository
                .existsByMovieIdAndStatusNot(id, Showtime.STATUS_CANCELLED);
        if (hasActiveShowtimes) {
            throw new ApiException(HttpStatus.CONFLICT,
                    "Cannot delete movie with scheduled showtimes");
        }

        movieRepository.deleteById(id);
        return ApiResponse.success(null, "Xoá phim thành công");
    }

    // ── helpers ───────────────────────────────────────────────────────────

    private Movie findMovieOrThrow(String id) {
        return movieRepository.findById(id)
                .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND,
                        "Không tìm thấy phim với id: " + id));
    }

    private void validateMovieRequest(String ageRating, int duration, boolean ageRatingValid) {
        if (!ageRatingValid) {
            throw new ApiException(HttpStatus.BAD_REQUEST,
                    "ageRating không hợp lệ. Giá trị hợp lệ: P, C13, C16, C18, T18");
        }
        if (duration < 30 || duration > 300) {
            throw new ApiException(HttpStatus.BAD_REQUEST,
                    "Thời lượng phim phải từ 30 đến 300 phút");
        }
    }

    private void applyFields(Movie movie, String title, java.time.LocalDate releaseDate,
                             int duration, String ageRating, List<String> genres,
                             String description, String posterUrl, String trailerUrl,
                             String director, List<String> cast, Double rating) {
        movie.setTitle(title);
        movie.setReleaseDate(releaseDate);
        movie.setDurationMinutes(duration);
        movie.setAgeRating(ageRating);
        if (genres      != null) movie.setGenres(genres);
        if (description != null) movie.setDescription(description);
        if (posterUrl   != null) movie.setPosterUrl(posterUrl);
        if (trailerUrl  != null) movie.setTrailerUrl(trailerUrl);
        if (director    != null) movie.setDirector(director);
        if (cast        != null) movie.setCast(cast);
        if (rating      != null) movie.setRating(rating);
    }
}
