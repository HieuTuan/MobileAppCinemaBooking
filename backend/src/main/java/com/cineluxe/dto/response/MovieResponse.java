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
    public static MovieResponse from(Movie m) {
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
                m.getRating(),
                m.getStatus(),
                m.getCreatedAt(),
                m.getUpdatedAt()
        );
    }
}
