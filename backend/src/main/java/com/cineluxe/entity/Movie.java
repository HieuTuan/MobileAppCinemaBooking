package com.cineluxe.entity;

import jakarta.persistence.*;
import java.time.Instant;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;
import java.util.Set;

/**
 * Movie entity (R19).
 * ageRating valid values: P · C13 · C16 · C18 · T18
 * status is computed from releaseDate at query time via getStatus().
 */
@Entity
@Table(name = "movies",
    indexes = {
        @Index(name = "idx_movie_release_date", columnList = "releaseDate"),
        @Index(name = "idx_movie_age_rating",   columnList = "ageRating")
    })
public class Movie {

    public static final Set<String> VALID_AGE_RATINGS = Set.of("P", "C13", "C16", "C18", "T18");

    @Id
    private String id;

    private String title;
    private String description;
    private String posterUrl;
    private String trailerUrl;
    private int durationMinutes;
    private String ageRating;
    private LocalDate releaseDate;

    @ElementCollection
    @CollectionTable(name = "movie_genres", joinColumns = @JoinColumn(name = "movie_id"))
    @Column(name = "genre")
    private List<String> genres = new ArrayList<>();

    @ElementCollection
    @CollectionTable(name = "movie_cast", joinColumns = @JoinColumn(name = "movie_id"))
    @Column(name = "cast_member")
    private List<String> cast = new ArrayList<>();

    private String director;
    private double rating;

    private Instant createdAt;
    private Instant updatedAt;

    protected Movie() {}

    public Movie(String id) {
        this.id = id;
        this.createdAt = Instant.now();
        this.updatedAt = Instant.now();
    }

    @PreUpdate
    protected void onUpdate() {
        this.updatedAt = Instant.now();
    }

    /**
     * Compute status dynamically: comingSoon if releaseDate is in the future,
     * nowShowing otherwise (R19-3).
     */
    public String getStatus() {
        if (releaseDate == null) return "comingSoon";
        return releaseDate.isAfter(LocalDate.now()) ? "comingSoon" : "nowShowing";
    }

    // Getters
    public String getId()              { return id; }
    public String getTitle()           { return title; }
    public String getDescription()     { return description; }
    public String getPosterUrl()       { return posterUrl; }
    public String getTrailerUrl()      { return trailerUrl; }
    public int getDurationMinutes()    { return durationMinutes; }
    public String getAgeRating()       { return ageRating; }
    public LocalDate getReleaseDate()  { return releaseDate; }
    public List<String> getGenres()    { return genres; }
    public List<String> getCast()      { return cast; }
    public String getDirector()        { return director; }
    public double getRating()          { return rating; }
    public Instant getCreatedAt()      { return createdAt; }
    public Instant getUpdatedAt()      { return updatedAt; }

    // Setters
    public void setTitle(String title)                   { this.title = title; }
    public void setDescription(String description)       { this.description = description; }
    public void setPosterUrl(String posterUrl)           { this.posterUrl = posterUrl; }
    public void setTrailerUrl(String trailerUrl)         { this.trailerUrl = trailerUrl; }
    public void setDurationMinutes(int durationMinutes)  { this.durationMinutes = durationMinutes; }
    public void setAgeRating(String ageRating)           { this.ageRating = ageRating; }
    public void setReleaseDate(LocalDate releaseDate)    { this.releaseDate = releaseDate; }
    public void setGenres(List<String> genres)           { this.genres = genres; }
    public void setCast(List<String> cast)               { this.cast = cast; }
    public void setDirector(String director)             { this.director = director; }
    public void setRating(double rating)                 { this.rating = rating; }
}
