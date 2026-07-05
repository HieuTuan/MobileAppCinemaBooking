package com.cineluxe.entity;

import jakarta.persistence.*;
import java.time.Instant;

@Entity
@Table(name = "reviews")
public class Review {

    @Id
    private String id;

    private String userId;
    private String movieId;
    private String userName;

    @Column(length = 500)
    private String comment;

    private int rating;       // 1-10
    private boolean verified; // true when user has a "used" booking

    private Instant createdAt;

    protected Review() {}

    public Review(String id, String userId, String movieId, String userName,
                  String comment, int rating, boolean verified) {
        this.id = id;
        this.userId = userId;
        this.movieId = movieId;
        this.userName = userName;
        this.comment = comment;
        this.rating = rating;
        this.verified = verified;
        this.createdAt = Instant.now();
    }

    public String getId() { return id; }
    public String getUserId() { return userId; }
    public String getMovieId() { return movieId; }
    public String getUserName() { return userName; }
    public String getComment() { return comment; }
    public int getRating() { return rating; }
    public boolean isVerified() { return verified; }
    public Instant getCreatedAt() { return createdAt; }
}
