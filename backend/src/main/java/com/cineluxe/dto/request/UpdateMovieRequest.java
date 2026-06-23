package com.cineluxe.dto.request;

import com.cineluxe.entity.Movie;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import java.time.LocalDate;
import java.util.List;

/**
 * Request body for PUT /api/admin/movies/{id} (R19-4).
 * All fields are optional – only non-null values are applied.
 */
public record UpdateMovieRequest(
        String title,
        LocalDate releaseDate,

        @Min(value = 30,  message = "Thời lượng phim tối thiểu 30 phút")
        @Max(value = 300, message = "Thời lượng phim tối đa 300 phút")
        Integer durationMinutes,

        String ageRating,
        List<String> genres,
        String description,
        String posterUrl,
        String trailerUrl,
        String director,
        List<String> cast,
        Double rating
) {
    public boolean isAgeRatingValid() {
        return ageRating == null || Movie.VALID_AGE_RATINGS.contains(ageRating);
    }
}
