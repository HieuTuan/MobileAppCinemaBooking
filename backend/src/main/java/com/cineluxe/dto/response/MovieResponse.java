package com.cineluxe.dto.response;

import com.cineluxe.entity.Movie;
import java.time.Instant;
import java.time.LocalDate;
import java.util.List;

/**
 * Response DTO for Movie (R19).
 * Mirrors the fields expected by the Flutter Movie model.
 */
public record MovieResponse(
        String id,
        String title,
        String description,
        String posterUrl,
        String trailerUrl,
        int durationMinutes,
        String ageRating,
        LocalDate releaseDate,
        List<String> genres,
        List<String> cast,
        String director,
        double rating,
        String status,
        Instant createdAt,
        Instant updatedAt
) {
    /**
     * Build response using the movie's static rating field.
     * Used when averageRating from reviews is not needed.
     */
    public static MovieResponse from(Movie m) {
        return from(m, null);
    }

    /**
     * Build response, replacing `rating` with the live average from reviews
     * when available (thang 1–10). Falls back to the movie's stored rating
     * (also on a 1–10 scale after * 2 normalisation) when no reviews exist.
     *
     * @param m             the Movie entity
     * @param averageRating AVG(review.rating) for this movie, or null if no reviews yet
     */
    public static MovieResponse from(Movie m, Double averageRating) {
        // Use live average when reviews exist; otherwise keep the stored value.
        // Stored value is on a 0–5 scale → multiply by 2 to normalise to 0–10.
        double displayRating = (averageRating != null)
                ? averageRating
                : m.getRating() * 2.0;

        return new MovieResponse(
                m.getId(),
                m.getTitle(),
                m.getDescription() != null ? m.getDescription() : "",
                m.getPosterUrl() != null ? m.getPosterUrl() : "",
                m.getTrailerUrl() != null ? m.getTrailerUrl() : "",
                m.getDurationMinutes(),
                m.getAgeRating(),
                m.getReleaseDate(),
                m.getGenres() != null ? m.getGenres() : List.of(),
                m.getCast() != null ? m.getCast() : List.of(),
                m.getDirector() != null ? m.getDirector() : "",
                displayRating,
                m.getStatus(),
                m.getCreatedAt(),
                m.getUpdatedAt()
        );
    }
}
