package com.cineluxe.entity;

import jakarta.persistence.*;
import java.time.Instant;

/**
 * Showtime entity – links a Movie to a room/time slot (R19).
 * Used to check R19-5: cannot delete a Movie that has scheduled showtimes.
 */
@Entity
@Table(name = "showtimes",
    indexes = {
        @Index(name = "idx_showtime_movie_id", columnList = "movieId"),
        @Index(name = "idx_showtime_status",   columnList = "status")
    })
public class Showtime {

    /** Valid statuses */
    public static final String STATUS_SCHEDULED = "scheduled";
    public static final String STATUS_CANCELLED = "cancelled";
    public static final String STATUS_COMPLETED  = "completed";

    @Id
    private String id;

    private String movieId;
    private String roomId;
    private String cinemaName;
    private Instant startTime;
    private Instant endTime;
    private int basePrice;

    /** scheduled | cancelled | completed */
    private String status = STATUS_SCHEDULED;

    private Instant createdAt;
    private Instant updatedAt;

    protected Showtime() {}

    public Showtime(String id, String movieId, String roomId,
                    String cinemaName, Instant startTime) {
        this(id, movieId, roomId, cinemaName, startTime, null, 120_000);
    }

    public Showtime(String id, String movieId, String roomId,
                    String cinemaName, Instant startTime, Instant endTime, int basePrice) {
        this.id = id;
        this.movieId = movieId;
        this.roomId = roomId;
        this.cinemaName = cinemaName;
        this.startTime = startTime;
        this.endTime = endTime;
        this.basePrice = basePrice;
        this.status = STATUS_SCHEDULED;
        this.createdAt = Instant.now();
        this.updatedAt = Instant.now();
    }

    @PreUpdate
    protected void onUpdate() {
        this.updatedAt = Instant.now();
    }

    // Getters
    public String getId()          { return id; }
    public String getMovieId()     { return movieId; }
    public String getRoomId()      { return roomId; }
    public String getCinemaName()  { return cinemaName; }
    public Instant getStartTime()  { return startTime; }
    public Instant getEndTime()    { return endTime; }
    public int getBasePrice()      { return basePrice; }
    public String getStatus()      { return status; }
    public Instant getCreatedAt()  { return createdAt; }
    public Instant getUpdatedAt()  { return updatedAt; }

    // Setters
    public void setMovieId(String movieId)       { this.movieId = movieId; }
    public void setRoomId(String roomId)         { this.roomId = roomId; }
    public void setStatus(String status)         { this.status = status; }
    public void setStartTime(Instant startTime)  { this.startTime = startTime; }
    public void setEndTime(Instant endTime)      { this.endTime = endTime; }
    public void setBasePrice(int basePrice)      { this.basePrice = basePrice; }
    public void setCinemaName(String cinemaName) { this.cinemaName = cinemaName; }
}
