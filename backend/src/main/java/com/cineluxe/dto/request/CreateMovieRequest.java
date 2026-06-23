package com.cineluxe.dto.request;

import com.cineluxe.entity.Movie;
import jakarta.validation.constraints.*;
import java.time.LocalDate;
import java.util.List;

/**
 * Request body for POST /api/admin/movies (R19-1).
 */
public record CreateMovieRequest(

        @NotBlank(message = "Tiêu đề phim không được để trống")
        String title,

        @NotNull(message = "Ngày phát hành không được để trống")
        LocalDate releaseDate,

        @NotNull(message = "Thời lượng không được để trống")
        @Min(value = 30,  message = "Thời lượng phim tối thiểu 30 phút")
        @Max(value = 300, message = "Thời lượng phim tối đa 300 phút")
        Integer durationMinutes,

        @NotBlank(message = "Độ tuổi xem phim không được để trống")
        String ageRating,

        List<String> genres,
        String description,
        String posterUrl,
        String trailerUrl,
        String director,
        List<String> cast,
        Double rating
) {
    /** Validate ageRating tại đây vì @Pattern không cover Set-based check. */
    public boolean isAgeRatingValid() {
        return ageRating != null && Movie.VALID_AGE_RATINGS.contains(ageRating);
    }
}
